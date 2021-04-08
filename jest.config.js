/*
 * Copyright (c) 2021, salesforce.com, inc.
 * All rights reserved.
 * SPDX-License-Identifier: BSD-3-Clause
 * For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/BSD-3-Clause
 */

const { jestConfig } = require("@salesforce/sfdx-lwc-jest/config");

const setupFilesAfterEnv = jestConfig.setupFilesAfterEnv || [];
setupFilesAfterEnv.push("<rootDir>/jest.setup.js");

module.exports = {
    ...jestConfig,
    testPathIgnorePatterns: ["<rootDir>/force-app/main/default/lwc/__(tests|mocks)__/"],
    reporters: ["default"],
    setupFilesAfterEnv: setupFilesAfterEnv,
};
