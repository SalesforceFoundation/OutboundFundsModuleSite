/*
 * Copyright (c) 2021, salesforce.com, inc.
 * All rights reserved.
 * SPDX-License-Identifier: BSD-3-Clause
 * For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/BSD-3-Clause
 */

/**
 * execute_anon.param1 option is a comma-delimited list of Application Names.
 *     e.g. param1: OutboundFundsNpsp,Outbound_Funds,Nonprofit_CRM
 * Query AppMenuItem.Name to see available names.
 * This script will execute successfully if a name is not found.
 */
final List<String> applicationNames = '%%%PARAM_1%%%'.split(',');
// Initialize applicationIdsByName with applicationNames.
final Map<String, Id> applicationIdsByName = new Map<String, Id>();
for (String applicationName : applicationNames) {
    applicationIdsByName.put(applicationName, (Id) null);
}
// Sort AppMenuItem records by applicationNames then original sort order.
final List<Id> unnamedApplicationIds = new List<Id>();
for (Schema.AppMenuItem appMenuItem : [
    SELECT Name, ApplicationId
    FROM AppMenuItem
    WHERE IsAccessible = TRUE
    ORDER BY SortOrder
]) {
    if (appMenuItem.ApplicationId != null) {
        if (applicationIdsByName.keySet().contains(appMenuItem.Name)) {
            applicationIdsByName.put(appMenuItem.Name, appMenuItem.ApplicationId);
        } else {
            unnamedApplicationIds.add(appMenuItem.ApplicationId);
        }
    }
}
final List<Id> sortedApplicationIds = new List<Id>();
for (String applicationName : applicationNames) {
    if (applicationIdsByName.get(applicationName) != null) {
        sortedApplicationIds.add(applicationIdsByName.get(applicationName));
    }
}
sortedApplicationIds.addAll(unnamedApplicationIds);
// Re-order the App Menu
AppLauncher.AppMenu.setOrgSortOrder(sortedApplicationIds);
