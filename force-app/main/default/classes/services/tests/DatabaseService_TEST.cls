@IsTest
public with sharing class DatabaseService_TEST {
    public static final TestUser.MinimalAccessPersona minimalAccessPersona = new TestUser.MinimalAccessPersona();

    @TestSetup
    public static void testSetup() {
        TestUser.insertPersonasInTestSetup(
            new List<TestUser.Persona>{ minimalAccessPersona }
        );
    }

    /**
     * DatabaseService.Savepoint should be constructed with a null System.Savepoint
     * to ensure a System.Savepoint was not created if a DatabaseService.Savepoint
     * is stubbed.
     */
    @IsTest
    private static void savepointShouldBeConstructedWithANullSavepoint() {
        Test.startTest();

        final DatabaseService.Savepoint savepoint = new DatabaseService.Savepoint();

        Test.stopTest();

        System.assertEquals(
            null,
            savepoint.savepoint,
            'savepoint should be null after construction'
        );
    }

    /**
     * DatabaseService.Savepoint was specifically designed to:
     * - Wrap a non-stubbable System.Savepoint
     * - And itself be stubbable.
     */
    @IsTest
    private static void savepointShouldBeStubbable() {
        final UnitTest.Mock mock = new UnitTest.Mock();

        Test.startTest();

        try {
            DatabaseService.Savepoint savepoint = (DatabaseService.Savepoint) mock.createStub(
                DatabaseService.Savepoint.class
            );
        } catch (Exception e) {
            System.assertNotEquals(
                null,
                e,
                'Creating a stub of DatabaseService.Savepoint should not throw an Exception.'
            );
        }

        Test.stopTest();
    }

    /**
     * DatabaseService.setSavepoint should return a DatabaseService.Savepoint with
     * its System.Savepoint set.
     */
    @IsTest
    private static void setSavepointShouldReturnWithSavepointSet() {
        final DatabaseService databaseService = new DatabaseService();

        Test.startTest();

        final DatabaseService.Savepoint savepoint = databaseService.setSavepoint();

        Test.stopTest();

        System.assertNotEquals(
            null,
            savepoint.savepoint,
            'setSavepoint should return a DatabaseService.Savepoint whose System.Savepoint is set.'
        );
    }

    /**
     * Asserts DatabaseService.rollback actually rolls back the transaction to the System.Savepoint in the DatabaseService.Savepoint returned by DatabaseService.setSavepoint.
     */
    @IsTest
    private static void rollbackShouldRollback() {
        final Schema.outfunds__Funding_Program__c fundingProgram = TestUtils.createFundingProgram();

        Test.startTest();

        final DatabaseService databaseService = new DatabaseService();
        final DatabaseService.Savepoint savepoint = databaseService.setSavepoint();

        insert fundingProgram;

        System.assert(
            ![SELECT Id FROM outfunds__Funding_Program__c WHERE Id = :fundingProgram.Id]
                .isEmpty(),
            'fundingProgram should be found because it was inserted.'
        );

        databaseService.rollback(savepoint);

        Test.stopTest();

        System.assert(
            [SELECT Id FROM outfunds__Funding_Program__c WHERE Id = :fundingProgram.Id]
                .isEmpty(),
            'fundingProgram should not be found because the transaction was rolled back.'
        );
    }

    /**
     * Asserts DatabaseService.insertRecords creates new records without error
     */
    @IsTest
    private static void insertRecordsShouldCreateRecords() {
        DatabaseService service = new DatabaseService();
        String accountName = 'Insert Records Test Account';

        Account acc = new Account(Name = accountName);
        List<SObject> sobjectRecords = new List<SObject>{ acc };

        List<DatabaseService.SaveResult> saveResults;
        Test.startTest();
        saveResults = service.insertRecords(sobjectRecords);
        Test.stopTest();

        System.assert(
            saveResults[0].isSuccess(),
            'Insert operation should have returned DatabaseService.SaveResult and isSuccess() should be true'
        );

        System.assertNotEquals(
            null,
            saveResults[0].getId(),
            'A record Id should have been returned after insert'
        );

        Id accountId = saveResults[0].getId();
        Account insertedAccount = [
            SELECT Id, Name
            FROM Account
            WHERE Id = :accountId
            LIMIT 1
        ];
        System.assert(
            insertedAccount != null,
            'Insert operation should have created an account record.'
        );
        System.assertEquals(
            insertedAccount.Name,
            accountName,
            'Insert operation should have created an account record with the expected Name value.'
        );
    }

    /**
     * Asserts DatabaseService.insertRecords returns DatabaseService.SaveResult records and that isSuccess() returns false on error
     */
    @IsTest
    private static void insertRecordsShouldReturnDatabaseServiceErrorOnFailure() {
        DatabaseService service = new DatabaseService();
        Account acc = new Account();

        List<SObject> sobjectRecords = new List<SObject>{ acc };

        List<DatabaseService.SaveResult> saveResults;
        Test.startTest();
        saveResults = service.insertRecords(sobjectRecords, false);
        test.stopTest();

        System.assert(
            !saveResults[0].isSuccess(),
            'The record insert should not have been successful'
        );

        System.assert(
            !saveResults[0].getErrors().isEmpty(),
            'A list of errors should have been returned from the service'
        );

        for (DatabaseService.Error error : saveResults[0].getErrors()) {
            System.assert(
                !error.getFields().isEmpty(),
                'Error fields should have been returned'
            );
            System.assert(
                !String.isBlank(error.getMessage()),
                'An error message should have been returned'
            );
            System.assertNotEquals(
                null,
                error.getStatusCode(),
                'An error status code should have been returned'
            );
        }
    }

    @IsTest
    private static void insertRecordsWithAllOrNothingShouldThrowExceptionOnError() {
        DatabaseService service = new DatabaseService();
        Account acc = new Account();

        List<SObject> sobjectRecords = new List<SObject>{ acc };

        List<DatabaseService.SaveResult> saveResults;
        Exception actualException;
        Test.startTest();
        try {
            saveResults = service.insertRecords(sobjectRecords, true);
        } catch (Exception e) {
            actualException = e;
        }
        Test.stopTest();
        System.assertNotEquals(
            null,
            actualException,
            'Expected service to throw an exception on AllOrNothing DML failure'
        );
    }

    @IsTest
    private static void insertRecordsShouldThrowExceptionOnMissingCreatePermission() {
        User limitedPermissionUser = TestUtils.createUser(
            'Minimum Access - Salesforce',
            'nocreatepermissions@example.com'
        );
        DatabaseService service = new DatabaseService();
        String accountName = 'Insert Records Exception';

        Account acc = new Account(Name = accountName);
        List<SObject> sobjectRecords = new List<SObject>{ acc };

        Exception actualException;

        System.runAs(limitedPermissionUser) {
            Test.startTest();
            List<DatabaseService.SaveResult> saveResults;
            try {
                saveResults = service.insertRecords(sobjectRecords);
            } catch (SecurityService.DoesNotHaveCreateAccessForObjectException e) {
                actualException = e;
            } catch (Exception e) {
                System.assert(
                    false,
                    String.format(
                        'Expected exception of type {0}. Received exception of type {1}',
                        new List<String>{
                            SecurityService.DoesNotHaveCreateAccessForObjectException.class
                                .getName(),
                            e.getTypeName()
                        }
                    )
                );
            }
            Test.stopTest();
        }

        System.assertNotEquals(
            null,
            actualException,
            String.format(
                'Expected an exception to be thrown of type {0}',
                new List<String>{
                    DatabaseService.DoesNotHaveCreateAccessForObjectException.class
                        .getName()
                }
            )
        );
    }

    @IsTest
    private static void insertRecordsShouldThrowExceptionOnMissingFlsPermission() {
        final Schema.DescribeSObjectResult accountObjectDescribe = Schema.SObjectType.Account;
        final Schema.DescribeSObjectResult contactObjectDescribe = Schema.SObjectType.Contact; // Account Read Dependency
        Account expectedAccount = new Account(
            Name = 'Test Account',
            AccountNumber = '1234'
        );

        // GranteeAccountFormDataService_TEST.minimalAccessPersona.load();
        TestUser.MinimalAccessPersona minimalAccessPersona = new TestUser.MinimalAccessPersona();
        minimalAccessPersona.load();

        final TestUser.PermissionSetManager permissionSet = minimalAccessPersona.getPermissionSetManager();

        final TestUser.ObjectPermission accountPermission = permissionSet.getObjectPermission(
            accountObjectDescribe
        );
        final TestUser.ObjectPermission contactPermission = permissionSet.getObjectPermission(
            contactObjectDescribe
        );
        accountPermission.setRead(true).setCreate(true).setEdit(true);
        contactPermission.setRead(true); // Account read dependency

        final TestUser.FieldPermission accountNumberPermission = accountPermission.getFieldPermission(
            Schema.SObjectType.Account.fields.AccountNumber
        );
        accountNumberPermission.setRead(true);
        permissionSet.save();

        Exception actualException;

        Test.startTest();
        System.runAs(minimalAccessPersona.getUser()) {
            final Schema.DescribeFieldResult accountNumberDescribe = Schema.Account.AccountNumber.getDescribe();
            System.assertEquals(
                false,
                accountNumberDescribe.isUpdateable(),
                'accountNumber should NOT be editable for this test.'
            );

            DatabaseService service = new DatabaseService();

            List<SObject> sobjectRecords = new List<SObject>{ expectedAccount };

            List<DatabaseService.SaveResult> saveResults;

            try {
                saveResults = service.insertRecords(sobjectRecords);
            } catch (SecurityService.DoesNotHaveFLSForCreateException e) {
                actualException = e;
            } catch (Exception e) {
                System.assert(
                    false,
                    String.format(
                        'Expected the service to throw an exception of type {0}',
                        new List<String>{
                            SecurityService.DoesNotHaveFLSForCreateException.class
                                .getName()
                        }
                    )
                );
            }
        }
        Test.stopTest();
        System.assertNotEquals(
            null,
            actualException,
            'Expected the service to throw an exception'
        );
    }

    //Test to confirm updateRecord for a list of list of SObjects is successfully updating grouped records.
    @IsTest
    private static void listForChunkProtectionShouldUpdate() {
        final DatabaseService databaseService = new DatabaseService();

        Account testOrg1 = TestUtils.createAccount('Database Service Test Account 1');
        insert testOrg1;
        Account testOrg2 = TestUtils.createAccount('Database Service Test Account 2');
        insert testOrg2;
        Set<Id> accIds = new Set<Id>{ testOrg1.Id, testOrg2.Id };

        Contact testContact1 = TestUtils.createContact('Sara', 'Smith', testOrg1.Id);
        testContact1.Email = 'sarasmith@salesforce.testUsersSfdc.test';
        insert testContact1;
        Contact testContact2 = TestUtils.createContact('Steve', 'Smith', testOrg2.Id);
        testContact2.Email = 'stevesmith@salesforce.testUsersSfdc.test';
        insert testContact2;
        Set<Id> contactIds = new Set<Id>{ testContact1.Id, testContact2.Id };

        testOrg1.Name = testOrg1.Name + ' updated';
        testOrg2.Name = testOrg2.Name + ' updated';
        testContact1.LastName = 'Updated';
        testContact2.LastName = 'Updated';

        List<SObject> groupedRecords = new List<SObject>{
            (SObject) testOrg1,
            (SObject) testOrg2,
            (SObject) testContact1,
            (SObject) testContact2
        };

        Test.startTest();
        databaseService.updateRecords(groupedRecords);
        Test.stopTest();

        List<Contact> updatedContacts = [
            SELECT Id, FirstName, LastName
            FROM Contact
            WHERE Id IN :contactIds
        ];
        List<Account> updatedAccounts = [
            SELECT Id, Name
            FROM Account
            WHERE Id IN :accIds
        ];

        System.assertEquals(
            2,
            updatedContacts.size(),
            'We should have returned two contacts in our query'
        );
        System.assertEquals(
            'Updated',
            updatedContacts[0].LastName,
            'Our contact names should have been updated'
        );
        System.assertEquals(
            'Updated',
            updatedContacts[1].LastName,
            'Our contact names should have been updated'
        );
        System.assertEquals(
            2,
            updatedAccounts.size(),
            'We should have returned two Accounts in our query'
        );
        System.assertEquals(
            true,
            updatedAccounts[0].Name.contains('updated'),
            'Our contact names should have been updated'
        );
        System.assertEquals(
            true,
            updatedAccounts[1].Name.contains('updated'),
            'Our contact names should have been updated'
        );
        System.assertEquals(
            false,
            updatedContacts.isEmpty(),
            'We were expecting updated contacts but we found none'
        );
        System.assertEquals(
            false,
            updatedAccounts.isEmpty(),
            'We were expecting updated accounts but we found none'
        );
    }

    @IsTest
    private static void deleteRecordsByIdShouldDeleteRecords() {
        final Integer fundingProgramsCount = 5;
        final DatabaseService databaseService = new DatabaseService();

        final List<Schema.outfunds__Funding_Program__c> fundingPrograms = TestUtils.createFundingPrograms(
            fundingProgramsCount
        );
        insert fundingPrograms;

        Map<Id, outfunds__Funding_Program__c> programsById = new Map<Id, outfunds__Funding_Program__c>(
            [SELECT Id FROM outfunds__Funding_Program__c]
        );

        System.assertEquals(fundingProgramsCount, programsById.size());

        List<Database.DeleteResult> results = new List<Database.DeleteResult>();

        Test.startTest();
        results = databaseService.deleteRecordsById(new List<Id>(programsById.keyset()));
        Test.stopTest();

        for (Database.DeleteResult result : results) {
            System.assert(result.isSuccess());
        }

        System.assertEquals(0, [SELECT COUNT() FROM outfunds__Funding_Program__c]);
    }

    @IsTest
    private static void updateRecordsReturnsDatabaseServiceSaveResults() {
        String accountNumber = '12345';
        Account account = new Account(Name = 'Test Account');
        insert account;

        account.AccountNumber = accountNumber;

        List<DatabaseService.SaveResult> results;
        Exception actualException;

        Test.startTest();
        List<SObject> sObjectRecords = new List<SObject>{ account };

        results = new DatabaseService().updateRecords(sObjectRecords);
        Test.stopTest();

        System.assert(
            results[0].isSuccess(),
            String.format(
                'Expected the {0} object\'s isSuccess() call to return true',
                new List<String>{ DatabaseService.SaveResult.class.getName() }
            )
        );

        System.assertNotEquals(
            null,
            results,
            String.format(
                'Expected the {0} objects returned from the update call',
                new List<String>{ DatabaseService.SaveResult.class.getName() }
            )
        );

        System.assertNotEquals(
            null,
            results[0].getErrors(),
            String.format(
                'Expected the {0} object to contain no {1} records',
                new List<String>{
                    DatabaseService.SaveResult.class.getName(),
                    DatabaseService.Error.class.getName()
                }
            )
        );

        System.assertEquals(
            account.Id,
            results[0].getId(),
            String.format(
                'Expected the {0} object to return the record Id',
                new List<String>{ DatabaseService.SaveResult.class.getName() }
            )
        );
    }

    @IsTest
    private static void databaseServiceSaveResultShouldBeCreatedByConstructor() {
        DatabaseService.SaveResult saveResult;
        List<DatabaseService.Error> errors; // No errors
        Id accountId = TestUtils.mockId(Account.getSObjectType());
        Boolean saveSuccess = true;

        Test.startTest();
        saveResult = new DatabaseService.SaveResult(errors, accountId, saveSuccess);
        Test.stopTest();

        System.assertNotEquals(
            null,
            saveResult,
            String.format(
                'Expected a {0} object to be instantiated',
                new List<String>{ DatabaseService.SaveResult.class.getName() }
            )
        );
    }

    @IsTest
    private static void databaseServiceSaveResultShouldReturnResultErrors() {
        DatabaseService.SaveResult saveResult;
        System.StatusCode statusCode = System.StatusCode.REQUIRED_FIELD_MISSING;
        List<String> errorFields = new List<String>{ 'Name' };
        String errorMessage = 'Required fields are missing: [Name] : [Name]';

        DatabaseService.Error error = new DatabaseService.Error(
            errorFields,
            errorMessage,
            statusCode
        );

        Id accountId = TestUtils.mockId(Account.getSObjectType());
        Boolean saveSuccess = false;

        Test.startTest();
        saveResult = new DatabaseService.SaveResult(
            new List<DatabaseService.Error>{ error },
            accountId,
            saveSuccess
        );
        Test.stopTest();

        System.assertNotEquals(
            null,
            saveResult,
            String.format(
                'Expected a {0} object to be instantiated',
                new List<String>{ DatabaseService.SaveResult.class.getName() }
            )
        );

        System.assertEquals(
            saveSuccess,
            saveResult.isSuccess(),
            String.format(
                'Expected the instantiated {0} to return isSuccess() true',
                new List<String>{ DatabaseService.SaveResult.class.getName() }
            )
        );

        System.assert(
            !saveResult.getErrors().isEmpty(),
            String.format(
                'Expected the instantiated {0} to return a list of errors',
                new List<String>{ DatabaseService.SaveResult.class.getName() }
            )
        );

        System.assertEquals(
            errorFields,
            saveResult.getErrors()[0].getFields(),
            String.format(
                'Expected the error fields returned from the {0} object to match the fields passed to the constructor',
                new List<String>{ DatabaseService.Error.class.getName() }
            )
        );
    }

    @IsTest
    private static void databaseServiceSaveResultShouldReturnResultRecordId() {
        DatabaseService.SaveResult saveResult;
        DatabaseService.Error error; // No errors
        Id accountId = TestUtils.mockId(Account.getSObjectType());
        Boolean saveSuccess = true;

        Test.startTest();
        saveResult = new DatabaseService.SaveResult(
            new List<DatabaseService.Error>{ error },
            accountId,
            saveSuccess
        );
        Test.stopTest();

        System.assertNotEquals(
            null,
            saveResult,
            String.format(
                'Expected a {0} object to be instantiated',
                new List<String>{ DatabaseService.SaveResult.class.getName() }
            )
        );

        System.assertEquals(
            accountId,
            saveResult.getId(),
            String.format(
                'Expected the record Id returned from the {0} to match the Id provided to the constructor',
                new List<String>{ DatabaseService.SaveResult.class.getName() }
            )
        );
    }

    @IsTest
    private static void databaseServiceSaveResultShouldReturnResultSuccess() {
        DatabaseService.SaveResult saveResult;
        DatabaseService.Error error; // No errors
        Id accountId = TestUtils.mockId(Account.getSObjectType());
        Boolean saveSuccess = true;

        Test.startTest();
        saveResult = new DatabaseService.SaveResult(
            new List<DatabaseService.Error>{ error },
            accountId,
            saveSuccess
        );
        Test.stopTest();

        System.assertNotEquals(
            null,
            saveResult,
            String.format(
                'Expected a {0} object to be instantiated',
                new List<String>{ DatabaseService.SaveResult.class.getName() }
            )
        );

        System.assertEquals(
            saveSuccess,
            saveResult.isSuccess(),
            String.format(
                'Expected the instantiated {0} to return true',
                new List<String>{ DatabaseService.SaveResult.class.getName() }
            )
        );
    }

    @IsTest
    private static void databaseServiceErrorShouldBeCreatedByConstructor() {
        DatabaseService.Error error;
        System.StatusCode statusCode = System.StatusCode.REQUIRED_FIELD_MISSING;
        List<String> errorFields = new List<String>{ 'Name' };
        String errorMessage = 'Required fields are missing: [Name] : [Name]';

        Test.startTest();
        error = new DatabaseService.Error(errorFields, errorMessage, statusCode);
        Test.stopTest();

        System.assertNotEquals(
            null,
            error,
            String.format(
                'Expected a {0} object to be instantiated',
                new List<String>{ DatabaseService.Error.class.getName() }
            )
        );
    }

    @IsTest
    private static void databaseServiceErrorShouldReturnErrorFields() {
        DatabaseService.Error error;
        System.StatusCode statusCode = System.StatusCode.REQUIRED_FIELD_MISSING;
        List<String> errorFields = new List<String>{ 'Name' };
        String errorMessage = 'Required fields are missing: [Name] : [Name]';

        Test.startTest();
        error = new DatabaseService.Error(errorFields, errorMessage, statusCode);
        Test.stopTest();

        System.assertNotEquals(
            null,
            error,
            String.format(
                'Expected the instantiated {0} to return a list of fields',
                new List<String>{ DatabaseService.Error.class.getName() }
            )
        );

        System.assertEquals(
            errorFields,
            error.getFields(),
            String.format(
                'Expected the error fields returned from the {0} object to match the fields passed to the constructor',
                new List<String>{ DatabaseService.Error.class.getName() }
            )
        );
    }

    @IsTest
    private static void databaseServiceErrorShouldReturnErrorMessage() {
        DatabaseService.Error error;
        System.StatusCode statusCode = System.StatusCode.REQUIRED_FIELD_MISSING;
        List<String> errorFields = new List<String>{ 'Name' };
        String errorMessage = 'Required fields are missing: [Name] : [Name]';

        Test.startTest();
        error = new DatabaseService.Error(errorFields, errorMessage, statusCode);
        Test.stopTest();

        System.assertNotEquals(
            null,
            error,
            String.format(
                'Expected the instantiated {0} to return a list of true',
                new List<String>{ DatabaseService.SaveResult.class.getName() }
            )
        );

        System.assertEquals(
            errorMessage,
            error.getMessage(),
            String.format(
                'Expected the error message returned from the {0} object to match the error message passed to the constructor',
                new List<String>{ DatabaseService.Error.class.getName() }
            )
        );
    }

    @IsTest
    private static void databaseServiceErrorShouldReturnStatusCode() {
        DatabaseService.Error error;
        System.StatusCode statusCode = System.StatusCode.REQUIRED_FIELD_MISSING;
        List<String> errorFields = new List<String>{ 'Name' };
        String errorMessage = 'Required fields are missing: [Name] : [Name]';

        Test.startTest();
        error = new DatabaseService.Error(errorFields, errorMessage, statusCode);
        Test.stopTest();

        System.assertNotEquals(
            null,
            error,
            String.format(
                'Expected the instantiated {0} to return a list of true',
                new List<String>{ DatabaseService.SaveResult.class.getName() }
            )
        );

        System.assertEquals(
            statusCode,
            error.getStatusCode(),
            String.format(
                'Expected the status code returned from the {0} object to match the status code passed to the constructor',
                new List<String>{ DatabaseService.Error.class.getName() }
            )
        );
    }

    @IsTest
    private static void getSaveResultsShouldReturnListOfSaveResults() {
        Integer recordCount = 3;
        List<Account> accounts = new List<Account>();
        for (Integer i = 0; i < recordCount; i++) {
            accounts.add(new Account(Name = 'Test Account ' + String.valueOf(i)));
        }

        List<DatabaseService.SaveResult> serviceResults;
        Test.startTest();
        List<Database.SaveResult> saveResults = Database.insert(accounts);
        serviceResults = new DatabaseService().getSaveResults(saveResults);
        Test.stopTest();

        System.assert(
            !serviceResults.isEmpty(),
            String.format(
                'Expected the {0} to return a list of {1}',
                new List<String>{
                    DatabaseService.class.getName(),
                    DatabaseService.SaveResult.class.getName()
                }
            )
        );

        System.assertEquals(
            recordCount,
            serviceResults.size(),
            String.format(
                'Expected the getSaveResults operation to return the same number of {0}s as records',
                new List<String>{ DatabaseService.SaveResult.class.getName() }
            )
        );
    }

    @IsTest
    private static void updateRecordsWithAllOrNothingShouldThrowExceptionOnError() {
        Integer recordCount = 3;
        Integer employeeCount = 150;
        List<Account> accounts = new List<Account>();
        for (Integer i = 0; i < recordCount; i++) {
            accounts.add(
                new Account(
                    Id = TestUtils.mockId(Account.getSObjectType()),
                    Name = 'Test Account ' + String.valueOf(i)
                )
            );
        }

        Test.startTest();
        // All or Nothing
        Exception actualException;
        try {
            List<DatabaseService.SaveResult> results = new DatabaseService()
                .updateRecords(accounts, true);
        } catch (Exception e) {
            actualException = e;
        }
        Test.stopTest();

        System.assertNotEquals(
            null,
            actualException,
            'Expected the allOrNothing updateRecords call to throw an exception'
        );
    }

    @IsTest
    private static void updateRecordsShouldReturnSaveResultsWithErrors() {
        Integer recordCount = 3;
        List<Account> accounts = new List<Account>();
        for (Integer i = 0; i < recordCount; i++) {
            accounts.add(
                new Account(
                    Id = TestUtils.mockId(Account.getSObjectType()),
                    Name = 'Test Account ' + String.valueOf(i)
                )
            );
        }

        Test.startTest();
        Exception actualException;
        List<DatabaseService.SaveResult> results;
        try {
            results = new DatabaseService().updateRecords(accounts, false);
        } catch (Exception e) {
            actualException = e;
        }
        Test.stopTest();

        System.assertEquals(
            null,
            actualException,
            'updateRecords should not throw an exception when allOrNothing is false'
        );

        System.assertEquals(
            recordCount,
            results.size(),
            String.format(
                'Expected {0} SaveResults, but received {1}',
                new List<String>{
                    String.valueOf(recordCount),
                    String.valueOf(results.size())
                }
            )
        );

        System.assertNotEquals(
            null,
            results[0].getErrors(),
            String.format(
                'updateRecords should have returned {0} records containing {1} records',
                new List<String>{
                    DatabaseService.SaveResult.class.getName(),
                    DatabaseService.Error.class.getName()
                }
            )
        );
    }

    @IsTest
    private static void updateRecordsDmlFailureWithoutAllOrNothingParameterSetShouldThrowException() {
        Account account = new Account(
            Id = TestUtils.mockId(Account.getSObjectType()),
            Name = 'Test Account'
        );

        Test.startTest();
        Exception actualException;
        try {
            List<SObject> groupedRecords = new List<SObject>{ account };
            // All or Nothing
            List<DatabaseService.SaveResult> results = new DatabaseService()
                .updateRecords(groupedRecords);
        } catch (Exception e) {
            actualException = e;
        }
        Test.stopTest();

        System.assertNotEquals(
            null,
            actualException,
            'Expected the allOrNothing updateRecords call to throw an exception'
        );
    }
}
