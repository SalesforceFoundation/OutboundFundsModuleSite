# * Copyright (c) 2021, salesforce.com, inc.
# * All rights reserved.
# * SPDX-License-Identifier: BSD-3-Clause
# * For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/BSD-3-Clause
# *

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
