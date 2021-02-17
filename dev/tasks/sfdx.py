import os
import json
from pathlib import Path
from abc import ABCMeta, abstractmethod
from shutil import copy2
from distutils.dir_util import copy_tree
from cumulusci.utils import temporary_dir
from cumulusci.core.utils import process_bool_arg
from cumulusci.core.sfdx import sfdx
from cumulusci.core.exceptions import SalesforceException
from cumulusci.core.tasks import BaseTask
from dev.tasks.namespaces import InjectNamespaceBaseTask, get_default_package_directory
from dev.tasks.debugger import debug


class BaseTaskWithSfdx(BaseTask):
    """
    Wrapper tasks for the SFDX CLI that returns the JSON response as a dict.
    """

    def _sfdx(self, commands, addTargetUsername=True):
        """
        Calls sfdx with commands joined by " " always including the option "--json" and
        gives the option to append the "--targetusername" as self.org_config.sfdx_alias
        if addTargetUsername is True.  Returns the JSON response as a dict.
        """

        if addTargetUsername:
            commands.append(
                f'--targetusername="{self.org_config.sfdx_alias if self.org_config.sfdx_alias else self.org_config.username}"'
            )
        commands.append("--json")
        self.logger.info("Calling sfdx: ")
        is_first = True
        for c in commands:
            if is_first:
                self.logger.info(f"    sfdx {c}")
                is_first = False
            else:
                self.logger.info(f"        {c}")
        self.logger.info("")

        pipe = sfdx(" ".join(commands))
        # pylint: disable=no-member
        result = json.loads(pipe.stdout.text)

        if result["status"] == 0:
            return result["result"]
        else:
            # Collect results for error message.
            logs = []

            def log_collector(log):
                logs.append(log)

            debug(
                {"message": result["message"], "result": result.get("result") or {}},
                title="sfdx result",
                logger=log_collector,
            )
            raise SalesforceException("\n".join(logs))


class SfdxEtlWithNamespaceInjectionTask(
    BaseTaskWithSfdx, InjectNamespaceBaseTask, metaclass=ABCMeta
):
    """
    An abstract "extract, transform, and load (ETL)" style task to extract and transform metadata
    into a temporary directory leaving the original metadata unchanged.

    As a bonus, since sfdx will be called in the temporary directory, the sfdx commands
    do NOT inherit the original directory's .forceignore!
    """

    task_options = {
        **InjectNamespaceBaseTask.task_options,
        "override_forceignore": {
            "description": """Path to a .forceignore to copy into the temporary directory instead of the default .forceignore which contains:
                - ``**/jsconfig.json``
                - ``**/.eslintrc.json``
                - ``**/__tests__/**``
            """,
            "required": False,
        },
        "copy_sfdx_config": {
            "description": 'If to copy ".sfdx" directory containing sfdx configuration into the temporary directory as well as copying ".sfdx" directory back to the current directory.  Useful for creating users with "sfdx force:user:create".   Default: False.',
            "required": False,
            "default": False,
        },
    }

    @abstractmethod
    def _sfdx_extract(self):
        """Extract files into self._temporary_directory to transform and load."""
        pass

    @abstractmethod
    def _sfdx_transform(self):
        """Transform metadata in self._temporary_directory if needed."""
        pass

    @abstractmethod
    def _sfdx_load(self):
        """Load the extracted and transformed files to their final destination, e.g. deploy, copy back to self._current_directory."""
        pass

    def get_forceignore_content(self):

        if self.options.get("override_forceignore") and os.path.isfile(
            os.path.join(
                self._current_directory, self.options.get("override_forceignore")
            )
        ):
            self.logger.info(
                "Overriding default .forceignore: {}".format(
                    self.options["override_forceignore"]
                )
            )
            with open(
                os.path.join(
                    self._current_directory, self.options.get("override_forceignore")
                ),
                "r",
            ) as f:
                forceignore_content = f.read()
        else:
            forceignore_content = "\n".join(
                ["**/jsconfig.json", "**/.eslintrc.json", "**/__tests__/**"]
            )
        return forceignore_content

    def _create_temporary_package_directories(self):
        project = json.loads(
            (Path(self._current_directory) / "sfdx-project.json").read_text()
        )
        for package_directory in project.get("packageDirectories"):
            path = Path(self._temporary_directory) / package_directory.get("path")
            path.mkdir(parents=True, exist_ok=False)

    def _run_task(self):
        """
        Creates a temporary directory and does the following:
        - Copies "sfdx-project.json" so sfdx can be called in the temporary directory
        - Option to copy ".sfdx" directory containing sfdx config.
        - Creates a ".forceignore" file.  Contents of the ".forceignore" file can be
          overridden with the "override_forceignore" option.
          NOTE: The current directory's ".forceignore" is never referenced, read, or
          modified.  This means no developer intervention is necessary to call this task!
        - Calls _sfdx_extract()
        - Calls _sfdx_transform()
        - Walks through the temporary directory and calls _inject_namespace() which
          injects the namespace into eligible directories and files.
        - Calls _sfdx_load()
        - Option to copy the temporary directory's ".sfdx" directory back to the current
          directory.   This is useful if ".sfdx" contents changes as a result of calling
          certain sfdx commands, e.g. "force:user:create".
        """
        self._default_package_directory = get_default_package_directory()

        self._current_directory = os.path.abspath(os.getcwd())
        self._package_path = os.path.abspath(
            os.path.join(self._current_directory, self._default_package_directory)
        )

        copy_sfdx_config = process_bool_arg(
            self.options.get("copy_sfdx_config", False)
        ) and os.path.isdir(os.path.join(self._current_directory, ".sfdx"))

        with temporary_dir() as self._temporary_directory:
            # Copy sfdx-project.json so we can run sfdx commands within self._temporary_directory.
            copy2(
                os.path.join(self._current_directory, "sfdx-project.json"),
                os.path.join(self._temporary_directory, "sfdx-project.json"),
            )
            self.logger.debug(
                'Copying "sfdx-project.json" file to the temporary directory.'
            )

            self._create_temporary_package_directories()

            # Copy ".sfdx" config to temporary directory.
            if copy_sfdx_config:
                copy_tree(
                    os.path.join(self._current_directory, ".sfdx"),
                    os.path.join(self._temporary_directory, ".sfdx"),
                )
                self.logger.debug(
                    'Copying ".sfdx" directory to the temporary directory.'
                )

            # Create the .forceignore in the temporary directory.
            # Since we're in the temporary directory, we don't need to change the
            # current directory's .forceignore to do things like `sfdx force:source:deploy`!
            with open(
                os.path.join(self._temporary_directory, ".forceignore"), "w"
            ) as f:
                f.write(self.get_forceignore_content())

            # Extract metadata into self._temporary_package_path.
            # load everything you need in to temporary directory
            self._sfdx_extract()

            # Transform metadata in self._temporary_package_path.
            self._sfdx_transform()

            # Inject namespace into metadata in self._temporary_directory.
            self._inject_namespace(self._temporary_directory, managed=False)

            # Load metadata into self._temporary_package_path.
            self._sfdx_load()

            # Copy .sfdx config modified in the temporary directory back to the original directory.
            if copy_sfdx_config:
                copy_tree(
                    os.path.join(self._temporary_directory, ".sfdx"),
                    os.path.join(self._current_directory, ".sfdx"),
                )
                self.logger.debug(
                    'Copying ".sfdx" directory from the temporary directory back to the current directory in case it was modifed.'
                )

    def debug_directory(self, root_path):
        """
        Walks through root_path and logs directories and files.
        Useful to know what exists in the temporary directory.
        """
        for root, dirs, files in os.walk(root_path):
            level = root.replace(root_path, "").count(os.sep)
            indent = " " * 4 * (level)
            self.logger.warn("{}{}/".format(indent, os.path.basename(root)))
            subindent = " " * 4 * (level + 1)
            for f in files:
                self.logger.warn("{}{}".format(subindent, f))
