import util from "c/util";
import { debug } from "c/util";
import { ShowToastEvent } from "lightning/platformShowToastEvent";

const mockFieldApiNameGetter = jest.fn();

jest.mock(
    "@salesforce/schema/outfunds__Requirement__c.ofm_Is_Add_Files_Visible__c",
    () => {
        return {
            default: {
                get fieldApiName() {
                    return mockFieldApiNameGetter();
                },
            },
        };
    },
    { virtual: true }
);

describe("isNull", () => {
    it("should only return true if value is null or undefined", () => {
        // Falsy values that isNull should return true.
        expect(util.isNull(undefined)).toBe(true);
        expect(util.isNull(null)).toBe(true);

        // Falsy values that isNull should return false.
        expect(util.isNull(false)).toBe(false);
        expect(util.isNull(+0)).toBe(false);
        expect(util.isNull(-0)).toBe(false);
        expect(util.isNull(NaN)).toBe(false);
        expect(util.isNull("")).toBe(false);
        expect(util.isNull(0n)).toBe(false);

        // Is truthy and isNull should return false.
        expect(util.isNull(true)).toBe(false);
        expect(util.isNull(" ")).toBe(false);
        expect(util.isNull("false")).toBe(false);
        expect(util.isNull("null")).toBe(false);
        expect(util.isNull({})).toBe(false);
        expect(util.isNull([])).toBe(false);
        expect(util.isNull(() => {})).toBe(false);
    });
});

describe("formatLabel", () => {
    describe("with an object for replacement", () => {
        it("should inject values for keys referenced in the label", () => {
            let label = "Hello, {firstName} {lastName}!  Welcome to the {communityName}!";
            let replacements = {
                firstName: "Aileen",
                lastName: "Davis",
                notReferenced: "not referenced",
            };
            expect(util.formatLabel(label, replacements)).toBe(
                "Hello, Aileen Davis!  Welcome to the {communityName}!"
            );
        });

        it("should inject values for keys referenced in the label if keys and label references case-insensitively match ", () => {
            let label = "Hello, {firstname} {lastname}!  Welcome to the {communityName}!";
            let replacements = {
                firstName: "Aileen",
                lastName: "Davis",
                notReferenced: "not referenced",
            };
            expect(util.formatLabel(label, replacements)).toBe(
                "Hello, Aileen Davis!  Welcome to the {communityName}!"
            );
        });

        it("should replace all instances referenced in the label", () => {
            let label =
                "Hello, {firstName} {lastName}!  {firstName}{firstName}{firstName}";
            let replacements = {
                firstName: "Aileen",
                lastName: "Davis",
                notReferenced: "not referenced",
            };
            expect(util.formatLabel(label, replacements)).toBe(
                "Hello, Aileen Davis!  AileenAileenAileen"
            );
        });

        it("should inject nothing if given an empty object", () => {
            let label = "Hello, {firstName} {lastName}!  Welcome to the {communityName}!";
            let replacements = {};
            expect(util.formatLabel(label, replacements)).toBe(
                "Hello, {firstName} {lastName}!  Welcome to the {communityName}!"
            );
        });

        it("should return an empty string if label isNull", () => {
            let replacements = {
                firstName: "Aileen",
                lastName: "Davis",
                notReferenced: "not referenced",
            };

            let label = null;
            expect(util.isNull(label)).toBe(true);
            expect(util.formatLabel(label, replacements)).toBe("");

            label = undefined;
            expect(util.isNull(label)).toBe(true);
            expect(util.formatLabel(label, replacements)).toBe("");
        });

        it("should not read prototype values from replacements", () => {
            let Replacements = function () {};
            Replacements.prototype.lastName = function () {
                return "Davis";
            };

            let label = "Hello, {firstName} {lastName}!  Welcome to the {communityName}!";

            let replacements = new Replacements();
            replacements.firstName = "Aileen";
            replacements.notReferenced = "not referenced";

            expect(util.formatLabel(label, replacements)).toBe(
                "Hello, Aileen {lastName}!  Welcome to the {communityName}!"
            );
        });
    });

    describe("with an array for replacement", () => {
        it("should inject values by index", () => {
            let label = "Hello, {0} {1}!  Welcome to the {communityName}!";
            let replacements = ["Aileen", "Davis", "Funding Program Community"];
            expect(util.formatLabel(label, replacements)).toBe(
                "Hello, Aileen Davis!  Welcome to the {communityName}!"
            );
        });

        it("should replace all instances referenced in the label", () => {
            let label = "Hello, {0} {1}!  {0}{0}{0}";
            let replacements = ["Aileen", "Davis", "Funding Program Community"];
            expect(util.formatLabel(label, replacements)).toBe(
                "Hello, Aileen Davis!  AileenAileenAileen"
            );
        });

        it("should inject nothing if given an empty array", () => {
            let label = "Hello, {0} {1}!  Welcome to the {communityName}!";
            let replacements = [];
            expect(util.formatLabel(label, replacements)).toBe(
                "Hello, {0} {1}!  Welcome to the {communityName}!"
            );
        });

        it("should return an empty string if label isNull", () => {
            let replacements = ["Aileen", "Davis"];

            let label = null;
            expect(util.isNull(label)).toBe(true);
            expect(util.formatLabel(label, replacements)).toBe("");

            label = undefined;
            expect(util.isNull(label)).toBe(true);
            expect(util.formatLabel(label, replacements)).toBe("");
        });
    });

    describe("with a string for replacement", () => {
        it("should inject values by index of string", () => {
            let label = "Hello, {0} {1}!  Welcome to the {communityName}!";
            let replacements = "abcd";
            expect(util.formatLabel(label, replacements)).toBe(
                "Hello, a b!  Welcome to the {communityName}!"
            );
        });

        it("should replace all instances referenced in the label", () => {
            let label = "Hello, {0} {1}!  {0}{0}{0}";
            let replacements = "abcd";
            expect(util.formatLabel(label, replacements)).toBe("Hello, a b!  aaa");
        });

        it("should inject nothing if given an empty string", () => {
            let label = "Hello, {0} {1}!  Welcome to the {communityName}!";
            let replacements = "";
            expect(util.formatLabel(label, replacements)).toBe(
                "Hello, {0} {1}!  Welcome to the {communityName}!"
            );
        });

        it("should return an empty string if label isNull", () => {
            let replacements = "≈";

            let label = null;
            expect(util.isNull(label)).toBe(true);
            expect(util.formatLabel(label, replacements)).toBe("");

            label = undefined;
            expect(util.isNull(label)).toBe(true);
            expect(util.formatLabel(label, replacements)).toBe("");
        });
    });
});

describe("showToast", () => {
    it("ShowToastEvent should have sticky mode if variant is error", () => {
        // Set arguments.
        const title = "title";
        const message = "message";
        const variant = "error";
        const lightningElement = jest.fn();

        // Mock dispatchEvent
        lightningElement.dispatchEvent = jest.fn();

        util.showToast(lightningElement, title, message, variant);

        expect(lightningElement.dispatchEvent).toHaveBeenCalledTimes(1);
        expect(lightningElement.dispatchEvent).toHaveBeenCalledWith(
            new ShowToastEvent({
                title: title,
                message: message,
                variant: variant,
                mode: "sticky",
            })
        );
    });

    it("ShowToastEvent should have pester mode if variant is info", () => {
        // Set constant arguments for the test.
        const title = "title";
        const message = "message";
        const variant = "info";
        const lightningElement = jest.fn();
        lightningElement.dispatchEvent = jest.fn();

        util.showToast(lightningElement, title, message, variant);

        expect(lightningElement.dispatchEvent).toHaveBeenCalledTimes(1);
        expect(lightningElement.dispatchEvent).toHaveBeenCalledWith(
            new ShowToastEvent({
                title: title,
                message: message,
                variant: variant,
                mode: "pester",
            })
        );
    });

    it("ShowToastEvent should have pester mode if variant is success", () => {
        // Set constant arguments for the test.
        const title = "title";
        const message = "message";
        const variant = "success";
        const lightningElement = jest.fn();
        lightningElement.dispatchEvent = jest.fn();

        util.showToast(lightningElement, title, message, variant);

        expect(lightningElement.dispatchEvent).toHaveBeenCalledTimes(1);
        expect(lightningElement.dispatchEvent).toHaveBeenCalledWith(
            new ShowToastEvent({
                title: title,
                message: message,
                variant: variant,
                mode: "pester",
            })
        );
    });

    it("ShowToastEvent should have pester mode if variant is warning", () => {
        // Set constant arguments for the test.
        const title = "title";
        const message = "message";
        const variant = "warning";
        const lightningElement = jest.fn();
        lightningElement.dispatchEvent = jest.fn();

        util.showToast(lightningElement, title, message, variant);

        expect(lightningElement.dispatchEvent).toHaveBeenCalledTimes(1);
        expect(lightningElement.dispatchEvent).toHaveBeenCalledWith(
            new ShowToastEvent({
                title: title,
                message: message,
                variant: variant,
                mode: "pester",
            })
        );
    });
});

describe("debug", () => {
    const data = {
        class: "util.test.js",
        numbers: [1, 2, 3],
        objects: [
            {
                recordId: "a",
            },
            {
                recordId: "b",
            },
            {
                recordId: "c",
            },
        ],
    };
    const expectedLog = JSON.stringify(data, null, 2);

    let consoleSpies = {};

    beforeEach(() => {
        consoleSpies = {
            log: jest.spyOn(console, "log").mockImplementation(),
            warn: jest.spyOn(console, "warn").mockImplementation(),
            error: jest.spyOn(console, "error").mockImplementation(),
        };
    });

    afterEach(() => {
        for (const mockImplementation of Object.values(consoleSpies)) {
            mockImplementation.mockRestore();
        }
    });

    it("should default to console.log", () => {
        debug(data);
        expect(console.log).toHaveBeenCalledTimes(1);
        expect(console.log).toHaveBeenLastCalledWith(expectedLog);
    });

    it("should override logger with warn", () => {
        debug(data, "warn");
        expect(console.warn).toHaveBeenCalledTimes(1);
        expect(console.warn).toHaveBeenLastCalledWith(expectedLog);
    });

    it("should override logger with error", () => {
        debug(data, "error");
        expect(console.error).toHaveBeenCalledTimes(1);
        expect(console.error).toHaveBeenLastCalledWith(expectedLog);
    });
});

describe("prefixNamespace", () => {
    describe("namespace is present", () => {
        it("should return the string with the namespace prefix", () => {
            mockFieldApiNameGetter.mockReturnValue("namespace__ofm_Is_Add_Files_Visible__c");
            let result = util.prefixNamespace("outfunds__Requirement__r");
            expect(result).toBe("namespace__outfunds__Requirement__r");
        });
    });

    describe("namespace is not present", () => {
        it("should return the string without the namespace prefix", () => {
            mockFieldApiNameGetter.mockReturnValue("ofm_Is_Add_Files_Visible__c");
            let result = util.prefixNamespace("outfunds__Requirement__r");
            expect(result).toBe("outfunds__Requirement__r");
        });
    });
});
