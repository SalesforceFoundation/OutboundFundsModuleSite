"""
 * Copyright (c) 2021, salesforce.com, inc.
 * All rights reserved.
 * SPDX-License-Identifier: BSD-3-Clause
 * For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/BSD-3-Clause
 *
"""

""""
Steps:

1) Retrieve Network, extract picassoSite (is the API Name of ExpBundle)
2) Retrieve ExperienceBundle
3) Update themes: loop over all *.json files in themes directory
    - navigationMenuEditorRefresh

"""
import os
import re
from tempfile import mkstemp
from shutil import move
import xml.etree.ElementTree as ET
from cumulusci.core.exceptions import CumulusCIException
from os import path, fdopen, remove
from dev.tasks.debugger import log_title
from dev.tasks.sfdx import SfdxEtlWithNamespaceInjectionTask


class ReplaceThemeLayoutNavigationMenuTask(SfdxEtlWithNamespaceInjectionTask):

    task_options = {
        "network_name": {"description": ("Name of Network"), "required": True},
        "navigation_menu": {
            "description": "NavigationMenu API name that will replace the default Navigation Menus in the community theme layout.",
            "required": True,
        },
        **SfdxEtlWithNamespaceInjectionTask.task_options,
    }

    def _retrieve_network(self):
        result = self._sfdx(
            [
                "force:source:retrieve",
                '--metadata="Network:{}"'.format(self.options.get("network_name")),
            ],
            addTargetUsername=True,
        )

        self.retrieved_file_paths = set()
        for inbound_file in result["inboundFiles"]:
            self.retrieved_file_paths.add(inbound_file["filePath"])

        # raise CumulusCIException is no results found.
        if not result["inboundFiles"]:
            raise CumulusCIException(
                'Metadata not found: "Network:{}"'.format(
                    self.options.get("network_name")
                )
            )

    def _set_experience_bundle_name(self):
        """
        1) Open Network file
        2) Extract picassoSite with regex.
        3) set self._experience_bundle_name = picassoSite
        """
        basepath = path.dirname(self._temporary_package_directory)
        filepath = path.abspath(path.join(basepath, self.retrieved_file_paths.pop()))

        tree = ET.parse(filepath)
        root = tree.getroot()

        for elem in root.findall(
            "{http://soap.sforce.com/2006/04/metadata}picassoSite"
        ):
            picasso_site = elem.text

        self._experience_bundle_name = picasso_site

    def _retrieve_experience_bundle(self):
        result = self._sfdx(
            [
                "force:source:retrieve",
                '--metadata="ExperienceBundle:{}"'.format(self._experience_bundle_name),
            ],
            addTargetUsername=True,
        )

        self.theme_file_paths = set()

        for item in result["inboundFiles"]:
            full_name = item["fullName"]
            match = self._experience_bundle_name + "/themes" in full_name
            if match:
                self.theme_file_paths.add(item["filePath"])

        # raise CumulusCIException is no results found.
        if not result["inboundFiles"]:
            raise CumulusCIException(
                'Metadata not found: "ExperienceBundle:{}"'.format(
                    self.options.get(self._experience_bundle_name)
                )
            )

    def _deploy_experience_bundle(self):
        result = self._sfdx(
            [
                "force:source:deploy",
                '--metadata="ExperienceBundle:{}"'.format(self._experience_bundle_name),
            ],
            addTargetUsername=True,
        )

        # raise CumulusCIException is no results found.
        if not result["deployedSource"]:
            raise CumulusCIException(
                'Metadata not found: "ExperienceBundle:{}"'.format(
                    self.options.get(self._experience_bundle_name)
                )
            )

    def _replace_theme_navigation_menus(self):
        """
        Replaces default navigation with navigation menu specified in the option navigation_menu
        """
        basepath = path.dirname(self._temporary_package_directory)
        filepath = path.abspath(path.join(basepath, self.theme_file_paths.pop()))

        fh, abs_path = mkstemp()
        log_title(
            "Adding navigation menu: {} to community pages".format(
                self.options["navigation_menu"]
            ),
            self.logger.info,
        )
        page_count = 0
        with fdopen(fh, "w") as new_file:
            with open(filepath) as old_file:
                substitution = '"navigationMenuEditorRefresh" : "{}"'.format(
                    self.options["navigation_menu"]
                )
                for line in old_file:
                    updated_line = re.sub(
                        r'("navigationMenuEditorRefresh" ?: ?.*$)',
                        substitution,
                        line,
                    )
                    new_file.write(updated_line)
                    if updated_line != line:
                        page_count += 1

        self.logger.info("Number of Community Pages updated: {}".format(page_count))

        # Remove original file
        remove(filepath)
        # Move new file
        move(abs_path, filepath)

    def _debug_temporary_directory(self):
        self.logger.warn("debugging temporary package directory")
        self.logger.warn("")
        self.logger.warn(f"temporary directory: {self._temporary_directory}")
        self.list_files(self._default_package_directory)

    def _sfdx_extract(self):
        # Create default package directory in temporary directory
        self._temporary_package_directory = os.path.join(
            self._temporary_directory, self._default_package_directory
        )
        self._retrieve_network()
        self._set_experience_bundle_name()

        self._retrieve_experience_bundle()

    def _sfdx_transform(self):
        self._replace_theme_navigation_menus()

    def _sfdx_load(self):
        self._deploy_experience_bundle()
