import os
import re

# TODO: use lxml instead of xml.etree.ElementTree
import xml.etree.ElementTree as et
import xml.dom.minidom
from distutils.dir_util import copy_tree
from cumulusci.core.utils import process_bool_arg
from cumulusci.core.exceptions import CumulusCIException, SalesforceException

# TODO: Use fancytables instead of dev.tasks.debugger
from dev.tasks.debugger import debug, log_title, log_table
from dev.tasks.sfdx import SfdxEtlWithNamespaceInjectionTask


def to_pretty_xml_string(root):
    new_content = xml.dom.minidom.parseString(et.tostring(root)).toprettyxml()
    new_content = os.linesep.join([s for s in new_content.splitlines() if s.strip()])
    return new_content


class ExportCommunityTemplateTask(SfdxEtlWithNamespaceInjectionTask):
    """
    Task to speed up developing Community Templates in the Experience Builder.

    When exporting a Community Template in the Experience Builder, any API Name for the
    Community Template must be entered along with other metadata describing the Community
    Template that will be displayed to end users.  For illustration, let's say the
    Community Template API Name is "Grants".  This API Name is then embedded in all
    metadata related to the Community Template.  For illustration, here are the API Names
    for the related Community Template metadata:
    - The CommunityTemplateDefinition API Name is "Grants".
    - The CommunityThemeDefinition API Name is also "Grants".
    - The BrandingSet API Name is also "Grants".
    - All FlexiPage API Names are prefixed with "Grants_".

    There is no mechanism in the Experience Builder to update an existing Community
    Template.  One can only export a Community Template with an API that does not already
    exist.

    One solution to this problem is to only make changes to the metadata files in
    the packaged Community Template.  However, this is far from ideal and difficult for
    most developers.

    Another solution is to make changes in the Experience Bundle and export another
    "temporary" Community Template with a different API Name.  Then, retrieve the
    "temporary" metadata and replace the contents of the cooresponding packaged Community
    Template metadata with the contents of the temporary Community Template metadata.
    This task is to automate this approach taking additional steps to:
    - Only copy over functional changes from CommunityTemplateDefinition and
      CommunityThemeDefinition metadata and not copy over metadata exposed to the end
      users.  This saves time for the developer not to accidentally overwrite this
      end user exposed metadata.  But this also means that overwriting this end user
      expose metadata must be done manually.  Thankfully, these changes are very
      infrequent.
    - All ContentAsset references need to be namespaced injected.  We've automated
      injecting the namespace token "%%%NAMESPACE%%%" before all ContentAsset references.
    - We also retrieve all ContentAsset metadata referenced in the Community Template
      instead of copying over all ContentAsset metadata.
    """

    task_options = {
        **SfdxEtlWithNamespaceInjectionTask.task_options,
        "template_name": {
            "description": 'API Name of the packaged CommunityTemplateDefinition.  The temporary CommunityTemplateDefinition API Name must start with this template_name.  E.g. the API Name of the packaged CommunityTemplateDefinition is "Grants", so template_name is also "Grants".  Then, any temporary CommunityTemplateDefinitions must start with "Grants".',
            "required": True,
        },
        "suffix": {
            "description": 'The part of the temporary CommunityTemplateDefinition\'s API Name after the packaged CommunityTemplateDefinition\'s API Name.  E.g. the packaged CommunityTemplateDefinition is "Grants", the temporary CommunityTemplateDefinition API Name is "Grants3", so the suffix is "3".',
            "required": True,
        },
        "export_template": {
            "description": "If to export and overwrite the template's CommunityTemplateDefinition's pageSettings.  Default: False",
            "required": False,
            "default": False,
        },
        "export_theme": {
            "description": "If to copy the temporary CommunityThemeTemplate to the packaged directory.   .  Default: False",
            "required": False,
            "default": False,
        },
        "export_branding_set": {
            "description": "If to export and overwrite the template's BrandingSet.  Default: False",
            "required": False,
            "default": False,
        },
        "export_flexipages": {
            "description": "If to export and overwrite the template's FlexiPages.  Default: False",
            "required": False,
            "default": False,
        },
        "copy_temporary_metadata": {
            "description": "If True, copies temporary metadata to the default package directory and does NOT transform existing, packaged metadata.  Use this option to inspect the temporary metadata.   Default: False",
            "required": False,
        },
    }

    def _debug(self, value, title=None, show_list_index=True):
        debug(
            value, title=title, logger=self.logger.info, show_list_index=show_list_index
        )

    def _log_title(self, title):
        log_title(title, logger=self.logger.info)

    def _log_table(
        self,
        raw_rows,
        groupByBlankColumns=False,
        rowBorders=True,
        columnBorders=True,
        padColumns=True,
        addHeaderBorder=True,
        logger=None,
    ):
        log_table(
            raw_rows,
            groupByBlankColumns=False,
            rowBorders=True,
            columnBorders=True,
            padColumns=True,
            addHeaderBorder=True,
            logger=(self.logger.info if logger is None else logger),
        )

    def _init_options(self, kwargs):
        super()._init_options(kwargs)
        # Process options to:
        # - generate metadata API Names
        # - copy but do not process temporary metadata
        self.template_name = self.options.get("template_name")
        self.temporary_template_name = "{}{}".format(
            self.template_name, self.options.get("suffix"),
        )
        self._copy_temporary_metadata = process_bool_arg(
            self.options.get("copy_temporary_metadata")
        )

        # Prevent exporting Community Template metadat from a namespaced org.
        # It is known references to FlexiPages in CommunityTemplateDefinition
        # and CommunityThemeDefinition metadata do not have the FlexiPage references
        # properly injected.  Plus, we don't have to package either metadata with
        # namespace references.
        if self.org_config.namespaced:
            raise CumulusCIException(
                f'You cannot export Community Template metadata from a namespaced org.  References to other metadata may not have the namespace properly injected when exporting a Community Template from the Community Builder.  E.g. FlexiPage themeLayout references in CommunityTemplateDefinition and CommunityThemeDefinition metadata are not properly formatted.  Try it yourself: call `sfdx force:source:retrieve --metadata:"CommunityTemplateDefinition{self.temporary_template_name}"` and inspect the themeLayout references in the retrieved "{self.temporary_template_name}" CommunityTemplateDefinition compared to the packaged "{self.template_name}" CommunityTemplateDefinition.'
            )

        self.metadata_to_process = {}

        self._is_export_template = process_bool_arg(self.options.get("export_template"))
        self._is_export_branding_set = process_bool_arg(
            self.options.get("export_branding_set")
        )
        self._is_export_theme = process_bool_arg(self.options.get("export_theme"))
        self._is_export_flexipages = process_bool_arg(
            self.options.get("export_flexipages")
        )

        # Verify at least one export_[metadata type] option is selected.
        # Otherwise, there would be no metadata to process.
        if not (
            self._is_export_template
            or self._is_export_branding_set
            or self._is_export_theme
            or self._is_export_flexipages
        ):
            raise CumulusCIException(
                "At least one of the following options must be selected, else there would be no metadata to process: {}".format(
                    ", ".join(
                        [
                            "export_template",
                            "export_theme",
                            "export_branding_set",
                            "export_flexipages",
                        ]
                    )
                )
            )

    def _process_template(self):
        """
        Only extract and replace <pageSetting> elements.
        """
        self._replace_xml_tags(
            "communityTemplateDefinitions",
            "communityTemplateDefinition-meta.xml",
            "pageSetting",
            ["page", "themeLayout"],
        )

    def _process_theme(self):
        """
        Only extract and replace <themeSetting> elements.
        """
        self._replace_xml_tags(
            "communityThemeDefinitions",
            "communityThemeDefinition-meta.xml",
            "themeSetting",
            ["themeLayout", "themeLayoutType"],
        )

    def _process_branding_sets(self):
        """
        Replace packaged file content with the temporary file's content.
        """
        self._replace_file_content("brandingSets", r"\.brandingSet-meta.xml")

    def _process_flexipages(self):
        """
        Replace packaged file content with the temporary file's content.
        """
        self._replace_file_content(
            "flexipages", r"_[A-Za-z]\w+\.flexipage-meta.xml", False
        )

    def _sfdx_extract(self):
        # Retrieve both packaged and temporary metadata.
        metadata_to_retrieve = []

        if self._is_export_template:
            metadata_to_retrieve.append(
                f"CommunityTemplateDefinition:{self.template_name},CommunityTemplateDefinition:{self.temporary_template_name}"
            )

        if self._is_export_theme:
            metadata_to_retrieve.append(
                f"CommunityThemeDefinition:{self.template_name},CommunityThemeDefinition:{self.temporary_template_name}"
            )

        if self._is_export_branding_set:
            metadata_to_retrieve.append(
                f"BrandingSet:{self.template_name},BrandingSet:{self.temporary_template_name}"
            )

        # We currently retrieve all FlexiPages but add a mechianism to only process
        # FlexPages whose API Name starts with the template_name.
        # TODO: All FlexiPages used in the Community Template are referenced in the
        #       CommunityTemplateDefinition's <pageSetting> elements.  We could first
        #       retrieve the CommunityTemplateDefinition, extract which FlexiPages are
        #       referenced, then do a second retrieve of referenced FlexiPages.
        if self._is_export_flexipages:
            metadata_to_retrieve.append("FlexiPage")

        try:
            result = self._sfdx(
                [
                    "force:source:retrieve",
                    "--metadata='{}'".format(",".join(metadata_to_retrieve)),
                ]
            )
        except SalesforceException as e:
            self.logger.warn('Double check you entered the correct "suffix" option.')
            self.logger.warn("")
            raise e

        # Save which files were retrieved, so we know which files to process in case there
        # are non-Community Template files in the metadata directories.  E.g. there could
        # exist non-Community Template FlexiPages.
        # TODO: If implementing TODO above "if self._is_export_flexipages", this step
        #       becomes unnecessary and could be removed.
        self.retrieved_file_paths = set()
        for inbound_file in result["inboundFiles"]:
            self.retrieved_file_paths.add(inbound_file["filePath"])

    def _sfdx_transform(self):
        # Log a warning if temporary metadata is only to be copied and not transformed.
        if self._copy_temporary_metadata:
            self.logger.info("")
            log_title("WARNING", self.logger.warn)
            self.logger.warn("No metadata is being overwritten!")
            self.logger.warn(
                "Since copy_temporary_metadata option is True, no temporary files are overwriting packaged metadata."
            )
            self.logger.warn(
                "However, temporary metadata is being copied to the default package directory for manual inspection."
            )
            self.logger.warn("")
        else:
            # Process metadata.
            self._referenced_content_assets = set()

            if self._is_export_template:
                self._process_template()

            if self._is_export_theme:
                self._process_theme()

            if self._is_export_branding_set:
                self._process_branding_sets()

            if self._is_export_flexipages:
                self._process_flexipages()

            # Copy all referenced ContentAssets to the default package directory.
            # ContentAssets are not modified and do not need to be deployed in _sfdx_load().
            if self._referenced_content_assets:
                rows = [["ContentAsset"]]
                metadata = []
                for content_asset in self._referenced_content_assets:
                    rows.append([content_asset])
                    metadata.append(f"ContentAsset:{content_asset}")

                self.logger.debug(
                    f"Copying all referenced ContentAsset metadata to {self._default_package_directory}"
                )
                self._log_table(rows)
                self.logger.debug("")

                self._sfdx(
                    [
                        "force:source:retrieve",
                        '--metadata="{}"'.format(",".join(metadata)),
                    ],
                    addTargetUsername=True,
                )

        # Processed files may contain namespace tokens for ContentAsset references.
        # Copy the processed files to the current directory.
        # The SfdxEtlWithNamespaceInjectionTask will inject the package's namespace into the
        # namespace tokens before _sfdx_load() is called.
        copy_tree(
            os.path.join(self._temporary_directory, self._default_package_directory),
            os.path.join(self._current_directory, self._default_package_directory),
        )

    def _sfdx_load(self):
        if self._copy_temporary_metadata:
            return

        # Deploy the packaged (and transformed) metadata.
        metadata_to_deploy = []

        if self._is_export_template:
            metadata_to_deploy.append(
                f"CommunityTemplateDefinition:{self.template_name}"
            )

        if self._is_export_theme:
            metadata_to_deploy.append(f"CommunityThemeDefinition:{self.template_name}")

        if self._is_export_branding_set:
            metadata_to_deploy.append(f"BrandingSet:{self.template_name}")

        if self._is_export_flexipages:
            metadata_to_deploy.append("FlexiPage")

        try:
            self._sfdx(
                [
                    "force:source:deploy",
                    "--metadata='{}'".format(",".join(metadata_to_deploy)),
                ]
            )
        except SalesforceException as e:
            # Log a warning if exporting CommunityTemplateDefinition or CommunityThemeDefinition metadata
            # but NOT FlexiPage metadata. If FlexiPage metadata are not also exported, the
            # CommunityTemplateDefinition or CommunityThemeDefinition metadata may reference
            # FlexiPage metadata that does not exist (since the temporary metadata is transformed into
            # packaged metadata).
            if not self._is_export_flexipages and (
                self._is_export_template or self._is_export_theme
            ):
                self.logger.warn(
                    'Try setting "export_flexipages" option as True to also export FlexiPage metadata.'
                )
                self.logger.warn(
                    "CommunityTemplateDefinition and CommunityThemeDefinition metadata may reference packaged FlexiPage metadata that might not exist."
                )
                self.logger.warn("")
            raise e

    def _inject_namespace_token_into_content_asset_references(self, file_content):
        """
        Finds all referenced ContentAsset metadata to:
        - Retrieve later
        - Inject the "%%%NAMESPACE%%%" namespace token to be propertly namespaced.
        """
        # Find all ContentAsset references
        content_asset_matches = re.findall(r"\/file-asset\/([A-Za-z]\w+)", file_content)

        if content_asset_matches:
            # Collect the ContentAsset API Names referenced to copy to the package directory.
            self._referenced_content_assets.update(content_asset_matches)

            # Log injecting namespace tokens into ContentAsset references.
            self.logger.debug(
                "Injecting namespace token into any ContentAsset references."
            )
            self.logger.debug('"/file-asset/" → "/file-asset/%%%NAMESPACE%%%"')
            rows = [["ContentAsset"]]
            for content_asset in content_asset_matches:
                self._referenced_content_assets.add(content_asset)
                rows.append([content_asset])

            self._log_table(rows, logger=self.logger.debug)
            self.logger.debug("")

            return file_content.replace("/file-asset/", "/file-asset/%%%NAMESPACE%%%")
        else:
            return file_content

    def _replace_template_name_references(self, file_content):
        return file_content.replace(self.temporary_template_name, self.template_name)

    def _replace_file_content(
        self, directory: str, file_suffix_regex: str, replace_template_name=True
    ):
        """
        "Renames" the temporary metadata as the packaged metadata while collecting and
        injecting namespace tokens into ContentAsset references with the option to replace
        all Community Template references from the temporary template name to the
        packaged template name.
        """
        # Set the path to the metadata directory we're interested in.
        metadata_directory = os.path.join(
            self._temporary_directory,
            self._default_package_directory,
            "main",
            "default",
            directory,
        )
        absolute_metadata_directory = os.path.join(
            self._temporary_directory, metadata_directory
        )

        # Log what we're processing.
        self._log_title(f"Processing {metadata_directory}")

        # Save which files we're processing and what processing happens.
        files_replacing_template_name = []
        rename_file_rows = []
        deleted_previous_version_files = []

        # Process files.
        for dir_entry in os.scandir(absolute_metadata_directory):
            # Only process files that start with the template_name to avoid
            # processing non-Community Template related files.
            if dir_entry.is_file() and dir_entry.name.startswith(self.template_name):
                # Detect if the file is the packaged file, temporary file, or belong to previous temporary file versions.
                packaged_file_matches = re.match(
                    r"{}({})".format(self.template_name, file_suffix_regex),
                    dir_entry.name,
                )
                temporary_matches = re.match(
                    r"{}({})".format(self.temporary_template_name, file_suffix_regex),
                    dir_entry.name,
                )

                if packaged_file_matches:
                    # File is the packaged file. Do nothing.
                    pass
                elif temporary_matches:
                    # File is the temporary file.  If replace_template_name,
                    # Replaces temporary_template_name with template_name.
                    # Then, overwrite packaged file's content with the temporary files's content.
                    # Finally, delete the temporary file.
                    with open(dir_entry.path, "r") as f:
                        #  Replace temporary_template_name references with template_name.
                        if replace_template_name:
                            files_replacing_template_name.append(dir_entry.name)
                            data = self._replace_template_name_references(f.read())
                        else:
                            data = f.read()

                    # Overwrite packaged file's content with temporary file's content.
                    packaged_file_name = (
                        f"{self.template_name}{temporary_matches.group(1)}"
                    )

                    rename_file_rows.append([dir_entry.name, packaged_file_name])

                    with open(
                        os.path.join(metadata_directory, packaged_file_name), "w",
                    ) as f:
                        f.write(
                            self._inject_namespace_token_into_content_asset_references(
                                data
                            )
                        )

                    # Delete temporary file since we replaced the packaged file's content above.
                    os.remove(dir_entry.path)

                elif dir_entry.path in self.retrieved_file_paths:
                    """
                    File is a previous file version because the file name starts with template_name.
                    File was retrieved by this Task because its path is in retrieved_file_paths.
                    Delete the file.
                    """
                    deleted_previous_version_files.append(dir_entry.name)
                    os.remove(dir_entry.path)

        # Log what was processed.
        if replace_template_name:
            rows = [
                [
                    'Replacing template references "{}" → "{}" for files'.format(
                        self.temporary_template_name, self.template_name
                    )
                ]
            ]

            for file_name in files_replacing_template_name:
                rows.append([file_name])
            self._log_table(rows)
            self.logger.info("")

        if rename_file_rows:
            self.logger.info("Renaming files")
            rows = [["FROM", "TO"]]
            rows.extend(rename_file_rows)
            self._log_table(rows)
            self.logger.info("")

        if deleted_previous_version_files:
            self._debug(
                deleted_previous_version_files,
                title="Deleting files that appear to be from previous Community Template versions",
                show_list_index=False,
            )
            self.logger.info("")

    def _replace_xml_tags(
        self, directory: str, file_suffix: str, tag_name: str, tag_property_names: list
    ):
        """
        Extracts XML elements of the specified tag name from the temporary metadata and
        replaces all XML elements of the specified tag name from the packaged metadata
        with XML elements extracted from the temporary file.

        Assumes the XML elements of the specified tag name have child elements one level
        deep with tags in tag_property_names.
        """
        metadata_directory = os.path.join(
            self._default_package_directory, "main", "default", directory,
        )
        absolute_metadata_directory = os.path.join(
            self._temporary_directory, metadata_directory
        )

        self._log_title(f"Processing {metadata_directory}")

        tag_rows = []

        # Register namespace with ElementTree so namespace is written as blank.
        namespace = "http://soap.sforce.com/2006/04/metadata"
        et.register_namespace("", namespace)

        packaged_file_name = f"{self.template_name}.{file_suffix}"
        tag_query = f"{{{namespace}}}{tag_name}"

        # Set temporary file's tags.
        with open(
            os.path.join(
                absolute_metadata_directory,
                f"{self.temporary_template_name}.{file_suffix}",
            ),
            "r",
        ) as f:
            temporary_file_tags = et.parse(f).getroot().findall(tag_query)

        for tag in temporary_file_tags:
            tag_row = []
            tag_rows.append(tag_row)

            for tag_property_name in tag_property_names:
                found_tag = tag.find((f"{{{namespace}}}{tag_property_name}"))
                if found_tag is not None:
                    tag_row.append(tag.find(f"{{{namespace}}}{tag_property_name}").text)

        # Set packaged file's ElementTree.
        with open(
            os.path.join(absolute_metadata_directory, packaged_file_name,), "r"
        ) as f:
            packaged_file_tree = et.parse(f)

        root = packaged_file_tree.getroot()

        # Remove all tag elements from packaged file's ElementTree.
        for tag in root.findall(tag_query):
            root.remove(tag)

        # Append each of temporary file's tags.
        root.extend(temporary_file_tags)

        # Overwrite packaged file with tags replaced from temporary file.
        with open(
            os.path.join(absolute_metadata_directory, packaged_file_name,), "w"
        ) as f:
            f.write(
                self._replace_template_name_references(
                    self._inject_namespace_token_into_content_asset_references(
                        to_pretty_xml_string(root)
                    )
                )
            )

        # Delete temporary file.
        os.remove(
            os.path.join(
                absolute_metadata_directory,
                f"{self.temporary_template_name}.{file_suffix}",
            )
        )

        # Log replacing template references names.
        self._log_table(
            [
                [
                    f'Replacing template references "{self.temporary_template_name}" → "{self.template_name}"'
                ],
                [packaged_file_name],
            ]
        )
        self.logger.info("")

        # Log tags that were replaced.
        if tag_rows:
            self.logger.debug(
                f'Replace "{self.temporary_template_name}" {tag_name} elements with → "{self.template_name}" {tag_name} elements'
            )
            rows = [tag_property_names]
            rows.extend(tag_rows)
            self._log_table(rows)
            self.logger.info("")
