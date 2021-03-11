# Custom cci tasks in `dev/tasks`:

## `dev.tasks.debugger`

Contains utilities for debugging:

-   `debug()` to pretty-log dicts, lists, and sets
-   `log_title()` logs underlined text
-   `log_table()` home built to log information as a table

## `dev.tasks.namespaces`

### `dev.tasks.namespaces.InjectNamespaceBaseTask`

Supports a method `_inject_namespace(source_path)` that walks through `source_path` and calls `cumulusci.utils.inject_namespace` with the package's namespace. Supports:

-   Ignoring directories and its subdirectories starting with `.` or `_`
-   Ignoring files starting with `.` or `sfdx-project.json`

## `dev.tasks.sfdx`

### `dev.tasks.sfdx.BaseTaskWithSfdx`

Includes a command `_sfdx(commands)` which calls `cumulusci.core.sfdx.sfdx()` with commands joined by `" "` always including the option `--json` and gives the option to append the `--targetusername` as `self.org_config.sfdx_alias` if "addTargetUsername" option is `True`. Returns the JSON response as a `dict`.

### `dev.tasks.sfdx.SfdxEtlWithNamespaceInjectionTask`

An "extract, transform, and load (ETL)" style task to extract and transform metadata into a temporary directory leaving the original metadata unchanged. - As a bonus, since sfdx will be called in the temporary directory, the sfdx commands
do **NOT** inherit the original directory's `.forceignore`! This means the developer never has to change their `.forceignore` to use this class!

## `dev.tasks.deploy`

### `dev.tasks.deploy.SfdxDeployWithNamespaceInjection`

A [dev.tasks.sfdx.SfdxEtlWithNamespaceInjectionTask](#dev.tasks.sfdx.SfdxEtlWithNamespaceInjectionTask) that calls `sfdx force:source:deploy` for the given `source_path` directory. Since this is a `dev.tasks.sfdx.SfdxEtlWithNamespaceInjectionTask`, all files in the directory are namespaced injected. - This works for any sfdx package directory, e.g. `force-app`, `dev/unpackaged/add_custom_tabs_for_admin`

## `dev.tasks.community_templates`

### `dev.tasks.community_templates.ExportCommunityTemplateTask`

A [dev.tasks.sfdx.SfdxEtlWithNamespaceInjectionTask](#dev.tasks.sfdx.SfdxEtlWithNamespaceInjectionTask) supporting developing Community Templates in the Community Builder which doesn't offer a way to update an existing Community Template. To use this task, make your changes in the Community Builder, then export another "temporary" Community Template but make sure the API Name starts with the packaged Community Template's API Name. This task then:

-   Retrieves both the packaged and temporary Community Template metadata,
-   Copies the changes in the temporary metadata to the packaged metadata, retrieves and injects a namespaced token into referenced `ContentAsset` metadata
-   Copies the changes back to the package directory
-   Deploys the changes to the org
