import os
import json
from cumulusci.utils import inject_namespace
from cumulusci.core.utils import process_list_arg
from cumulusci.core.exceptions import CumulusCIException
from cumulusci.core.tasks import BaseTask
from dev.tasks.debugger import log_title
from cumulusci.core.config import TaskConfig
from cumulusci.tasks.salesforce import GetInstalledPackages


def get_default_package_directory():
    with open("sfdx-project.json", "r") as f:
        project = json.load(f)
    for source_path in project["packageDirectories"]:
        if source_path.get("default"):
            return source_path["path"]
    raise CumulusCIException(
        'One of of sfdx-project.json "packageDirectories" must be marked as default.'
    )


def _is_project_package_installed(self: BaseTask):
    """
    Temporary fix to detect if the org is in a "managed" context meaning
    the project's package is installed.

    The plan is to use self.org_config.has_minimum_version() when released.
    """
    namespace = self.project_config.project__package__namespace
    for package in GetInstalledPackages(
        self.project_config, TaskConfig({}), self.org_config,
    )().items():
        installed_package_namespace = package[0]
        if namespace == installed_package_namespace:
            return True
    return False


def get_task_namespace_info(self: BaseTask):
    """
    Retrieves useful calculations of whether or not namespace injection is needed.
    """
    # Always use the project's package's namespace as the namespace to inject.
    is_packaged_installed = False
    namespace = self.project_config.project__package__namespace

    # namespaced_org is true if the scratch org is a namespaced org.
    is_namespaced_org = self.org_config.scratch and self.org_config.namespaced

    # is_managed passed in as the "managed" kwarg for inject_namespace().
    # is_managed is true if any of the following is true:
    # - is a namespaced org
    # - this package is installed
    if not is_namespaced_org:
        is_packaged_installed = _is_project_package_installed(self)

    is_managed = is_namespaced_org or is_packaged_installed

    return {
        "namespace": namespace,
        "is_namespaced_org": is_namespaced_org,
        "is_packaged_installed": is_packaged_installed,  # is_packaged_installed is not checked if is_namespaced_org is True
        "is_managed": is_managed,
    }


class InjectNamespaceBaseTask(BaseTask):
    task_options = {
        "ignore_directories_for_inject_namespace": {
            "description": 'Directories which inject_namespace will not process.  Option must be an array.  Always ignores directories starting with "." or "_", and always ignores file names starting with ".".  Default: [contentassets, staticresources].',
            "required": False,
        },
    }

    def _ignore_inject_namespace_for_directory(self, directory):
        return directory.startswith((".", "_"))

    def _ignore_inject_namespace_for_file(self, file_name):
        return file_name.startswith((".", "sfdx-project.json",))

    def _inject_namespace(
        self, source_path: str, managed=False,
    ):
        """
        Walks through source_path and calls inject_namespace on files whose:
        - Directory or parent directory:
            - Is not in "ignore_directories_for_inject_namespace" option
            - Does not start with:
                - "." for configuration directories
                - "_" for test directories
        - File name starts with:
            - "." for configuration files
            - "sfdx-project.json" since it's a configuration file.

        NOTE: We pass in the "namespace", "managed", and "namespaced_org" kwargs into
              inject_namespace() to handle most (if not all) namespace tokens and
              contexts.
        """

        # Set which additional directories to ignore that make it pass _ignore_inject_namespace_for_directory().
        directories_to_ignore = set()
        directories_to_ignore.update(
            process_list_arg(
                self.options.get("ignore_directories_for_inject_namespace")
                or ["contentassets", "staticresources"]
            )
        )

        # Walk through source_path and inject_namespace for all directories and files not ignored.
        log_title("Injecting namespace in temporary directory", self.logger.info)
        self.logger.info(source_path)

        namespace_info = get_task_namespace_info(self)
        for path, subdirectories, files in os.walk(source_path):
            directory = os.path.basename(path)

            if (
                directory in directories_to_ignore
                or self._ignore_inject_namespace_for_directory(directory)
            ):
                # directory is excluded. Exclude subdirectories too.
                subdirectories[:] = []
                continue

            for file_name in files:
                file_path = os.path.join(path, file_name)

                if self._ignore_inject_namespace_for_file(file_name):
                    continue

                # Read file's content.
                # TODO: BEWARE: This will do newline translation.  Come back to this.
                with open(file_path, "r") as f:
                    file_content = f.read()

                # Inject namespace into file_name and file_content.
                new_file_name, injected_file_content = inject_namespace(
                    file_name,
                    file_content,
                    namespace=namespace_info["namespace"],
                    # managed kwarg overrides namespace_info["is_managed"]
                    managed=(managed or namespace_info["is_managed"]),
                    namespaced_org=namespace_info["is_namespaced_org"],
                    logger=self.logger,
                )

                # Write injected_file_content if inject_namespace() changes either file_name or file_content.
                if new_file_name != file_name or injected_file_content != file_content:
                    # If file_name changes after injecting namespace, remove the old file.
                    if new_file_name != file_name:
                        os.remove(file_path)

                    # Save the injected_file_content.
                    with open(os.path.join(path, new_file_name), "w") as f:
                        f.write(injected_file_content)

        self.logger.info("")
