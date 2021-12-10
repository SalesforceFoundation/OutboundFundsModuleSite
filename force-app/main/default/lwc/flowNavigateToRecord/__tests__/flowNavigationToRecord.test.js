/*
 * Copyright (c) 2021, salesforce.com, inc.
 * All rights reserved.
 * SPDX-License-Identifier: BSD-3-Clause
 * For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/BSD-3-Clause
 */
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

        return Promise.resolve().then(async () => {
            const { pageReference } = getNavigateCalledWith();
            expect(pageReference.type).toBe("standard__recordPage");
            expect(pageReference.attributes.recordId).toBe(component.recordId);
            expect(pageReference.attributes.actionName).toBe("view");
        });
    });
});
