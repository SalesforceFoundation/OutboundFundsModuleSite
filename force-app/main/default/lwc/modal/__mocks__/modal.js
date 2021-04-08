/*
 * Copyright (c) 2021, salesforce.com, inc.
 * All rights reserved.
 * SPDX-License-Identifier: BSD-3-Clause
 * For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/BSD-3-Clause
 */
import { api, LightningElement } from "lwc";

export default class Modal extends LightningElement {
    @api isLarge;
    @api header;
    @api toggleModal = jest.fn();
    @api show = jest.fn();
    @api hide = jest.fn();
    @api cssClass = jest.fn();
    @api modalAriaHidden = jest.fn();
}
