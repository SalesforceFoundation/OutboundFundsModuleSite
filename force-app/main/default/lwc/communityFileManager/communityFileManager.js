/*
 * Copyright (c) 2021, salesforce.com, inc.
 * All rights reserved.
 * SPDX-License-Identifier: BSD-3-Clause
 * For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/BSD-3-Clause
 */
import { LightningElement, api, wire, track } from "lwc";
import { getRecord, getFieldValue } from "lightning/uiRecordApi";
import getRecordFiles from "@salesforce/apex/FileController.getRecordFiles";
import deleteContentDocument from "@salesforce/apex/FileController.deleteContentDocument";
import { refreshApex } from "@salesforce/apex";
import { showToast } from "c/util";
import RUNNING_USER_ID from "@salesforce/user/Id";
import COMMUNITY_BASE_URL from "@salesforce/community/basePath";
import customProgressBar from "@salesforce/resourceUrl/customProgressBar";
import { loadStyle } from "lightning/platformResourceLoader";
import FILEUPLOAD_VISIBILITY_FIELD from "@salesforce/schema/outfunds__Requirement__c.IsAddFilesVisible__c";

// LABELS
import deleteFileErrorTitle from "@salesforce/label/c.Delete_File_Error_Header";
import deleteFileErrorMessage from "@salesforce/label/c.Delete_File_Error_Message";
import requirementAttachments from "@salesforce/label/c.Requirement_Attachments";
import removeFileAction from "@salesforce/label/c.Delete_File_Action";
import error from "@salesforce/label/c.Error";
import fileRetrieveError from "@salesforce/label/c.File_Retrieval_Error";
import fileDeleteConfirmationBody from "@salesforce/label/c.Delete_File_Confirmation_Body";
import loadingText from "@salesforce/label/c.Loading";
import cancelButton from "@salesforce/label/c.Cancel";
import deleteFileConfirmationAction from "@salesforce/label/c.Delete_File_Confirmation_Action";
import noFilesAttached from "@salesforce/label/c.No_Files_Attached";

export default class CommunityFileManager extends LightningElement {
    @api recordId;
    files = [];
    deleteFileId;
    @track showDeleteSpinner = false;

    labels = {
        deleteFileErrorTitle: deleteFileErrorTitle,
        deleteFileErrorMessage: deleteFileErrorMessage,
        requirementAttachmentsHeader: requirementAttachments,
        removeFileAction: removeFileAction,
        errorHeader: error,
        fileRetrieveErrorMessage: fileRetrieveError,
        fileDeleteConfirmationBody: fileDeleteConfirmationBody,
        loadingText: loadingText,
        cancelButton: cancelButton,
        deleteFileConfirmationAction: deleteFileConfirmationAction,
        noFilesAttached: noFilesAttached,
    };
    connectedCallback() {
        loadStyle(this, customProgressBar);
    }

    /* Wired Apex so we can refresh on upload / delete */
    wiredFilesResult;

    @wire(getRecordFiles, { recordId: "$recordId" })
    wiredFiles(result) {
        this.wiredFilesResult = result;
        if (result.data) {
            this.files = JSON.parse(JSON.stringify(result.data));
            this.files.forEach((element) => {
                element.canDelete = element.OwnerId === RUNNING_USER_ID;
                element.fullName = element.Title + "." + element.FileExtension;
            });
        } else if (result.error) {
            showToast(
                this,
                this.labels.errorHeader,
                this.labels.fileRetrieveErrorMessage,
                "error"
            );
            this.files = [];
        }
    }

    @wire(getRecord, {
        recordId: "$recordId",
        fields: FILEUPLOAD_VISIBILITY_FIELD,
    })
    requirement;

    get showUpload() {
        if (this.requirement && this.requirement.data) {
            return getFieldValue(this.requirement.data, FILEUPLOAD_VISIBILITY_FIELD);
        }
        return false;
    }

    get displayFilesList() {
        return this.files && this.files.length > 0;
    }

    handleUploadFinished() {
        refreshApex(this.wiredFilesResult);
    }

    handleFileClick(e) {
        e.preventDefault();
        let fileId = e.target.dataset.fileId;
        let baseFileURL = COMMUNITY_BASE_URL.toString().split("/s")[0];
        let fileDownloadUrl =
            baseFileURL +
            "/sfc/servlet.shepherd/document/download/" +
            fileId +
            "?operationContext=S1";
        window.location.href = fileDownloadUrl;
    }

    handleDeleteClick(e) {
        e.preventDefault();
        this.deleteFileId = e.target.dataset.fileId;
        let modal = this.template.querySelector("c-modal");
        modal.toggleModal();
    }

    handleConfirmDelete() {
        let modal = this.template.querySelector("c-modal");
        this.showDeleteSpinner = true;
        const contentDocumentObject = this.files.find(
            (file) => file.Id === this.deleteFileId
        );

        deleteContentDocument({
            cd: { Id: this.deleteFileId, OwnerId: contentDocumentObject.OwnerId },
        })
            .then((result) => {
                let deleteResults = JSON.parse(result);

                // Only expecting one response per click
                if (!deleteResults || !deleteResults[0].success) {
                    showToast(
                        this,
                        this.labels.deleteFileErrorTitle,
                        this.labels.deleteFileErrorMessage,
                        "error"
                    );
                    return;
                }
                refreshApex(this.wiredFilesResult);
                this.showDeleteSpinner = false;
                modal.toggleModal();
            })
            .catch(() => {
                showToast(
                    this,
                    this.labels.deleteFileErrorTitle,
                    this.labels.deleteFileErrorMessage,
                    "error"
                );
                this.showDeleteSpinner = false;
                modal.toggleModal();
            });
    }

    handleCancelDelete() {
        this.deleteFileId = null;
        let modal = this.template.querySelector("c-modal");
        modal.toggleModal();
    }
}
