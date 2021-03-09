public with sharing class OFMSite_FileController {
    @TestVisible
    private static OFMSite_FileService fileService = new OFMSite_FileService();

    @AuraEnabled(cacheable=true)
    public static List<ContentDocument> getRecordFiles(Id recordId) {
        try {
            return fileService.getContentDocumentByRecordId(recordId);
        } catch (Exception e) {
            throw new AuraHandledException(System.Label.File_Retrieval_Error);
        }
    }

    @AuraEnabled
    public static String deleteContentDocument(ContentDocument cd) {
        if (cd.OwnerId != UserInfo.getUserId()) {
            throw new AuraHandledException(System.Label.Delete_File_Error_Message);
        }

        try {
            return JSON.serialize(
                fileService.deleteContentDocumentsById(new List<Id>{ cd.Id })
            );
        } catch (Exception e) {
            throw new AuraHandledException(System.Label.Delete_File_Error_Message);
        }
    }
}
