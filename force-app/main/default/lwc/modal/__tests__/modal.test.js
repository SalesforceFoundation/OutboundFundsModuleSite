import { createElement } from "lwc";
import Modal from "c/modal";

describe("modal without a header attribute and without header slot", () => {
    let modal;
    let contentSlot;

    beforeEach(() => {
        modal = createElement("c-modal", {
            is: Modal,
        });

        document.body.appendChild(modal);

        contentSlot = document.createElement("button");
        contentSlot.setAttribute("slot", "content");
        contentSlot.appendChild(document.createTextNode("My Fancy Header"));

        modal.appendChild(contentSlot);
    });

    afterEach(() => {
        document.body.removeChild(modal);
        modal = null;
    });

    it("should be accessible", async () => {
        await expect(modal).toBeAccessible();

        modal.show();

        await expect(modal).toBeAccessible();
    });

    it("should trap keyboard focus", async () => {
        await modal.show();

        expect(document.activeElement === contentSlot).toBe(true);
    });
});

describe("modal without a header attribute and with header slot", () => {
    let modal;
    let headerSlot;

    beforeEach(() => {
        modal = createElement("c-modal", {
            is: Modal,
        });

        headerSlot = document.createElement("button");
        headerSlot.setAttribute("slot", "content");
        headerSlot.appendChild(document.createTextNode("My Fancy Header"));

        modal.appendChild(headerSlot);

        document.body.appendChild(modal);
    });

    afterEach(() => {
        document.body.removeChild(modal);
        modal = null;
    });

    it("should be accessible", async () => {
        // Initial state has modal hidden
        await expect(modal).toBeAccessible();

        modal.show();

        await expect(modal).toBeAccessible();
    });

    it("should trap keyboard focus", async () => {
        await modal.show();

        expect(document.activeElement === headerSlot).toBe(true);
    });
});

describe("modal with a header attribute and without header slot", () => {
    let modal;
    let header = "My Fancy Modal";
    let contentSlot;

    beforeEach(() => {
        modal = createElement("c-modal", {
            is: Modal,
        });
        // Add header attribute content.
        modal.header = header;

        contentSlot = document.createElement("button");
        contentSlot.setAttribute("slot", "content");
        contentSlot.appendChild(document.createTextNode("My Fancy Header"));

        modal.appendChild(contentSlot);

        document.body.appendChild(modal);
    });

    afterEach(() => {
        document.body.removeChild(modal);
        modal = null;
    });

    it("should be accessible", async () => {
        // Initial state has modal hidden
        await expect(modal).toBeAccessible();

        modal.show();

        await expect(modal).toBeAccessible();
    });

    it("should trap keyboard focus", () => {
        expect(document.activeElement === contentSlot).toBe(true);
    });
});

describe("modal with a header attribute and with header slot", () => {
    let modal;
    let header = "My Fancy Modal";
    let headerSlot;

    beforeEach(() => {
        modal = createElement("c-modal", {
            is: Modal,
        });

        // Add header attribute content.
        modal.header = header;

        // Add "header" slot content.
        headerSlot = document.createElement("button");
        headerSlot.setAttribute("slot", "content");
        headerSlot.appendChild(document.createTextNode("My Fancy Header"));

        modal.appendChild(headerSlot);

        document.body.appendChild(modal);
    });

    afterEach(() => {
        document.body.removeChild(modal);
        modal = null;
    });

    it("should be accessible", async () => {
        // Initial state has modal hidden
        await expect(modal).toBeAccessible();

        modal.show();

        await expect(modal).toBeAccessible();
    });

    it("should trap keyboard focus", async () => {
        await modal.show();

        expect(document.activeElement === headerSlot).toBe(true);
    });
});
