@isTest
public with sharing class FileController_TEST {
    private static String USER_EMAIL = 'alternatUser@example.com';

    private static TestUser.BusinessFundseekerPersona alternateFundSeekerPersona = new TestUser.BusinessFundseekerPersona();

    @TestSetup
    private static void createTestData() {
        TestUser.insertPersonasInTestSetup(
            new List<TestUser.Persona>{ FileController_TEST.alternateFundSeekerPersona }
        );
    }

    @IsTest
    private static void getRecordFilesShouldRetrieveFiles() {
        Id programId = UnitTest.mockId(Schema.SObjectType.outfunds__Funding_Program__c);
        final List<ContentDocument> expected = new List<ContentDocument>{
            new ContentDocument(Id = UnitTest.mockId(Schema.SObjectType.ContentDocument))
        };

        final UnitTest.Mock fileServiceMock = new UnitTest.Mock();
        fileServiceMock.getMethod('getContentDocumentByRecordId').returnValue = expected;

        Test.startTest();

        FileController.fileService = (FileService) fileServiceMock.createStub(
            FileService.class
        );

        final List<ContentDocument> actual = FileController.getRecordFiles(programId);

        Test.stopTest();

        System.assertEquals(
            expected,
            actual,
            'Expected the controller to return the list from the FileService'
        );

        fileServiceMock.getMethod('getContentDocumentByRecordId').assertCalled();
    }

    @IsTest
    private static void getRecordFilesShouldThrowException() {
        Id programId = UnitTest.mockId(Schema.SObjectType.outfunds__Funding_Program__c);
        final UnitTest.Mock fileServiceMock = new UnitTest.Mock();
        fileServiceMock.getMethod('getContentDocumentByRecordId')
            .returnValue = new AuraHandledException(System.Label.File_Retrieval_Error);

        Test.startTest();

        FileController.fileService = (FileService) fileServiceMock.createStub(
            FileService.class
        );

        final List<ContentDocument> actual;
        String actualExceptionMessage;

        try {
            actual = FileController.getRecordFiles(programId);
        } catch (AuraHandledException e) {
            actualExceptionMessage = e.getMessage();
        } catch (Exception e) {
            System.assert(false, 'Expected AuraHandledException to be thrown');
        }

        System.assertNotEquals(
            null,
            actualExceptionMessage,
            'Exception message should not be null.'
        );

        fileServiceMock.getMethod('getContentDocumentByRecordId').assertCalled();
    }

    @isTest
    private static void deleteContentDocumentShouldCallDeleteFiles() {
        ContentDocument file = FileSelector_TEST.createContentDocuments(1)[0];
        file = [SELECT Id, OwnerId FROM ContentDocument];

        final List<Database.DeleteResult> results = new List<Database.DeleteResult>();
        results.add(
            (Database.DeleteResult) JSON.deserialize(
                '{"success": true, "id": "' +
                file.Id +
                '"}',
                Database.DeleteResult.class
            )
        );

        final UnitTest.Mock fileServiceMock = new UnitTest.Mock();
        fileServiceMock.getMethod('deleteContentDocumentsById').returnValue = results;

        Test.startTest();
        FileController.fileService = (FileService) fileServiceMock.createStub(
            FileService.class
        );

        final String actual = FileController.deleteContentDocument(file);
        Test.stopTest();

        System.assertEquals(JSON.serialize(results), actual);
        fileServiceMock.getMethod('deleteContentDocumentsById').assertCalled();
    }

    @IsTest
    private static void deleteContentDocumentShouldThrowExceptionOnMismatchedOwner() {
        Exception actualException;
        Id runningUserId = UserInfo.getUserId();
        FileController_TEST.alternateFundSeekerPersona.load();

        ContentDocument file = FileSelector_TEST.createContentDocuments(1)[0];

        System.runAs(FileController_TEST.alternateFundSeekerPersona.getUser()) {
            file.OwnerId = runningUserId;
            update file;

            Test.startTest();
            try {
                FileController.deleteContentDocument(file);
            } catch (AuraHandledException e) {
                actualException = e;
            } catch (Exception e) {
                System.assert(false, 'Expected an Aura Handled Exception to be thrown');
            }
            Test.stopTest();
        }
        System.assertNotEquals(null, actualException);
    }

    @IsTest
    private static void deleteContentDocumentShouldThrowExceptionOnUnexpectedException() {
        Exception actualException;
        ContentDocument file = FileSelector_TEST.createContentDocuments(1)[0];
        file.OwnerId = UserInfo.getUserId();

        final UnitTest.Mock fileServiceMock = new UnitTest.Mock();
        fileServiceMock.getMethod('deleteContentDocumentsById')
            .returnValue = new AuraHandledException(
            System.Label.Delete_File_Error_Message
        );

        Test.startTest();

        FileController.fileService = (FileService) fileServiceMock.createStub(
            FileService.class
        );

        try {
            FileController.deleteContentDocument(file);
        } catch (AuraHandledException e) {
            actualException = e;
        } catch (Exception e) {
            System.assert(false, 'Expected an Aura Handled Exception to be thrown');
        }
        Test.stopTest();

        System.assertNotEquals(null, actualException);
    }
}
