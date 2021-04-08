# * Copyright (c) 2021, salesforce.com, inc.
# * All rights reserved.
# * SPDX-License-Identifier: BSD-3-Clause
# * For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/BSD-3-Clause
# *

import pytest  # noqa: F401
import unittest
from unittest.mock import Mock, call
from cumulusci.tasks.salesforce.tests.util import create_task
from tasks.network_member_group import CreateNetworkMemberGroups
from cumulusci.core.exceptions import SalesforceException, CumulusCIException


class TestCreateNetworkMemberGroups(unittest.TestCase):
    """
    Unit tests tasks.network_member_group.CreateNetworkMemberGroups.
    """

    def test_task_options(self):
        self.assertTrue(CreateNetworkMemberGroups.task_options)

        self.assertEqual(
            set(["network_name", "profile_names", "permission_set_names"]),
            CreateNetworkMemberGroups.task_options.keys(),
        )

        # network_name
        network_name = CreateNetworkMemberGroups.task_options["network_name"]
        self.assertTrue(network_name)
        self.assertEqual(
            "Name of Network to add NetworkMemberGroup children records.",
            network_name["description"],
        )
        self.assertEqual(True, network_name["required"])

        # profile_names
        profile_names = CreateNetworkMemberGroups.task_options["profile_names"]
        self.assertTrue(profile_names)
        self.assertEqual(
            "List of Profile Names to add as NetworkMemberGroups for this Network.",  # noqa: E501
            profile_names["description"],
        )
        self.assertEqual(False, profile_names["required"])

        # network_name
        permission_set_names = CreateNetworkMemberGroups.task_options[
            "permission_set_names"
        ]
        self.assertTrue(permission_set_names)
        self.assertEqual(
            (
                "List of PermissionSet Names to add as NetworkMemberGroups "
                "for this Network."
            ),
            permission_set_names["description"],
        )
        self.assertEqual(False, permission_set_names["required"])

    def test_get_network_id__no_network_found(self):
        network_name = "network_name"

        task = create_task(CreateNetworkMemberGroups, {"network_name": network_name})

        task.sf = Mock()
        task.sf.query = Mock(return_value={"records": []})

        task.logger = Mock()
        task.logger.info = Mock()

        # Execute the test.
        with self.assertRaises(SalesforceException) as context:
            task._get_network_id(network_name)

        # Assert scenario execute as expected.
        self.assertEqual(
            f'No Network record found with Name "{network_name}"',
            context.exception.args[0],
        )

        task.sf.query.assert_called_once_with(
            f"SELECT Id FROM Network WHERE Name = '{network_name}' LIMIT 1"
        )

        task.logger.info.assert_not_called()

    def test_get_network_id__network_found(self):
        network_name = "network_name"

        task = create_task(CreateNetworkMemberGroups, {"network_name": network_name})

        task.sf = Mock()
        task.sf.query = Mock(return_value={"records": [{"Id": "NetworkId"}]})

        task.logger = Mock()
        task.logger.info = Mock()

        expected = task.sf.query.return_value["records"][0]["Id"]

        # Execute the test.
        actual = task._get_network_id(network_name)

        # Assert scenario execute as expected.
        self.assertEqual(expected, actual)

        task.sf.query.assert_called_once_with(
            f"SELECT Id FROM Network WHERE Name = '{network_name}' LIMIT 1"
        )

        task.logger.info.assert_called_once_with(
            'Creating NetworkMemberGroup records for "{}" Network:'.format(network_name)
        )

    def test_get_network_member_group_parent_ids(self):
        network_name = "network_name"
        network_id = "network_id"

        task = create_task(CreateNetworkMemberGroups, {"network_name": network_name})

        task.sf = Mock()
        task.sf.query = Mock(
            return_value={
                "records": [
                    {"ParentId": "0"},
                    {"ParentId": "2"},
                    {"ParentId": "3"},
                    {"ParentId": "1"},
                ]
            }
        )

        expected = set(["0", "1", "2", "3"])

        # Execute the test.
        actual = task._get_network_member_group_parent_ids(network_id)

        # Assert scenario execute as expected.
        self.assertEqual(expected, actual)

        task.sf.query.assert_called_once_with(
            f"SELECT ParentId FROM NetworkMemberGroup WHERE NetworkId = '{network_id}'"  # noqa: E501
        )

    def test_get_parent_ids_by_name(self):
        network_name = "network_name"
        sobject_type = "sobject_type"
        record_names = [
            "Name_0",
            "Name_1",
            "Name_2",
        ]

        task = create_task(CreateNetworkMemberGroups, {"network_name": network_name})

        task.sf = Mock()
        task.sf.query = Mock(
            return_value={
                "records": [
                    {"Name": "Name_0", "Id": "Id_0"},
                    {"Name": "Name_2", "Id": "Id_2"},
                ]
            }
        )

        expected = {
            "Name_0": "Id_0",
            "Name_1": None,
            "Name_2": "Id_2",
        }

        # Execute the test.
        actual = task._get_parent_ids_by_name(sobject_type, record_names)

        # Assert scenario execute as expected.
        self.assertEqual(expected, actual)

        task.sf.query.assert_called_once_with(
            "SELECT Id, Name FROM {} WHERE Name IN ('{}')".format(
                sobject_type,
                "','".join(record_names),
            )
        )

    def test_process_parent__no_names(self):
        network_name = "network_name"
        sobject_type = "sobject_type"
        for record_names in [
            None,
            [],
        ]:
            self.assertFalse(record_names)

            task = create_task(
                CreateNetworkMemberGroups, {"network_name": network_name}
            )

            task.logger = Mock()
            task.logger.info = Mock()

            parent_ids_by_name = Mock()
            parent_ids_by_name.items = Mock()

            task._get_parent_ids_by_name = Mock(return_value=parent_ids_by_name)

            task._create_network_member_group = Mock()

            # Execute the test.
            task._process_parent(sobject_type, record_names)

            # Assert scenario execute as expected.
            task.logger.info.assert_not_called()

            task._get_parent_ids_by_name.assert_not_called()

            parent_ids_by_name.items.assert_not_called()

            task._create_network_member_group.assert_not_called()

    def test_process_parent__with_names(self):
        network_name = "network_name"
        sobject_type = "sobject_type"
        record_names = [
            "Name_0",
            "Name_1",
            "Name_2",
        ]

        self.assertTrue(record_names)

        task = create_task(CreateNetworkMemberGroups, {"network_name": network_name})

        task.logger = Mock()
        task.logger.info = Mock()

        parent_ids_by_name = Mock()
        parent_ids_by_name.items = Mock(
            return_value=[("Name_0", "Id_0"), ("Name_1", None), ("Name_2", "Id_2")]
        )

        task._get_parent_ids_by_name = Mock(return_value=parent_ids_by_name)

        task._create_network_member_group = Mock()

        expected_create_network_member_group_calls = []
        for parent_name, parent_id in parent_ids_by_name.items.return_value:
            expected_create_network_member_group_calls.append(
                call(sobject_type, parent_name, parent_id)
            )

        # Execute the test.
        task._process_parent(sobject_type, record_names)

        # Assert scenario execute as expected.
        task.logger.info.assert_called_once_with(f"    {sobject_type}:")

        task._get_parent_ids_by_name.assert_called_once_with(sobject_type, record_names)

        parent_ids_by_name.items.assert_called_once_with()

        task._create_network_member_group.assert_has_calls(
            expected_create_network_member_group_calls
        )

    def test_create_network_member_group__parent_not_found_in_query(self):
        network_name = "network_name"
        sobject_type = "sobject_type"
        parent_name = "parent_name"
        parent_id = None

        self.assertFalse(parent_id)

        task = create_task(CreateNetworkMemberGroups, {"network_name": network_name})

        task._parent_ids = set()

        task._network_id = "network_id"

        task.logger = Mock()
        task.logger.info = Mock()
        task.logger.warn = Mock()

        task.sf = Mock()
        task.sf.NetworkMemberGroup = Mock()

        insert_response = Mock()
        insert_response.get = Mock()
        task.sf.NetworkMemberGroup.create = Mock(insert_response)

        # Execute the test.
        with self.assertRaises(CumulusCIException) as context:
            task._create_network_member_group(sobject_type, parent_name, parent_id)

        # Assert scenario execute as expected.
        self.assertEqual(
            f'No {sobject_type} record found with Name "{parent_name}"',
            context.exception.args[0],
        )

        task.logger.info.assert_not_called()

        task.logger.warn.assert_not_called()

        task.sf.NetworkMemberGroup.create.assert_not_called()

    def test_create_network_member_group__parent_already_exists(self):
        network_name = "network_name"
        sobject_type = "sobject_type"
        parent_name = "parent_name"
        parent_id = "parent_id"

        self.assertTrue(parent_id)

        task = create_task(CreateNetworkMemberGroups, {"network_name": network_name})

        task._parent_ids = set()
        task._parent_ids.add(parent_id)
        self.assertTrue(parent_id in task._parent_ids)

        task._network_id = "network_id"

        task.logger = Mock()
        task.logger.info = Mock()
        task.logger.warn = Mock()

        task.sf = Mock()
        task.sf.NetworkMemberGroup = Mock()

        insert_response = Mock()
        insert_response.get = Mock()
        task.sf.NetworkMemberGroup.create = Mock(insert_response)

        # Execute the test.
        task._create_network_member_group(sobject_type, parent_name, parent_id)

        # Assert scenario execute as expected.
        task.logger.info.assert_not_called()

        task.logger.warn.assert_called_once_with(
            f'        Already exists for "{parent_name}"'
        )

        task.sf.NetworkMemberGroup.create.assert_not_called()

    def test_create_network_member_group__creating_parent_with_success(self):
        network_name = "network_name"
        sobject_type = "sobject_type"
        parent_name = "parent_name"
        parent_id = "parent_id"

        self.assertTrue(parent_id)

        task = create_task(CreateNetworkMemberGroups, {"network_name": network_name})

        task._parent_ids = set()
        self.assertFalse(parent_id in task._parent_ids)

        task._network_id = "network_id"

        task.logger = Mock()
        task.logger.info = Mock()
        task.logger.warn = Mock()

        task.sf = Mock()
        task.sf.NetworkMemberGroup = Mock()

        insert_response = {"success": True}
        self.assertTrue(insert_response.get("success") is True)

        task.sf.NetworkMemberGroup.create = Mock(return_value=insert_response)

        # Execute the test.
        task._create_network_member_group(sobject_type, parent_name, parent_id)

        # Assert scenario execute as expected.
        task.logger.info.assert_called_once_with(f'        "{parent_name}"')

        task.logger.warn.assert_not_called()

        task.sf.NetworkMemberGroup.create.assert_called_once_with(
            {"NetworkId": task._network_id, "ParentId": parent_id}
        )

    def test_create_network_member_group__creating_parent_not_success__with_errors(
        self,
    ):
        network_name = "network_name"
        sobject_type = "sobject_type"
        parent_name = "parent_name"
        parent_id = "parent_id"

        self.assertTrue(parent_id)

        task = create_task(CreateNetworkMemberGroups, {"network_name": network_name})

        task._parent_ids = set()
        self.assertFalse(parent_id in task._parent_ids)

        task._network_id = "network_id"

        task.logger = Mock()
        task.logger.info = Mock()
        task.logger.warn = Mock()

        task.sf = Mock()
        task.sf.NetworkMemberGroup = Mock()

        errors = ["error_0", "error_1"]
        insert_response = {"success": False, "errors": errors}
        self.assertFalse(insert_response.get("success") is True)

        task.sf.NetworkMemberGroup.create = Mock(return_value=insert_response)

        # Execute the test.
        with self.assertRaises(SalesforceException) as context:
            task._create_network_member_group(sobject_type, parent_name, parent_id)

        # Assert scenario execute as expected.
        self.assertEquals(
            f'Error creating NetworkMemberGroup for Network "{task._network_id}" for parent {sobject_type} "{parent_name}" {parent_id}.   Errors: {", ".join(errors)}',
            context.exception.args[0],
        )

        task.logger.info.assert_not_called()

        task.logger.warn.assert_not_called()

        task.sf.NetworkMemberGroup.create.assert_called_once_with(
            {"NetworkId": task._network_id, "ParentId": parent_id}
        )

    def test_create_network_member_group__creating_parent_not_success__no_errors(
        self,
    ):
        network_name = "network_name"
        sobject_type = "sobject_type"
        parent_name = "parent_name"
        parent_id = "parent_id"

        self.assertTrue(parent_id)

        task = create_task(CreateNetworkMemberGroups, {"network_name": network_name})

        task._parent_ids = set()
        self.assertFalse(parent_id in task._parent_ids)

        task._network_id = "network_id"

        task.logger = Mock()
        task.logger.info = Mock()
        task.logger.warn = Mock()

        task.sf = Mock()
        task.sf.NetworkMemberGroup = Mock()

        insert_response = {"success": False, "errors": None}
        self.assertFalse(insert_response.get("success") is True)

        task.sf.NetworkMemberGroup.create = Mock(return_value=insert_response)

        # Execute the test.
        with self.assertRaises(SalesforceException) as context:
            task._create_network_member_group(sobject_type, parent_name, parent_id)

        # Assert scenario execute as expected.
        self.assertEquals(
            f'Error creating NetworkMemberGroup for Network "{task._network_id}" for parent {sobject_type} "{parent_name}" {parent_id}.   Errors: {", ".join([])}',
            context.exception.args[0],
        )

        task.logger.info.assert_not_called()

        task.logger.warn.assert_not_called()

        task.sf.NetworkMemberGroup.create.assert_called_once_with(
            {"NetworkId": task._network_id, "ParentId": parent_id}
        )

    def test_run_task__none_profile_names_and_permission_set_names(
        self,
    ):
        network_name = "network_name"

        task = create_task(CreateNetworkMemberGroups, {"network_name": network_name})

        self.assertTrue(task.options.get("profile_names") is None)
        self.assertTrue(task.options.get("permission_set_names") is None)

        task._get_network_id = Mock(return_value="network_id")

        task._get_network_member_group_parent_ids = Mock(return_value=set(["Id_1"]))

        task._process_parent = Mock()
        expected_process_parent_calls = [
            call("Profile", []),
            call("PermissionSet", []),
        ]

        # Execute the test.
        task._run_task()

        # Assert scenario execute as expected.
        task._get_network_id.assert_called_once_with(task.options.get("network_name"))

        task._get_network_member_group_parent_ids.assert_called_once_with(
            task._get_network_id.return_value
        )

        task._process_parent.assert_has_calls(expected_process_parent_calls)

    def test_run_task__string_profile_names_and_permission_set_names(
        self,
    ):
        network_name = "network_name"
        profile_names = "profile_name"
        permission_set_names = "permission_set_name"

        task = create_task(
            CreateNetworkMemberGroups,
            {
                "network_name": network_name,
                "profile_names": profile_names,
                "permission_set_names": permission_set_names,
            },
        )

        self.assertEqual(profile_names, task.options.get("profile_names"))
        self.assertEqual(permission_set_names, task.options.get("permission_set_names"))

        task._get_network_id = Mock(return_value="network_id")

        task._get_network_member_group_parent_ids = Mock(return_value=set(["Id_1"]))

        task._process_parent = Mock()
        expected_process_parent_calls = [
            call("Profile", [profile_names]),
            call("PermissionSet", [permission_set_names]),
        ]

        # Execute the test.
        task._run_task()

        # Assert scenario execute as expected.
        task._get_network_id.assert_called_once_with(task.options.get("network_name"))

        task._get_network_member_group_parent_ids.assert_called_once_with(
            task._get_network_id.return_value
        )

        task._process_parent.assert_has_calls(expected_process_parent_calls)

    def test_run_task__list_profile_names_and_permission_set_names(
        self,
    ):
        network_name = "network_name"
        profile_names = [
            "profile_name_0",
            "profile_name_1",
            "profile_name_2",
        ]
        permission_set_names = [
            "permission_set_name_0",
            "permission_set_name_1",
            "permission_set_name_2",
            "permission_set_name_3",
        ]

        task = create_task(
            CreateNetworkMemberGroups,
            {
                "network_name": network_name,
                "profile_names": profile_names,
                "permission_set_names": permission_set_names,
            },
        )

        self.assertEqual(profile_names, task.options.get("profile_names"))
        self.assertEqual(permission_set_names, task.options.get("permission_set_names"))

        task._get_network_id = Mock(return_value="network_id")

        task._get_network_member_group_parent_ids = Mock(return_value=set(["Id_1"]))

        task._process_parent = Mock()
        expected_process_parent_calls = [
            call("Profile", profile_names),
            call("PermissionSet", permission_set_names),
        ]

        # Execute the test.
        task._run_task()

        # Assert scenario execute as expected.
        task._get_network_id.assert_called_once_with(task.options.get("network_name"))

        task._get_network_member_group_parent_ids.assert_called_once_with(
            task._get_network_id.return_value
        )

        task._process_parent.assert_has_calls(expected_process_parent_calls)
