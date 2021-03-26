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
