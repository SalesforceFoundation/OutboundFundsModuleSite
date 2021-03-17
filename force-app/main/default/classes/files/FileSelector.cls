public with sharing class FileSelector {
    public List<ContentDocumentLink> contentDocumentLinkByRecordIds(Set<Id> recordIds) {
        return [
            SELECT Id, ContentDocumentId, LinkedEntityId
            FROM ContentDocumentLink
            WHERE LinkedEntityId IN :recordIds
            WITH SECURITY_ENFORCED
        ];
    }

    public List<ContentDocument> contentDocumentsByIds(Set<Id> contentDocumentIds) {
        return [
            SELECT Id, OwnerId, Description, FileExtension, FileType, Title
            FROM ContentDocument
            WHERE Id IN :contentDocumentIds
            WITH SECURITY_ENFORCED
        ];
    }
}
