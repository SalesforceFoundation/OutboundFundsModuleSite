@IsTest
public with sharing class FileService_TEST {
    /** Static stubs and setup properties **/
    private static TestUser.BusinessFundseekerPersona businessFundSeekerPersona = new TestUser.BusinessFundseekerPersona();

    @TestSetup
    private static void createTestData() {
        TestUser.insertPersonasInTestSetup(
            new List<TestUser.Persona>{ FileService_TEST.businessFundSeekerPersona }
        );
    }

    /** Test Runs **/
    @IsTest
    private static void testGetContentDocumentByRecordId() {
        Id programId = UnitTest.mockId(Schema.SObjectType.outfunds__Funding_Program__c);
        Id contentDocumentLinkId = UnitTest.mockId(
            Schema.SObjectType.ContentDocumentLink
        );
        Id contentDocumentId = UnitTest.mockId(Schema.SObjectType.ContentDocument);

        List<ContentDocumentLink> contentDocumentLinkExpected = new List<ContentDocumentLink>{
            new ContentDocumentLink(
                Id = contentDocumentLinkId,
                ContentDocumentId = contentDocumentId,
                LinkedEntityId = programId
            )
        };
        List<ContentDocument> contentDocumentExpected = new List<ContentDocument>{
            new ContentDocument(Id = contentDocumentId)
        };

        UnitTest.Mock fileSelectorMock = new UnitTest.Mock();
        UnitTest.Mock contentDocumentLinkByRecordIds = fileSelectorMock.getMethod(
            'contentDocumentLinkByRecordIds'
        );
        contentDocumentLinkByRecordIds.returnValue = contentDocumentLinkExpected;

        UnitTest.Mock contentDocumentByRecordIds = fileSelectorMock.getMethod(
            'contentDocumentsByIds'
        );
        contentDocumentByRecordIds.returnValue = contentDocumentExpected;

        Test.startTest();

        FileService service = new FileService();
        service.fileSelector = (FileSelector) fileSelectorMock.createStub(
            FileSelector.class
        );

        List<ContentDocument> contentDocumentActual = service.getContentDocumentByRecordId(
            programId
        );

        Test.stopTest();

        System.assertEquals(
            contentDocumentExpected,
            contentDocumentActual,
            'Expected the FileService to return the list from the FileSelector'
        );

        contentDocumentLinkByRecordIds.assertCalledOnceWith(
            new List<Object>{ new Set<Id>{ programId } }
        );

        contentDocumentByRecordIds.assertCalledOnceWith(
            new List<Object>{ new Set<Id>{ contentDocumentId } }
        );
    }

    @IsTest
    private static void testGetContentDocumentByRecordIdNoFiles() {
        Id programId = UnitTest.mockId(Schema.SObjectType.outfunds__Funding_Program__c);
        List<ContentDocumentLink> contentDocumentLinkExpected = new List<ContentDocumentLink>();
        List<ContentDocument> contentDocumentExpected = new List<ContentDocument>();

        UnitTest.Mock fileSelectorMock = new UnitTest.Mock();
        UnitTest.Mock contentDocumentLinkByRecordIds = fileSelectorMock.getMethod(
            'contentDocumentLinkByRecordIds'
        );
        contentDocumentLinkByRecordIds.returnValue = contentDocumentLinkExpected;

        UnitTest.Mock contentDocumentByRecordIds = fileSelectorMock.getMethod(
            'contentDocumentsByIds'
        );
        contentDocumentByRecordIds.returnValue = contentDocumentExpected;

        Test.startTest();

        FileService fileService = new FileService();
        fileService.fileSelector = (FileSelector) fileSelectorMock.createStub(
            FileSelector.class
        );

        List<ContentDocument> contentDocumentActual = fileService.getContentDocumentByRecordId(
            programId
        );

        Test.stopTest();

        System.assertEquals(
            contentDocumentExpected,
            contentDocumentActual,
            'Expected the FileService to return an empty list from the FileSelector'
        );

        contentDocumentLinkByRecordIds.assertCalledOnceWith(
            new List<Object>{ new Set<Id>{ programId } }
        );
        contentDocumentByRecordIds.assertNotCalled();
    }

    @IsTest
    private static void deleteContentDocumentsByIdShouldCallDeleteRecords() {
        Integer contentDocumentCount = 5;
        FileService fileServiceInstance = new FileService();
        List<ContentDocument> contentDocuments = FileSelector_TEST.createContentDocuments(
            contentDocumentCount
        );

        final Id contentDocumentId = contentDocuments[0].Id;

        // final Id contentDocumentId = UnitTest.mockId(Schema.SObjectType.ContentDocument);
        final List<Database.DeleteResult> results = new List<Database.DeleteResult>();
        results.add(
            (Database.DeleteResult) JSON.deserialize(
                '{"success": true, "id": "' +
                contentDocumentId +
                '"}',
                Database.DeleteResult.class
            )
        );

        final UnitTest.Mock databaseServiceMock = new UnitTest.Mock();
        databaseServiceMock.getMethod('deleteRecords').returnValue = results;

        Test.startTest();
        fileServiceInstance.databaseService = (DatabaseService) databaseServiceMock.createStub(
            DatabaseService.class
        );

        final List<Database.DeleteResult> actual = fileServiceInstance.deleteContentDocumentsById(
            new List<ContentDocument>{ contentDocuments[0] }
        );
        Test.stopTest();

        System.assert(actual[0].success);
        databaseServiceMock.getMethod('deleteRecords').assertCalled();
    }

    @IsTest
    private static void deleteContentDocumentsByIdShouldConfirmPermissions() {
        Integer contentDocumentCount = 5;
        FileService fileServiceInstance = new FileService();

        List<ContentDocument> contentDocuments = FileSelector_TEST.createContentDocuments(
            contentDocumentCount
        );

        //final Id contentDocumentId = UnitTest.mockId(Schema.SObjectType.User);
        final List<Database.DeleteResult> results = new List<Database.DeleteResult>();

        final UnitTest.Mock databaseServiceMock = new UnitTest.Mock();
        databaseServiceMock.getMethod('deleteRecords').returnValue = results;

        FileService_TEST.businessFundSeekerPersona.load();

        final List<Database.DeleteResult> actual;
        Test.startTest();
        System.runAs(FileService_TEST.businessFundSeekerPersona.getUser()) {
            fileServiceInstance.databaseService = (DatabaseService) databaseServiceMock.createStub(
                DatabaseService.class
            );

            actual = fileServiceInstance.deleteContentDocumentsById(
                new List<ContentDocument>{ contentDocuments[0] }
            );
        }
        Test.stopTest();

        System.assert(actual.isEmpty());
        databaseServiceMock.getMethod('deleteRecords').assertCalled();
    }

    @IsTest
    private static void deleteContentDocumentsByIdShouldDeleteFiles() {
        FileService fileServiceInstance = new FileService();
        Integer contentDocumentCount = 5;

        List<ContentDocument> contentDocuments = FileSelector_TEST.createContentDocuments(
            contentDocumentCount
        );

        System.assertEquals(contentDocumentCount, [SELECT COUNT() FROM ContentDocument]);

        Test.startTest();
        fileServiceInstance.deleteContentDocumentsById(
            new List<ContentDocument>{ contentDocuments[0] }
        );
        Test.stopTest();

        System.assertEquals(
            contentDocumentCount - 1,
            [SELECT COUNT() FROM ContentDocument]
        );
    }

    /**
     * Asserts that createContentDocumentLinks() inserts ContentDocumentLink(s)
     * Note: Integration test
     */
    @IsTest
    private static void createContentDocumentLinksShouldInsertContentDocumentLinks() {
        FileService fileServiceInstance = new FileService();
        Integer contentDocumentCount = 3;
        Account account = new Account(Name = 'Test Verification Check');
        insert account;

        List<ContentDocument> contentDocuments = FileSelector_TEST.createContentDocuments(
            contentDocumentCount
        );

        List<Id> contentDocumentIds = new List<Id>();
        for (ContentDocument cd : contentDocuments) {
            contentDocumentIds.add(cd.Id);
        }

        System.assertEquals(
            0,
            [SELECT COUNT() FROM ContentDocumentLink WHERE LinkedEntityId = :account.Id],
            'Expected no ContentDocumentLink records to exist prior to test execution.'
        );

        Test.startTest();
        fileServiceInstance.createContentDocumentLinks(account.Id, contentDocumentIds);
        Test.stopTest();

        System.assertEquals(
            contentDocumentCount,
            [SELECT COUNT() FROM ContentDocumentLink WHERE LinkedEntityId = :account.Id],
            String.format(
                'Expected {0} ContentDocumentLink record(s) to exist and be related to the record.',
                new List<String>{ String.valueOf(contentDocumentCount) }
            )
        );
    }

    /**
     * Asserts that createContentDocumentLinks() calls DatabaseService.insertRecords() using the expected parameters
     */
    @IsTest
    private static void createContentDocumentLinksShouldCallDatabaseService() {
        FileService fileServiceInstance = new FileService();

        final Id accountId = UnitTest.mockId(Schema.SObjectType.Account);
        final Id contentDocumentId = UnitTest.mockId(Schema.SObjectType.ContentDocument);
        final Id contentDocumentLinkId = UnitTest.mockId(
            Schema.SObjectType.ContentDocumentLink
        );

        List<Id> contentDocumentIds = new List<Id>{ contentDocumentId };
        List<Database.SaveResult> expectedSaveResults = new List<Database.SaveResult>();

        expectedSaveResults.add(
            (Database.SaveResult) JSON.deserialize(
                '{"success":true, "id":"' +
                contentDocumentLinkId +
                '"}',
                Database.SaveResult.class
            )
        );

        // Create all Mocks and set return values/exceptions.
        final UnitTest.Mock databaseServiceMock = new UnitTest.Mock();
        final UnitTest.Mock insertRecordsMock = databaseServiceMock.getMethod(
            'insertRecordsEnforceFls'
        );
        insertRecordsMock.returnValue = expectedSaveResults;

        List<Database.SaveResult> actualResults;
        Test.startTest();

        // Set mocks.
        fileServiceInstance.databaseService = (DatabaseService) databaseServiceMock.createStub(
            DatabaseService.class
        );

        actualResults = fileServiceInstance.createContentDocumentLinks(
            accountId,
            contentDocumentIds
        );

        Test.stopTest();

        insertRecordsMock.assertCalledOnce();
        System.assertEquals(
            expectedSaveResults,
            actualResults,
            String.format(
                'Expected {0} to return the Id of the ContentDocumentLink created for the file',
                new List<String>{ FileService.class.getName() }
            )
        );
    }

    /**
     * Asserts that unlinkContentDocumentsFromRecord() deletes the specified ContentDocumentLink(s) from the specified record
     * Note: Integration test
     */
    @IsTest
    private static void unlinkContentDocumentsFromRecordShouldDeleteContentDocumentLinks() {
        FileService fileServiceInstance = new FileService();
        Integer contentDocumentCount = 3;
        Account account = new Account(Name = 'Test Verification Check');
        insert account;

        List<ContentDocumentLink> contentLinks = FileSelector_TEST.createContentDocumentsWithLink(
            account.Id,
            'AllUsers',
            contentDocumentCount
        );

        List<Id> contentDocumentIds = new List<Id>();
        for (ContentDocumentLink contentLink : contentLinks) {
            contentDocumentIds.add(contentLink.ContentDocumentId);
        }

        System.assertEquals(
            contentDocumentCount,
            [SELECT COUNT() FROM ContentDocumentLink WHERE LinkedEntityId = :account.Id],
            String.format(
                'Expected ContentDocumentLink records prior to test execution.',
                new List<String>{ String.valueOf(contentDocumentCount) }
            )
        );

        Test.startTest();
        fileServiceInstance.unlinkContentDocumentsFromRecord(
            account.Id,
            contentDocumentIds
        );
        Test.stopTest();

        System.assertEquals(
            0,
            [SELECT COUNT() FROM ContentDocumentLink WHERE LinkedEntityId = :account.Id],
            'Expected no ContentDocumentLink records after test execution.'
        );
    }

    /**
     * Asserts that unlinkContentDocumentsFromRecord() calls DatabaseService.deleteRecordsById() with the specified parameters
     */
    @IsTest
    private static void unlinkContentDocumentsFromRecordShouldCallDatabaseService() {
        FileService fileServiceInstance = new FileService();

        final Id accountId = UnitTest.mockId(Schema.SObjectType.Account);
        final Id contentDocumentId = UnitTest.mockId(Schema.SObjectType.ContentDocument);
        final Id contentDocumentLinkId = UnitTest.mockId(
            Schema.SObjectType.ContentDocumentLink
        );
        final ContentDocumentLink expectedContentDocumentLink = new ContentDocumentLink(
            Id = contentDocumentLinkId
        );

        final List<Database.DeleteResult> deleteResults = new List<Database.DeleteResult>();
        deleteResults.add(
            (Database.DeleteResult) JSON.deserialize(
                '{"success": true, "id": "' +
                expectedContentDocumentLink.Id +
                '"}',
                Database.DeleteResult.class
            )
        );

        final UnitTest.Mock fileSelectorMock = new UnitTest.Mock();
        final UnitTest.Mock contentDocumentLinkByRecordIdsMock = fileSelectorMock.getMethod(
            'contentDocumentLinkByRecordIds'
        );
        contentDocumentLinkByRecordIdsMock.returnValue = new List<ContentDocumentLink>{
            expectedContentDocumentLink
        };

        // Create all Mocks and set return values/exceptions.
        final UnitTest.Mock databaseServiceMock = new UnitTest.Mock();
        final UnitTest.Mock deleteRecordsByIdMock = databaseServiceMock.getMethod(
            'deleteRecords'
        );
        deleteRecordsByIdMock.returnValue = deleteResults;

        List<Database.DeleteResult> actualResults;
        Test.startTest();

        // Set mocks.
        fileServiceInstance.databaseService = (DatabaseService) databaseServiceMock.createStub(
            DatabaseService.class
        );
        fileServiceInstance.fileSelector = (FileSelector) fileSelectorMock.createStub(
            FileSelector.class
        );

        actualResults = fileServiceInstance.unlinkContentDocumentsFromRecord(
            accountId,
            new List<Id>{ contentDocumentId }
        );

        Test.stopTest();

        contentDocumentLinkByRecordIdsMock.assertCalledOnceWith(
            new List<Object>{ new Set<Id>{ accountId } }
        );

        deleteRecordsByIdMock.assertCalledOnce();
        System.assertEquals(
            deleteResults,
            actualResults,
            String.format(
                'Expected {0} to return delete results matching the Id of the ContentDocumentLink for the file',
                new List<String>{ FileService.class.getName() }
            )
        );
    }
}
