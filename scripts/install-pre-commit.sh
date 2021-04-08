# * Copyright (c) 2021, salesforce.com, inc.
# * All rights reserved.
# * SPDX-License-Identifier: BSD-3-Clause
# * For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/BSD-3-Clause
# *

if [ ! -d node_modules ] || [ \"$(cat .node_hash)\" != \"$(cat yarn.lock | npx hasha)\" ]; 
then 
    . scripts/update-dependencies.sh 
fi
if [ ! -d venv ] || [ \"$(cat .python_hash)\" != \"$(cat requirements.txt | npx hasha)\" ]; 
then 
    . scripts/update-python-dependencies.sh
fi