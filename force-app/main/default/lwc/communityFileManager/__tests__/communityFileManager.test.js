import { createElement } from "lwc";
import CommunityFileManager from "c/communityFileManager";
import getRecordFiles from "@salesforce/apex/FileController.getRecordFiles";
import deleteContentDocument from "@salesforce/apex/FileController.deleteContentDocument";
import { refreshApex } from "@salesforce/apex";
import {
    registerApexTestWireAdapter,
    registerLdsTestWireAdapter,
} from "@salesforce/sfdx-lwc-jest";
import { getRecord } from "lightning/uiRecordApi";
import { showToast } from "c/util";

const MOCK_GET_RECORD_FILES = require("./data/getRecordFiles.json");
const MOCK_GET_RECORD_FILES_UNOWNED = require("./data/getUnownedFiles.json");
const getRecordFilesAdapter = registerApexTestWireAdapter(getRecordFiles);
const MOCK_DELETE_CONTENT_DOCUMENT_SUCCESS = '[{ "success": true }]';

const MOCK_DELETE_ERROR = {
    body: { message: "An internal server error has occurred" },
    ok: false,
    status: 400,
    statusText: "Bad Request",
};

const MOCK_GET_RECORD_SHOW_UPLOAD_FILES = require("./data/getShowFilesRequirement.json");
const MOCK_GET_RECORD_HIDE_UPLOAD_FILES = require("./data/getHideFilesRequirement.json");

const getRecordWireAdapter = registerLdsTestWireAdapter(getRecord); // eslint-disable-line

jest.mock(
    "@salesforce/community/basePath",
    () => {
        return { default: "/fakecommunity/s" };
    },
    { virtual: true }
);

jest.mock(
    "@salesforce/user/Id",
    () => {
        return { default: "0053B000003wIzfQAE" };
    },
    { virtual: true }
);

jest.mock(
    "@salesforce/apex/FileController.deleteContentDocument",
    () => {
        return {
            default: jest.fn(),
        };
    },
    { virtual: true }
);

jest.mock("c/util", () => {
    return {
        showToast: jest.fn(),
    };
});

jest.mock(
    "@salesforce/apex",
    () => {
        return {
            refreshApex: jest.fn(),
        };
    },
    { virtual: true }
);

describe("c-community-file-manager", () => {
    let fileManager;

    beforeEach(() => {
        delete window.location;
        window.location = {
            href: "",
        };
        fileManager = createElement("c-community-file-manager", {
            is: CommunityFileManager,
        });
        document.body.appendChild(fileManager);
    });

    afterEach(() => {
        jest.clearAllMocks();
        document.body.removeChild(fileManager);
        fileManager = null;
    });

    it("should mock assignments to location.href", () => {
        const target = "https://example.com/";
        window.location.href = target;
        expect(window.location.href).toBe(target);
    });

    it("should be accessible", async () => {
        await expect(fileManager).toBeAccessible();
    });

    it("should render list of files", async () => {
        getRecordWireAdapter.emit(MOCK_GET_RECORD_SHOW_UPLOAD_FILES);
        getRecordFilesAdapter.emit(MOCK_GET_RECORD_FILES);

        return Promise.resolve().then(() => {
            expect(fileManager).toBeAccessible();
            const fileBoxes = fileManager.shadowRoot.querySelectorAll(".slds-box");
            const recordCount = JSON.parse(JSON.stringify(MOCK_GET_RECORD_FILES)).length;
            expect(fileBoxes.length).toBe(recordCount);
        });
    });

    it("should show toast on file list error", async () => {
        getRecordFilesAdapter.error();

        return Promise.resolve()
            .then(() => {
                const fileBoxes = fileManager.shadowRoot.querySelectorAll(".slds-box");
                expect(fileBoxes.length).toBe(0);
            })
            .then(() => {
                expect(showToast).toHaveBeenCalled();
            });
    });

    it("should allow users to download files", async () => {
        getRecordWireAdapter.emit(MOCK_GET_RECORD_SHOW_UPLOAD_FILES);
        getRecordFilesAdapter.emit(MOCK_GET_RECORD_FILES);

        return Promise.resolve()
            .then(() => {
                const fileBox = fileManager.shadowRoot.querySelector(".slds-box a");
                fileBox.click();
            })
            .then(() => {
                expect(global.window.location.href).toEqual(
                    expect.stringContaining("sfc/servlet.shepherd/document/download")
                );
            });
    });

    it("should refresh list after user uploads files", async () => {
        getRecordWireAdapter.emit(MOCK_GET_RECORD_SHOW_UPLOAD_FILES);
        const handler = jest.fn();
        fileManager.addEventListener("uploadfinished", handler);

        return Promise.resolve()
            .then(() => {
                const uploadComponent = fileManager.shadowRoot.querySelector(
                    "lightning-file-upload"
                );
                uploadComponent.dispatchEvent(new CustomEvent("uploadfinished"));
            })
            .then(() => {
                expect(refreshApex).toHaveBeenCalled();
            });
    });

    it("should allow users to delete files", async () => {
        getRecordWireAdapter.emit(MOCK_GET_RECORD_SHOW_UPLOAD_FILES);
        getRecordFilesAdapter.emit(MOCK_GET_RECORD_FILES);
        deleteContentDocument.mockResolvedValue(MOCK_DELETE_CONTENT_DOCUMENT_SUCCESS);

        return Promise.resolve()
            .then(() => {
                const deleteAnchor = fileManager.shadowRoot.querySelector(
                    "a[data-id='deleteAnchor']"
                );
                expect(deleteAnchor).not.toBe(null);
                deleteAnchor.click();
            })
            .then(() => {
                const modalButton = fileManager.shadowRoot.querySelector(
                    "c-modal lightning-button[data-id='confirmDelete']"
                );
                expect(modalButton).not.toBe(null);
                modalButton.click();
            })
            .then(() => {
                expect(deleteContentDocument).toHaveBeenCalled();
            });
    });

    it("should allow the user to cancel without deletion", async () => {
        getRecordWireAdapter.emit(MOCK_GET_RECORD_SHOW_UPLOAD_FILES);
        getRecordFilesAdapter.emit(MOCK_GET_RECORD_FILES);

        return Promise.resolve()
            .then(() => {
                const deleteAnchor = fileManager.shadowRoot.querySelector(
                    "a[data-id='deleteAnchor']"
                );
                expect(deleteAnchor).not.toBe(null);
                deleteAnchor.click();
            })
            .then(() => {
                const modalButton = fileManager.shadowRoot.querySelector(
                    "c-modal lightning-button[data-id='cancel']"
                );
                expect(modalButton).not.toBe(null);
                modalButton.click();
            })
            .then(() => {
                expect(deleteContentDocument).not.toHaveBeenCalled();
            });
    });

    it("should should not allow user to delete files owned by another user", async () => {
        getRecordWireAdapter.emit(MOCK_GET_RECORD_SHOW_UPLOAD_FILES);
        getRecordFilesAdapter.emit(MOCK_GET_RECORD_FILES_UNOWNED);

        return Promise.resolve().then(() => {
            const deleteAnchor = fileManager.shadowRoot.querySelector(
                "a[data-id='deleteAnchor']"
            );
            expect(deleteAnchor).toBe(null);
        });
    });

    it("should throw toast on file deletion exceptions", async () => {
        getRecordWireAdapter.emit(MOCK_GET_RECORD_SHOW_UPLOAD_FILES);
        getRecordFilesAdapter.emit(MOCK_GET_RECORD_FILES);
        deleteContentDocument.mockRejectedValue(MOCK_DELETE_ERROR);

        return Promise.resolve()
            .then(() => {
                const deleteAnchor = fileManager.shadowRoot.querySelector(
                    "a[data-id='deleteAnchor']"
                );
                expect(deleteAnchor).not.toBe(null);
                deleteAnchor.click();
            })
            .then(() => {
                const modalButton = fileManager.shadowRoot.querySelector(
                    "c-modal lightning-button[data-id='confirmDelete']"
                );
                expect(modalButton).not.toBe(null);
                modalButton.click();
            })
            .then(() => {
                expect(deleteContentDocument).toHaveBeenCalled();
            })
            .then(() => {
                expect(showToast).toHaveBeenCalled();
            });
    });

    it("should throw toast if empty delete results are returned", async () => {
        getRecordWireAdapter.emit(MOCK_GET_RECORD_SHOW_UPLOAD_FILES);
        getRecordFilesAdapter.emit(MOCK_GET_RECORD_FILES);
        deleteContentDocument.mockResolvedValue(null);

        return Promise.resolve()
            .then(() => {
                const deleteAnchor = fileManager.shadowRoot.querySelector(
                    "a[data-id='deleteAnchor']"
                );
                expect(deleteAnchor).not.toBe(null);
                deleteAnchor.click();
            })
            .then(() => {
                const modalButton = fileManager.shadowRoot.querySelector(
                    "c-modal lightning-button[data-id='confirmDelete']"
                );
                expect(modalButton).not.toBe(null);
                modalButton.click();
            })
            .then(() => {
                expect(deleteContentDocument).toHaveBeenCalled();
            })
            .then(() => {
                expect(showToast).toHaveBeenCalled();
            });
    });

    it("should hide the upload section", async () => {
        getRecordWireAdapter.emit(MOCK_GET_RECORD_HIDE_UPLOAD_FILES);
        getRecordFilesAdapter.emit(MOCK_GET_RECORD_FILES);

        return Promise.resolve().then(() => {
            const uploadComponent = fileManager.shadowRoot.querySelector(
                "lightning-file-upload"
            );
            expect(uploadComponent).toBe(null);
        });
    });

    it("should render list of files without delete button", async () => {
        getRecordWireAdapter.emit(MOCK_GET_RECORD_HIDE_UPLOAD_FILES);
        getRecordFilesAdapter.emit(MOCK_GET_RECORD_FILES);

        return Promise.resolve().then(() => {
            const fileBoxes = fileManager.shadowRoot.querySelectorAll(".slds-box");
            expect(fileBoxes.length).toBe(3);

            const deleteAnchor = fileManager.shadowRoot.querySelector(
                "a[data-id='deleteAnchor']"
            );
            expect(deleteAnchor).toBe(null);
        });
    });
});
