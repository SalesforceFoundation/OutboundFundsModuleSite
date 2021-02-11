from unittest import mock, TestCase
from cumulusci.tasks.salesforce.tests.util import create_task

from dev.tasks.metadata_etl import UpdateMetadataFirstChildTextTask
from cumulusci.utils.xml.metadata_tree import MetadataElement


class TestUpdateMetadataFirstChildTextTask(TestCase):
    def test_init_options(self):
        for options, expected_value in [
            (
                {
                    "managed": False,
                    "namespace_inject": None,
                    "entity": "CustomObject",
                    "tag": "customObjectAttribute",
                    "value": "newAttributeValue",
                },
                "newAttributeValue",
            ),
            (
                {
                    "managed": True,
                    "namespace_inject": None,
                    "entity": "CustomObject",
                    "tag": "customObjectAttribute",
                    "value": "newAttributeValue",
                },
                "newAttributeValue",
            ),
            (
                {
                    "managed": False,
                    "namespace_inject": "namespace",
                    "entity": "CustomObject",
                    "tag": "customObjectAttribute",
                    "value": "newAttributeValue",
                },
                "newAttributeValue",
            ),
            (
                {
                    "managed": True,
                    "namespace_inject": "namespace",
                    "entity": "CustomObject",
                    "tag": "customObjectAttribute",
                    "value": "newAttributeValue",
                },
                "newAttributeValue",
            ),
            (
                {
                    "managed": False,
                    "namespace_inject": None,
                    "entity": "CustomObject",
                    "tag": "customObjectAttribute",
                    "value": "%%%NAMESPACE%%%newAttributeValue",
                },
                "newAttributeValue",
            ),
            (
                {
                    "managed": True,
                    "namespace_inject": None,
                    "entity": "CustomObject",
                    "tag": "customObjectAttribute",
                    "value": "%%%NAMESPACE%%%newAttributeValue",
                },
                "newAttributeValue",
            ),
            (
                {
                    "managed": False,
                    "namespace_inject": "namespace",
                    "entity": "CustomObject",
                    "tag": "customObjectAttribute",
                    "value": "%%%NAMESPACE%%%newAttributeValue",
                },
                "newAttributeValue",
            ),
            (
                {
                    "managed": True,
                    "namespace_inject": "namespace",
                    "entity": "CustomObject",
                    "tag": "customObjectAttribute",
                    "value": "%%%NAMESPACE%%%newAttributeValue",
                },
                "namespace__newAttributeValue",
            ),
        ]:
            task = create_task(UpdateMetadataFirstChildTextTask, options)

            self.assertEqual(options["entity"], task.entity)
            self.assertEqual(expected_value, task.options["value"])

    def test_transform_entity__attribute_found(self):
        api_name = "Supercalifragilisticexpialidocious__c"

        metadata = mock.Mock(spec=MetadataElement)
        metadata.find.return_value = mock.Mock(spec=MetadataElement)
        metadata.append.return_value = mock.Mock(spec=MetadataElement)

        self.assertTrue(metadata.find.return_value)

        entity = "CustomObject"
        tag = "customObjectAttribute"
        value = "newAttributeValue"

        task = create_task(
            UpdateMetadataFirstChildTextTask,
            {
                "managed": False,
                "namespace_inject": None,
                "entity": entity,
                "tag": tag,
                "value": value,
            },
        )
        task.logger = mock.Mock()
        self.assertEqual(tag, task.options.get("tag"))
        self.assertEqual(value, task.options.get("value"))

        actual = task._transform_entity(metadata, api_name)

        self.assertEqual(metadata, actual)

        metadata.find.assert_called_once_with(tag)
        metadata.append.assert_not_called()
        self.assertEqual(metadata.find.return_value.text, value)

        task.logger.info.assert_has_calls(
            [
                mock.call(f'Updating {entity} "{api_name}":'),
                mock.call(f'    {tag} as "{value}"'),
            ]
        )

    def test_transform_entity__attribute_not_found(self):
        api_name = "Supercalifragilisticexpialidocious__c"

        metadata = mock.Mock(spec=MetadataElement)
        metadata.find.return_value = None
        metadata.append.return_value = mock.Mock(spec=MetadataElement)

        self.assertFalse(metadata.find.return_value)

        entity = "CustomObject"
        tag = "customObjectAttribute"
        value = "newAttributeValue"

        task = create_task(
            UpdateMetadataFirstChildTextTask,
            {
                "managed": False,
                "namespace_inject": None,
                "entity": entity,
                "tag": tag,
                "value": value,
            },
        )
        task.logger = mock.Mock()
        self.assertEqual(tag, task.options.get("tag"))
        self.assertEqual(value, task.options.get("value"))

        actual = task._transform_entity(metadata, api_name)

        self.assertEqual(metadata, actual)

        metadata.find.assert_called_once_with(tag)
        metadata.append.assert_called_once_with(tag)
        self.assertEqual(metadata.append.return_value.text, value)

        task.logger.info.assert_has_calls(
            [
                mock.call(f'Updating {entity} "{api_name}":'),
                mock.call(f'    {tag} as "{value}"'),
            ]
        )
