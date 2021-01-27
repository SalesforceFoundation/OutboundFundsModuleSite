const { jestConfig } = require("@salesforce/sfdx-lwc-jest/config");
module.exports = {
    ...jestConfig,
    moduleNameMapper: {
        "^lightning/navigation$":
            "<rootDir>/force-app/main/default/lwc/__mocks__/lightning/navigation/navigation.js",
    },
    testPathIgnorePatterns: ["force-app/main/default/lwc/__(tests|mocks)__/"],
    reporters: ["default"],
    setupFilesAfterEnv: ["./jest.setup.js"],
};
