import { api, LightningElement } from "lwc";
import CLOSE_LABEL from "@salesforce/label/c.Close";

const ESC_KEY_CODE = 27;
const ESC_KEY_STRING = "Escape";
const TAB_KEY_CODE = 9;
const TAB_KEY_STRING = "Tab";
const CSS_CLASS = "modal-hidden";

export default class OfmModal extends LightningElement {
    showModal = false;

    labels = {
        close: CLOSE_LABEL,
    };

    @api isLarge;

    get modalContainerCss() {
        let classes = ["slds-modal__container"];
        if (this.isLarge) {
            classes.push("modal__large");
        }
        return classes.join(" ");
    }

    @api
    set header(value) {
        this.hasHeaderAttribute = value !== "";
        this._header = value;
    }
    get header() {
        return this._header;
    }

    @api
    toggleModal() {
        this.showModal = !this.showModal;
        if (this.showModal) {
            this.focusFirstChild();
        }
    }

    /**
     * Shows the modal and moves the focus to inside the modal.
     */
    @api show() {
        this.showModal = true;
        this.focusFirstChild();
    }

    @api hide() {
        const closedialog = new CustomEvent("closedialog");
        this.dispatchEvent(closedialog);
        this.showModal = false;
    }

    @api
    get cssClass() {
        const baseClasses = ["slds-modal"];
        baseClasses.push([
            this.showModal ? "slds-visible slds-fade-in-open" : "slds-hidden",
        ]);
        return baseClasses.join(" ");
    }

    @api
    get modalAriaHidden() {
        return !this.showModal;
    }

    renderedCallback() {
        if (!this.template.activeElement) {
            this.focusFirstChild();
        }
    }

    closeModal(event) {
        event.stopPropagation();
        const closedialog = new CustomEvent("closedialog");
        this.dispatchEvent(closedialog);
        this.toggleModal();
    }

    innerClickHandler(event) {
        event.stopPropagation();
    }

    innerKeyUpHandler(event) {
        if (event.keyCode === ESC_KEY_CODE || event.code === ESC_KEY_STRING) {
            this.toggleModal();
        } else if (event.keyCode === TAB_KEY_CODE || event.code === TAB_KEY_STRING) {
            const el = this.template.activeElement;
            let focusableElement;
            if (el && el.classList.contains("end-of-form")) {
                focusableElement = this._getCloseButton();
            }
            if (focusableElement) {
                focusableElement.focus();
            }
        }
    }

    _getCloseButton() {
        let closeButton = this.template.querySelector(".slds-modal__close");
        if (!closeButton) {
            // In the absence of a the headers close icon, make the cancel button the first button.
            closeButton = this.template.querySelector("button");
        }
        return closeButton;
    }

    _getSlotName(element) {
        let slotName = element.slot;
        while (!slotName && element.parentElement) {
            slotName = this._getSlotName(element.parentElement);
        }
        return slotName;
    }

    async focusFirstChild() {
        const children = [...this.querySelectorAll("*")];
        for (let child of children) {
            let hasBeenFocused = false;
            if (this._getSlotName(child) === "body") {
                continue;
            }
            // eslint-disable-next-line no-await-in-loop
            this.setFocus(child).then((res) => {
                hasBeenFocused = res;
            });
            if (hasBeenFocused) {
                return;
            }
        }
        //if there is no focusable markup from slots
        //focus the first button
        const closeButton = this._getCloseButton();
        if (closeButton) {
            closeButton.focus();
        }
    }

    setFocus(el) {
        return new Promise((resolve) => {
            const promiseListener = () => resolve(true);
            try {
                el.addEventListener("focus", promiseListener);
                el.focus();
                el.removeEventListener("focus", promiseListener);
                // eslint-disable-next-line @lwc/lwc/no-async-operation
                setTimeout(() => resolve(false), 0);
            } catch (ex) {
                resolve(false);
            }
        });
    }

    handleSlotFooterChange() {
        const footerEl = this.template.querySelector("footer");
        if (footerEl) {
            footerEl.classList.remove(CSS_CLASS);
        }
    }
}
