public with sharing class OFMSite_FileSelector {

    public List<ContentDocumentLink> contentDocumentLinkByRecordIds(Set<Id> recordIds) {
        List<ContentDocumentLink> contentDocumentLinks = new List<ContentDocumentLink>();

        if (ContentDocumentLink.sObjectType.getDescribe().isAccessible()) {
            contentDocumentLinks = [
                SELECT Id, ContentDocumentId, LinkedEntityId
                FROM ContentDocumentLink
                WHERE LinkedEntityId IN :recordIds
            ];
        }

        return Security.stripInaccessible(AccessType.READABLE, contentDocumentLinks)
            .getRecords();
    }

    public List<ContentDocument> contentDocumentsByIds(Set<Id> contentDocumentIds) {
        List<ContentDocument> contentDocuments = new List<ContentDocument>();

        if (ContentDocument.SObjectType.getDescribe().isAccessible()) {
            contentDocuments = [
                SELECT Id, OwnerId, Description, FileExtension, FileType, Title
                FROM ContentDocument
                WHERE Id IN :contentDocumentIds
            ];
        }

        return Security.stripInaccessible(AccessType.READABLE, contentDocuments)
            .getRecords();
    }
    
}
