import os
from pathlib import Path
import re
import xml.etree.ElementTree as ET
from cumulusci.core.exceptions import CumulusCIException
from dev.tasks.debugger import log_title
from dev.tasks.sfdx import SfdxEtlWithNamespaceInjectionTask


class ExperienceBundleTask(SfdxEtlWithNamespaceInjectionTask):
    task_options = {
        "network_name": {"description": ("Name of Network"), "required": True},
        **SfdxEtlWithNamespaceInjectionTask.task_options,
    }

    def _sfdx_extract(self):
        # Create default package directory in temporary directory
        self._temporary_package_directory = os.path.join(
            self._temporary_directory, self._default_package_directory
        )

        self._network_name = self.options.get("network_name")

        # Retrieve the Network metadata.
        self._retrieve_network()

        # Extract the ExperienceBundle API Name from the Network metadata.
        self._set_experience_bundle_name()

        # Retrieve the ExperienceBundle metadata.
        self._retrieve_experience_bundle()

    def _sfdx_transform(self):
        pass

    def _sfdx_load(self):
        self._deploy_experience_bundle()
        self._publish_network()

    def _retrieve_network(self):
        self._log_title("Retrieving Network metadata")
        result = self._sfdx(
            ["force:source:retrieve", f'--metadata="Network:{self._network_name}"'],
            addTargetUsername=True,
        )

        # Check if there were any errors retrieveing metadata
        self._assert_sfdx_retrieved_successfully(result)

    def _set_experience_bundle_name(self):
        """
        1) Open Network file
        2) Extract picassoSite with regex.
        3) set self._experience_bundle_name = picassoSite
        """
        network_path = os.path.join(
            self._temporary_package_directory,
            "main",
            "default",
            "networks",
            f"{self._network_name}.network-meta.xml",
        )

        tree = ET.parse(network_path)
        root = tree.getroot()

        for elem in root.findall(
            "{http://soap.sforce.com/2006/04/metadata}picassoSite"
        ):
            picasso_site = elem.text

        self._experience_bundle_name = picasso_site

        self._log_title("Extracting ExperienceBundle API Name from Network metadata")
        self.logger.info(f"ExperienceBundle: {self._experience_bundle_name}")

    def _retrieve_experience_bundle(self):
        self._log_title("Retrieving ExperienceBundle metadata")
        result = self._sfdx(
            [
                "force:source:retrieve",
                f'--metadata="ExperienceBundle:{self._experience_bundle_name}"',
            ],
            addTargetUsername=True,
        )

        # Check if there were any errors retrieveing metadata
        self._assert_sfdx_retrieved_successfully(result)

    def _deploy_experience_bundle(self):
        self._log_title("Deploying ExperienceBundle metadata")

        result = self._sfdx(
            [
                "force:source:deploy",
                f'--metadata="ExperienceBundle:{self._experience_bundle_name}"',
            ],
            addTargetUsername=True,
        )

        # raise CumulusCIException is no results found.
        if not result["deployedSource"]:
            raise CumulusCIException(
                f'Metadata not found: "ExperienceBundle:{self._experience_bundle_name}"'
            )

    def _publish_network(self):
        self._log_title("Publishing Network")
        self._sfdx(
            ["force:community:publish", f'--name="{self._network_name}"'],
            addTargetUsername=True,
        )

    def _assert_sfdx_retrieved_successfully(self, sfdx_result):
        errors = []
        for inbound_file in sfdx_result["inboundFiles"]:
            if inbound_file.get("error"):
                errors.append(inbound_file.get("error"))

        if errors:
            raise CumulusCIException("; ".join(errors))

    def _log_title(self, title):
        self.logger.info("")
        log_title(title, self.logger.info)

    def _debug_temporary_directory(self):
        self.logger.warn("debugging temporary package directory")
        self.logger.warn("")
        self.logger.warn(f"temporary directory: {self._temporary_directory}")
        self.list_files(self._default_package_directory)


class ReplaceThemeLayoutNavigationMenuTask(ExperienceBundleTask):

    task_options = {
        "navigation_menu": {
            "description": "NavigationMenu API name to set for all theme layouts.",
            "required": True,
        },
        **ExperienceBundleTask.task_options,
    }

    def _sfdx_transform(self):
        self._set_navigation_menu()

    def _set_navigation_menu(self):
        self._log_title("Set navigation menu")
        self.logger.info(
            'Setting the navigation menu as "{}" for all "{}" ExperienceBundle themes:'.format(
                self.options["navigation_menu"], self._experience_bundle_name,
            )
        )

        themes_path = os.path.join(
            self._temporary_package_directory,
            "main",
            "default",
            "experiences",
            self._experience_bundle_name,
            "themes",
        )

        for theme_file_dir_entry in os.scandir(themes_path):
            if theme_file_dir_entry.is_file():
                self.logger.info(f"  {theme_file_dir_entry.name}")

                theme_file = Path(theme_file_dir_entry.path)

                # Replace all "navigationMenuEditorRefresh" values with the navigation_menu option.
                # This should be safe since it seems only the forceCommunity:themeNav component has a navigationMenuEditorRefresh attribute.
                theme_file.write_text(
                    re.sub(
                        r'("navigationMenuEditorRefresh" ?: ?"\w*")',
                        '"navigationMenuEditorRefresh" : "{}"'.format(
                            self.options.get("navigation_menu")
                        ),
                        theme_file.read_text(),
                        flags=re.M,
                    )
                )