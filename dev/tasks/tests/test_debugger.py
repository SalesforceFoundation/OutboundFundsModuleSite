import pytest  # noqa: F401
from unittest import mock
from dev.tasks.debugger import log_title


class TestLogTitle:
    def test_log_title(self):
        logger = mock.Mock()

        log_title("This is a title", logger=logger)

        logger.assert_has_calls(
            [
                mock.call(""),
                mock.call("This is a title"),
                mock.call("───────────────"),
            ]
        )
