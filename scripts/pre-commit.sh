# * Copyright (c) 2021, salesforce.com, inc.
# * All rights reserved.
# * SPDX-License-Identifier: BSD-3-Clause
# * For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/BSD-3-Clause
# *

. scripts/install-pre-commit.sh
if [ $? -ne 0 ]
then
  exit 1
fi

npx lint-staged
if [ $? -ne 0 ]
then
  exit 1
fi

venv/bin/python scripts/label_audit.py
if [ $? -ne 0 ]
then
  exit 1
fi
