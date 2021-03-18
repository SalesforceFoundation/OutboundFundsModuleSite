const { jestConfig } = require("@salesforce/sfdx-lwc-jest/config");

const setupFilesAfterEnv = jestConfig.setupFilesAfterEnv || [];
setupFilesAfterEnv.push("<rootDir>/jest.setup.js");

/*
moduleNameMapper: {
        "^lightning/navigation$":
            "<rootDir>/force-app/main/default/lwc/__mocks__/lightning/navigation/navigation.js",
    },*/

module.exports = {
    ...jestConfig,
    testPathIgnorePatterns: ["<rootDir>/force-app/main/default/lwc/__(tests|mocks)__/"],
    reporters: ["default"],
    setupFilesAfterEnv: setupFilesAfterEnv,
};
