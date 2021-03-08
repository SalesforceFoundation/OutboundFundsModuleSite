import { createElement } from "lwc";
import { getNavigateCalledWith } from "lightning/navigation";
import FlowSobjectNavigation from "c/flowNavigateToRecord";

describe("c-flow-navigate-to-records", () => {
    let component;

    afterEach(global.clearDOM);
    beforeEach(() => {
        component = createElement("c-flow-navigate-to-records", {
            is: FlowSobjectNavigation,
        });
    });

    it("should call navigation mixin when connected", async () => {
        component.recordId = "recordId";
        document.body.appendChild(component);

        return global.flushPromises().then(async () => {
            const { pageReference } = getNavigateCalledWith();
            expect(pageReference.type).toBe("standard__recordPage");
            expect(pageReference.attributes.recordId).toBe(component.recordId);
            expect(pageReference.attributes.actionName).toBe("view");
        });
    });
});
