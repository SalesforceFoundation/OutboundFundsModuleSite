# * Copyright (c) 2021, salesforce.com, inc.
# * All rights reserved.
# * SPDX-License-Identifier: BSD-3-Clause
# * For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/BSD-3-Clause
# *

python3 -m venv venv
venv/bin/pip install -r requirements.txt
cat requirements.txt | npx hasha > .python_hash