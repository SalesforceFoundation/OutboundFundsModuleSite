@IsTest
public with sharing class FileService_TEST {
    /** Static stubs and setup properties **/
    private static BasicStub fileSelectorStub = new BasicStub(FileSelector.class);
    final static String METHOD_CONTENT_DOCUMENT_LINK_BY_RECORD_IDS = 'contentDocumentLinkByRecordIds';
    final static String METHOD_CONTENT_DOCUMENT_BY_IDS = 'contentDocumentsByIds';
    final static string COMMUNITY_USER_EMAIL = 'communitytestuser@salesforce.org';

    /** Test Runs **/
    @IsTest
    private static void testGetContentDocumentByRecordId() {
        Id programId = TestUtils.mockId(outfunds__Funding_Program__c.SObjectType);
        Id contentDocumentLinkId = TestUtils.mockId(ContentDocumentLink.SObjectType);
        Id contentDocumentId = TestUtils.mockId(ContentDocument.SObjectType);

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

        fileSelectorStub.withReturnValue(
            METHOD_CONTENT_DOCUMENT_LINK_BY_RECORD_IDS,
            Set<Id>.class,
            contentDocumentLinkExpected
        );

        fileSelectorStub.withReturnValue(
            METHOD_CONTENT_DOCUMENT_BY_IDS,
            Set<Id>.class,
            contentDocumentExpected
        );

        Test.startTest();

        FileService.fileSelector = (FileSelector) fileSelectorStub.createMock();
        FileService service = new FileService();

        List<ContentDocument> contentDocumentActual = service.getContentDocumentByRecordId(
            programId
        );

        Test.stopTest();

        System.assertEquals(
            contentDocumentExpected,
            contentDocumentActual,
            'Expected the FileService to return the list from the FileSelector'
        );

        fileSelectorStub.assertCalledWith(
            METHOD_CONTENT_DOCUMENT_LINK_BY_RECORD_IDS,
            Set<Id>.class,
            new Set<Id>{ programId }
        );

        fileSelectorStub.assertCalledWith(
            METHOD_CONTENT_DOCUMENT_BY_IDS,
            Set<Id>.class,
            new Set<Id>{ contentDocumentId }
        );
    }

    @IsTest
    private static void testGetContentDocumentByRecordIdNoFiles() {
        Id programId = TestUtils.mockId(outfunds__Funding_Program__c.SObjectType);
        List<ContentDocumentLink> contentDocumentLinkExpected = new List<ContentDocumentLink>();
        List<ContentDocument> contentDocumentExpected = new List<ContentDocument>();

        fileSelectorStub.withReturnValue(
            METHOD_CONTENT_DOCUMENT_LINK_BY_RECORD_IDS,
            Set<Id>.class,
            contentDocumentLinkExpected
        );

        fileSelectorStub.withReturnValue(
            METHOD_CONTENT_DOCUMENT_BY_IDS,
            Set<Id>.class,
            contentDocumentExpected
        );

        Test.startTest();

        FileService.fileSelector = (FileSelector) fileSelectorStub.createMock();
        FileService service = new FileService();

        List<ContentDocument> contentDocumentActual = service.getContentDocumentByRecordId(
            programId
        );

        Test.stopTest();

        System.assertEquals(
            contentDocumentExpected,
            contentDocumentActual,
            'Expected the FileService to return an empty list from the FileSelector'
        );

        fileSelectorStub.assertCalledWith(
            METHOD_CONTENT_DOCUMENT_LINK_BY_RECORD_IDS,
            Set<Id>.class,
            new Set<Id>{ programId }
        );

        fileSelectorStub.assertNotCalled(METHOD_CONTENT_DOCUMENT_BY_IDS);
    }

    @IsTest
    private static void deleteContentDocumentsByIdShouldCallDeleteRecords() {
        FileService fileServiceInstance = new FileService();

        final Id contentDocumentId = TestUtils.mockId(Schema.SObjectType.ContentDocument);
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
        databaseServiceMock.getMethod('deleteRecordsById').returnValue = results;

        Test.startTest();
        FileService.databaseService = (DatabaseService) databaseServiceMock.createStub(
            DatabaseService.class
        );

        final List<Database.DeleteResult> actual = fileServiceInstance.deleteContentDocumentsById(
            new List<Id>{ contentDocumentId }
        );
        Test.stopTest();

        System.assert(actual[0].success);
        databaseServiceMock.getMethod('deleteRecordsById').assertCalled();
    }

    @IsTest
    private static void deleteContentDocumentsByIdShouldConfirmPermissions() {
        FileService fileServiceInstance = new FileService();

        final Id contentDocumentId = TestUtils.mockId(Schema.SObjectType.User);
        final List<Database.DeleteResult> results = new List<Database.DeleteResult>();

        final UnitTest.Mock databaseServiceMock = new UnitTest.Mock();
        databaseServiceMock.getMethod('deleteRecordsById').returnValue = results;

        User noPermUser = TestUtils.createUser(
            'Minimum Access - Salesforce',
            COMMUNITY_USER_EMAIL
        );

        final List<Database.DeleteResult> actual;
        Test.startTest();
        System.runAs(noPermUser) {
            FileService.databaseService = (DatabaseService) databaseServiceMock.createStub(
                DatabaseService.class
            );

            actual = fileServiceInstance.deleteContentDocumentsById(
                new List<Id>{ contentDocumentId }
            );
        }
        Test.stopTest();

        System.assert(actual.isEmpty());
        databaseServiceMock.getMethod('deleteRecordsById').assertCalled();
    }

    @IsTest
    private static void deleteContentDocumentsByIdShouldDeleteFiles() {
        FileService fileServiceInstance = new FileService();
        Integer contentDocumentCount = 5;

        List<ContentDocument> contentDocuments = TestUtils.createContentDocuments(
            contentDocumentCount
        );

        System.assertEquals(contentDocumentCount, [SELECT COUNT() FROM ContentDocument]);

        Test.startTest();
        fileServiceInstance.deleteContentDocumentsById(
            new List<Id>{ contentDocuments[0].Id }
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

        List<ContentDocument> contentDocuments = TestUtils.createContentDocuments(
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

        final Id accountId = TestUtils.mockId(Schema.Account.getSObjectType());
        final Id contentDocumentId = TestUtils.mockId(
            Schema.ContentDocument.getSObjectType()
        );
        final Id contentDocumentLinkId = TestUtils.mockId(
            Schema.ContentDocumentLink.getSObjectType()
        );

        List<Id> contentDocumentIds = new List<Id>{ contentDocumentId };
        List<DatabaseService.SaveResult> expectedSaveResults = new List<DatabaseService.SaveResult>{
            new DatabaseService.SaveResult(null, contentDocumentLinkId, true)
        };

        // Create all Mocks and set return values/exceptions.
        final UnitTest.Mock databaseServiceMock = new UnitTest.Mock();
        final UnitTest.Mock insertRecordsMock = databaseServiceMock.getMethod(
            'insertRecords'
        );
        insertRecordsMock.returnValue = expectedSaveResults;

        List<DatabaseService.SaveResult> actualResults;
        Test.startTest();

        // Set mocks.
        FileService.databaseService = (DatabaseService) databaseServiceMock.createStub(
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

        List<ContentDocumentLink> contentLinks = TestUtils.createContentDocumentsWithLink(
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

        final Id accountId = TestUtils.mockId(Schema.Account.getSObjectType());
        final Id contentDocumentId = TestUtils.mockId(
            Schema.ContentDocument.getSObjectType()
        );
        final Id contentDocumentLinkId = TestUtils.mockId(
            Schema.ContentDocumentLink.getSObjectType()
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
            'deleteRecordsById'
        );
        deleteRecordsByIdMock.returnValue = deleteResults;

        List<Database.DeleteResult> actualResults;
        Test.startTest();

        // Set mocks.
        FileService.databaseService = (DatabaseService) databaseServiceMock.createStub(
            DatabaseService.class
        );
        FileService.fileSelector = (FileSelector) fileSelectorMock.createStub(
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

    /**
     * Asserts that the custom exception created for ContentDocument Deletion security checks can be thrown by the service
     */
    @IsTest
    private static void doesNotHaveDeleteAccessForObjectExceptionShouldBeThrowable() {
        Exception actualException;
        try {
            throw new FileService.DoesNotHaveDeleteAccessForObjectException();
        } catch (FileService.DoesNotHaveDeleteAccessForObjectException e) {
            actualException = e;
        } catch (Exception e) {
            System.assert(
                false,
                String.format(
                    'Expected to catch an exception of type {0}',
                    new List<String>{
                        FileService.DoesNotHaveDeleteAccessForObjectException.class
                            .getName()
                    }
                )
            );
        }
        System.assertEquals(
            actualException.getTypeName(),
            FileService.DoesNotHaveDeleteAccessForObjectException.class.getName()
        );
        System.assertEquals(
            System.Label.Does_Not_Have_Delete_Access_For_Object_Message,
            actualException.getMessage(),
            'Expected exception message to match the expected label'
        );
    }
}
