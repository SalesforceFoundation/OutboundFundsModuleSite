/*
 * Copyright (c) 2021, salesforce.com, inc.
 * All rights reserved.
 * SPDX-License-Identifier: BSD-3-Clause
 * For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/BSD-3-Clause
 */
import { LightningElement, api } from "lwc";
import { NavigationMixin } from "lightning/navigation";

export default class FlowNavigateToRecord extends NavigationMixin(LightningElement) {
    @api recordId;

    connectedCallback() {
        this[NavigationMixin.Navigate]({
            type: "standard__recordPage",
            attributes: {
                recordId: this.recordId,
                actionName: "view",
            },
        });
    }
}
