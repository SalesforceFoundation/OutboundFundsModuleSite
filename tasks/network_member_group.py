"""
 * Copyright (c) 2021, salesforce.com, inc.
 * All rights reserved.
 * SPDX-License-Identifier: BSD-3-Clause
 * For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/BSD-3-Clause
 *
"""

from typing import List, Dict
from cumulusci.tasks.salesforce import BaseSalesforceApiTask
from cumulusci.core.exceptions import SalesforceException, CumulusCIException
from cumulusci.core.utils import process_list_arg


class CreateNetworkMemberGroups(BaseSalesforceApiTask):
    """
    Creates NetworkMemberGroup for a Network for Profiles and Permission Sets
    that don't already have a corresponding NetworkMemberGroup.

    Raises exceptions if records cannot be found:
    - Network with Name network_name
    - Profiles with Names in profile_names
    - Permission Sets with Names in permission_set_names
    """

    task_options = {
        "network_name": {
            "description": (
                "Name of Network to add NetworkMemberGroup children records."
            ),
            "required": True,
        },
        "profile_names": {
            "description": (
                "List of Profile Names to add as NetworkMemberGroups "
                "for this Network."
            ),
            "required": False,
        },
        "permission_set_names": {
            "description": (
                "List of PermissionSet Names to add as NetworkMemberGroups "
                "for this Network."
            ),
            "required": False,
        },
    }

    def _get_network_id(self, network_name: str) -> str:
        """
        Returns Id of Network record with Name network_name.
        Raises a SalesforceException if no Network is found.
        """

        networks = self.sf.query(
            f"SELECT Id FROM Network WHERE Name = '{network_name}' LIMIT 1"
        )

        if not networks["records"]:
            raise SalesforceException(
                f'No Network record found with Name "{network_name}"'
            )
        self.logger.info(
            "Creating NetworkMemberGroup records for " f'"{network_name}" Network:'
        )
        return networks["records"][0]["Id"]

    def _get_network_member_group_parent_ids(self, network_id) -> set:
        """
        Collect existing NetworkMemberGroup Parent IDs.  An excpetion is thrown
        trying to create a NetworkMemberGroup for a parent who already has a
        record.
        """

        network_member_group_parent_ids = set()
        for record in self.sf.query(
            f"SELECT ParentId FROM NetworkMemberGroup WHERE NetworkId = '{network_id}'"  # noqa: E501
        )["records"]:
            network_member_group_parent_ids.add(record["ParentId"])
        return network_member_group_parent_ids

    def _get_parent_ids_by_name(
        self, sobject_type: str, record_names: List[str]
    ) -> Dict[str, str]:
        """
        Returns a Dict: Name --> ID of records with Name in record_names for
        sObject_type.   Dict value are None for all record_names that do not
        have corresponding records.
        """

        parent_ids_by_name = dict((name, None) for name in record_names)
        for record in self.sf.query(
            "SELECT Id, Name FROM {} WHERE Name IN ('{}')".format(
                sobject_type,
                "','".join(record_names),
            )
        )["records"]:
            parent_ids_by_name[record["Name"]] = record["Id"]
        return parent_ids_by_name

    def _process_parent(self, sobject_type: str, record_names: List[str]) -> None:
        """
        For a specific sobject_type and record_names, queries all Salesforce IDs
        corresponding to records of SObjectType sobject_type with Name in
        record_names.   Then, tries to create NetworkMemberGroup for each
        parent in record_names.
        """

        if not record_names:
            return

        self.logger.info(f"    {sobject_type}:")

        # Collect Parent IDs by Name.
        parent_ids_by_name = self._get_parent_ids_by_name(sobject_type, record_names)

        # Create NetworkMemberGroup records.
        for parent_name, parent_id in parent_ids_by_name.items():
            self._create_network_member_group(sobject_type, parent_name, parent_id)

    def _create_network_member_group(
        self, sobject_type: str, parent_name: str, parent_id: str
    ) -> None:
        """
        Processes and logs creating a NetworkMemberGroup for a specific parent.

        Outcomes:
        - Raises a CumulusCIException if record_id is None meaning
          no corresponding record was found in _get_parent_ids_by_name.
        - Logs a warning that a NetworkMemberGroup already exists is parent_id
          is in self._parent_ids.
        - Creates a NetworkMemberGroup for parent_id and logs the result.
        """

        # Assert a Parent was found for each Name.
        if not parent_id:
            raise CumulusCIException(
                f'No {sobject_type} record found with Name "{parent_name}"'
            )

        if parent_id in self._parent_ids:
            self.logger.warn(f'        Already exists for "{parent_name}"')
        else:
            insert_response = self.sf.NetworkMemberGroup.create(
                {"NetworkId": self._network_id, "ParentId": parent_id}
            )
            if insert_response.get("success") is True:
                self.logger.info(f'        "{parent_name}"')
            else:
                # It might be impossible to get to this state.
                # If there's a query exception, it gets thrown before this is called.
                raise SalesforceException(
                    f'Error creating NetworkMemberGroup for Network "{self._network_id}" for parent {sobject_type} "{parent_name}" {parent_id}.   Errors: {", ".join(insert_response.get("errors") or [])}'  # noqa: E501
                )

    def _run_task(self):
        """
        Gets required information then tries to create NetworkMemberGroups for
        Profiles and Permission Sets cooresponding to profile_names and
        permission_set_names respectively.
        """

        self._network_id = self._get_network_id(self.options["network_name"])
        self._parent_ids = self._get_network_member_group_parent_ids(self._network_id)

        # Create NetworkMemberGroup records.
        for sobject_type, record_names in {
            "Profile": process_list_arg(self.options.get("profile_names") or []),
            "PermissionSet": process_list_arg(
                self.options.get("permission_set_names") or []
            ),
        }.items():
            self._process_parent(sobject_type, record_names)
