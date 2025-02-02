/*
 * Copyright (c) 2021, salesforce.com, inc.
 * All rights reserved.
 * SPDX-License-Identifier: BSD-3-Clause
 * For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/BSD-3-Clause
 */
public with sharing class FileService {
    @TestVisible
    private FileSelector fileSelector = new FileSelector();

    @TestVisible
    private DatabaseService databaseService = new DatabaseService();

    /**
     * @description Returns a list of ContentDocument(s) related to a record
     * @param recordId  Id of the record for which we will query associated ContentDocument(s)
     */
    public List<ContentDocument> getContentDocumentsByRecordId(Id recordId) {
        Set<Id> contentDocumentLinkIds = new Set<Id>();
        List<ContentDocument> contentDocuments = new List<ContentDocument>();

        List<ContentDocumentLink> contentDocumentLinks = fileSelector.getContentDocumentLinksByRecordIds(
            new Set<Id>{ recordId }
        );

        if (contentDocumentLinks.isEmpty()) {
            return contentDocuments;
        }

        for (ContentDocumentLink cdl : contentDocumentLinks) {
            contentDocumentLinkIds.add(cdl.ContentDocumentId);
        }
        contentDocuments = fileSelector.getContentDocumentsByIds(contentDocumentLinkIds);

        return contentDocuments;
    }

    /**
     * @description Creates the association (ContentDocumentLink) between a record and a list of ContentDocument(s)
     * @param recordId  Id of the record to which we will associate the ContentDocument(s)
     * @param contentDocumentIds    List of ContentDocument Id(s) to associate with the specified record
     */
    public List<Database.SaveResult> createContentDocumentLinks(
        Id recordId,
        List<Id> contentDocumentIds
    ) {
        List<ContentDocumentLink> contentDocumentLinks = new List<ContentDocumentLink>();
        for (Id contentDocumentId : contentDocumentIds) {
            contentDocumentLinks.add(
                new ContentDocumentLink(
                    LinkedEntityId = recordId,
                    ContentDocumentId = contentDocumentId
                )
            );
        }

        // Service confirms CRUD/FLS permissions
        return databaseService.insertRecordsEnforceFls(contentDocumentLinks);
    }

    /**
     * @description Remove the association (ContentDocumentLink) between a record and a list of ContentDocument(s)
     * @param recordId  Id of the record to which we will disassociate the ContentDocument(s)
     * @param contentDocumentIds    List of ContentDocument Id(s) to disassociate with the specified record
     */
    public List<Database.DeleteResult> unlinkContentDocumentsFromRecord(
        Id recordId,
        List<Id> contentDocumentIds
    ) {
        List<Database.DeleteResult> results = new List<Database.DeleteResult>();
        List<Id> contentDocumentLinkIdsToDelete = new List<Id>();
        List<ContentDocumentLink> contentDocumentLinksToDelete = new List<ContentDocumentLink>();

        for (
            ContentDocumentLink contentDocumentLink : fileSelector.getContentDocumentLinksByRecordIds(
                new Set<Id>{ recordId }
            )
        ) {
            if (contentDocumentIds.contains(contentDocumentLink.ContentDocumentId)) {
                contentDocumentLinksToDelete.add(contentDocumentLink);
            }
        }
        return databaseService.deleteRecords(contentDocumentLinksToDelete);
    }

    /**
     * @description Deletes a collection of ContentDocument(s)
     * @param contentDocumentIds    List of ContentDocument Id(s) to delete
     */
    public List<Database.DeleteResult> deleteContentDocuments(
        List<ContentDocument> contentDocuments
    ) {
        return databaseService.deleteRecords(contentDocuments);
    }
}
