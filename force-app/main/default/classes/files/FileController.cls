public with sharing class FileController {
    @TestVisible
    private static FileService fileService = new FileService();

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
            return JSON.serialize(fileService.deleteContentDocumentsById(new List<ContentDocument>{cd}));
        } catch (Exception e) {
            throw new AuraHandledException(System.Label.Delete_File_Error_Message);
        }
    }
}
