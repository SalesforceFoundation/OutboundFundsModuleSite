/*
 * Copyright (c) 2021, salesforce.com, inc.
 * All rights reserved.
 * SPDX-License-Identifier: BSD-3-Clause
 * For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/BSD-3-Clause
 */

global.flushPromises = () => new Promise((resolve) => setImmediate(resolve));

global.clearDOM = () => {
    while (document.body.firstChild) {
        document.body.removeChild(document.body.firstChild);
    }
    jest.clearAllMocks();
};

// Load @sa11y/jest.
const { registerSa11yMatcher } = require("@sa11y/jest");
registerSa11yMatcher();
