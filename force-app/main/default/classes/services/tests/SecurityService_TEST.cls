@isTest
public with sharing class SecurityService_TEST {
    //The service we need for all the tests
    private static final SecurityService SERVICE = new SecurityService();
    private static final Id runningUserId = UserInfo.getUserId();

    /////////////////////////////////////
    // verifyIsUpdateableTests
    //
    /**
     * sobjectShouldBeUpdateableWithVerifyIsUpdateable
     * verifyIsUpdateable should not throw exception on updatable object
     */
    @isTest
    private static void sobjectShouldBeUpdateableWithVerifyIsUpdateable() {
        Exception actualException;
        Contact testContact = new Contact(
            FirstName = 'Grace',
            LastName = 'Walker',
            Email = 'gracewalker@salesforce.comtest',
            AccountId = TestUtils.mockId(Schema.SObjectType.Account)
        );
        Test.startTest();
        try {
            SERVICE.verifyIsUpdateable(new List<SObject>{ testContact });
        } catch (Exception e) {
            actualException = e;
            System.assertNotEquals(
                null,
                e,
                'Contact and fields should be verified as updateable without exception by Running User.'
            );
        }
        Test.stopTest();
        system.assertEquals(
            null,
            actualException,
            'There should have been no exceptions thrown'
        );
    }

    /**
     * shouldThrowNoRecordsExceptionWhenVerifyUpdateableWithNoRecord
     * verifyIsUpdateable should throw noRecordsToCheckSecurityException when no record is called with it
     */
    @isTest
    private static void shouldThrowNoRecordsExceptionWhenVerifyUpdateableWithNoRecord() {
        Exception actualException;
        SObject testRecord;
        Test.startTest();
        try {
            SERVICE.verifyIsUpdateable(new List<SObject>{ testRecord });
        } catch (SecurityService.NoRecordsToCheckSecurityException e) {
            actualException = e;
        } catch (Exception e) {
            System.assert(
                false,
                String.format(
                    'A {0} should have been thrown, but a {1} was thrown instead.',
                    new List<String>{
                        SecurityService.NoRecordsToCheckSecurityException.class.getName(),
                        e.getTypeName()
                    }
                )
            );
        }
        Test.stopTest();
        System.assertNotEquals(
            null,
            actualException,
            'Expecting a ' +
            SecurityService.NoRecordsToCheckSecurityException.class.getName() +
            ' to be thrown.'
        );
    }

    /**
     * shouldThrowNoRecordsExceptionWhenVerifyUpdateableWithNoRecords
     * verifyIsUpdateable should not throw exception on updatable object
     */
    @isTest
    private static void shouldThrowNoRecordsExceptionWhenVerifyUpdateableWithNoRecords() {
        Exception actualException;
        List<SObject> testRecords;
        Test.startTest();
        try {
            SERVICE.verifyIsUpdateable(testRecords);
        } catch (SecurityService.NoRecordsToCheckSecurityException e) {
            actualException = e;
        } catch (Exception e) {
            System.assert(
                false,
                String.format(
                    'A {0} should have been thrown, but a {1} was thrown instead.',
                    new List<String>{
                        SecurityService.NoRecordsToCheckSecurityException.class.getName(),
                        e.getTypeName()
                    }
                )
            );
        }
        Test.stopTest();
        System.assertNotEquals(
            null,
            actualException,
            'Expecting a ' +
            SecurityService.NoRecordsToCheckSecurityException.class.getName() +
            ' to be thrown.'
        );
    }

    /**
     * shouldThrowExceptionWhenVerifyUpdateableWithObjectNotUpdateable
     * verifyIsUpdateable should throw exception with an object that is not updateable
     */
    @isTest
    private static void shouldThrowExceptionWhenVerifyUpdateableWithObjectNotUpdateable() {
        Exception actualException;

        Test.startTest();
        Id runningUserId = runningUserId;
        UserRecordAccess testRecord = [
            SELECT RecordId, MaxAccessLevel
            FROM UserRecordAccess
            WHERE UserId = :runningUserId AND RecordId = :runningUserId
        ];
        try {
            SERVICE.verifyIsUpdateable(new List<SObject>{ testRecord });
        } catch (SecurityService.DoesNotHaveUpdateForObjectException e) {
            actualException = e;
        } catch (Exception e) {
            System.assert(
                false,
                String.format(
                    'A {0} should have been thrown, but a {1} was thrown instead.',
                    new List<String>{
                        SecurityService.DoesNotHaveUpdateForObjectException.class
                            .getName(),
                        e.getTypeName()
                    }
                )
            );
        }

        Test.stopTest();
        System.assertNotEquals(
            null,
            actualException,
            'Expecting a ' +
            SecurityService.DoesNotHaveUpdateForObjectException.class.getName() +
            ' to be thrown.'
        );
    }

    /**
     * shouldThrowExceptionWhenVerifyUpdateableWithNoFLSUpdateable
     *verifyIsUpdateable should throw throw exception when object includes fields not editable
     */
    @isTest
    private static void shouldThrowExceptionWhenVerifyUpdateableWithNoFLSUpdateable() {
        Exception actualException;
        Contact testRecord = new Contact(
            FirstName = 'Grace',
            LastName = 'Walker',
            Email = 'gracewalker@salesforce.comtest',
            AccountId = TestUtils.mockId(Schema.SObjectType.Account)
        );
        Test.startTest();
        System.runAs(TestUtils.createUser(
            'Standard User',
            'TestGrants2020@salesforce.test.com'
        )) {
            // 'Standard User' profile does not have edit access on the DoNotCall field by default.
            testRecord.DoNotCall = true;
            try {
                SERVICE.verifyIsUpdateable(testRecord);
            } catch (SecurityService.DoesNotHaveFLSForEditException e) {
                actualException = e;
            } catch (Exception e) {
                System.assert(
                    false,
                    String.format(
                        'A {0} should have been thrown, but a {1} was thrown instead.',
                        new List<String>{
                            SecurityService.DoesNotHaveFLSForEditException.class
                                .getName(),
                            e.getTypeName()
                        }
                    )
                );
            }
        }

        Test.stopTest();
        System.assertNotEquals(
            null,
            actualException,
            'Expecting a ' +
            SecurityService.DoesNotHaveFLSForEditException.class.getName() +
            ' to be thrown.'
        );
    }

    /////////////////////////////////////
    // verifyisCreatableTests
    //
    /**
     * sobjectShouldBeCreatableWithVerifyIsCreateable
     * verifyIsCreateable should not throw exception on updatable object
     */
    @isTest
    private static void sobjectShouldBeCreatableWithVerifyIsCreateable() {
        Contact testContact = new Contact(
            FirstName = 'Grace',
            LastName = 'Walker',
            Email = 'gracewalker@salesforce.comtest',
            AccountId = TestUtils.mockId(Schema.SObjectType.Account)
        );
        Test.startTest();
        try {
            SERVICE.verifyIsCreateable(new List<SObject>{ testContact });
        } catch (Exception e) {
            System.assertNotEquals(
                null,
                e,
                'Contact and fields should be verified as createable without exception by Running User.'
            );
        }
        Test.stopTest();
    }

    /**
     * shouldThrowNoRecordsExceptionWhenVerifyCreateableWithNoRecord
     * verifyIsCreateable should throw noRecordsToCheckSecurityException when no record is called with it
     */
    @isTest
    private static void shouldThrowNoRecordsExceptionWhenVerifyCreateableWithNoRecord() {
        Exception actualException;
        SObject testRecord;
        Test.startTest();
        try {
            SERVICE.verifyIsCreateable(new List<SObject>{ testRecord });
        } catch (SecurityService.NoRecordsToCheckSecurityException e) {
            actualException = e;
        } catch (Exception e) {
            System.assert(
                false,
                String.format(
                    'A {0} should have been thrown, but a {1} was thrown instead.',
                    new List<String>{
                        SecurityService.NoRecordsToCheckSecurityException.class.getName(),
                        e.getTypeName()
                    }
                )
            );
        }
        Test.stopTest();
        System.assertNotEquals(
            null,
            actualException,
            'Expecting a ' +
            SecurityService.NoRecordsToCheckSecurityException.class.getName() +
            ' to be thrown.'
        );
    }
    /**
     * shouldThrowNoRecordsExceptionWhenVerifyCreateableWithNoRecords
     * verifyIsCreateable should not throw exception on createable object
     */
    @isTest
    private static void shouldThrowNoRecordsExceptionWhenVerifyCreateableWithNoRecords() {
        Exception actualException;
        List<SObject> testRecords;
        Test.startTest();
        try {
            SERVICE.verifyIsCreateable(testRecords);
        } catch (SecurityService.NoRecordsToCheckSecurityException e) {
            actualException = e;
        } catch (Exception e) {
            System.assert(
                false,
                String.format(
                    'A {0} should have been thrown, but a {1} was thrown instead.',
                    new List<String>{
                        SecurityService.NoRecordsToCheckSecurityException.class.getName(),
                        e.getTypeName()
                    }
                )
            );
        }
        Test.stopTest();
        System.assertNotEquals(
            null,
            actualException,
            'Expecting a ' +
            SecurityService.NoRecordsToCheckSecurityException.class.getName() +
            ' to be thrown.'
        );
    }
    /**
     * shouldThrowExceptionWhenVerifyCreateableWithObjectNotUpdateable
     * verifyIsCreateable should throw exception with an object that is not createable
     */
    @isTest
    private static void shouldThrowExceptionWhenVerifyCreateableWithObjectNotCreatable() {
        Exception actualException;
        SObject testSObject;

        Test.startTest();
        Id runningUserId = runningUserId;
        UserRecordAccess testRecord = [
            SELECT RecordId, MaxAccessLevel
            FROM UserRecordAccess
            WHERE UserId = :runningUserId AND RecordId = :runningUserId
        ];
        try {
            SERVICE.verifyIsCreateable(new List<SObject>{ testRecord });
        } catch (SecurityService.DoesNotHaveCreateAccessForObjectException e) {
            actualException = e;
        } catch (Exception e) {
            System.assert(
                false,
                String.format(
                    'A {0} should have been thrown, but a {1} was thrown instead.',
                    new List<String>{
                        SecurityService.DoesNotHaveCreateAccessForObjectException.class
                            .getName(),
                        e.getTypeName()
                    }
                )
            );
        }

        Test.stopTest();
        System.assertNotEquals(
            null,
            actualException,
            'Expecting a ' +
            SecurityService.DoesNotHaveCreateAccessForObjectException.class.getName() +
            ' to be thrown.'
        );
    }
    /**
     * shouldThrowExceptionWhenVerifyCreateableWithNoFLSUpdateable
     *verifyIsCreateable should throw throw exception when object includes fields not editable
     */
    @isTest
    private static void shouldThrowExceptionWhenVerifyCreateableWithNoFLSUpdateable() {
        Exception actualException;
        Contact testRecord = new Contact(
            FirstName = 'Grace',
            LastName = 'Walker',
            Email = 'gracewalker@salesforce.comtest',
            AccountId = TestUtils.mockId(Schema.SObjectType.Account)
        );
        Test.startTest();
        System.runAs(TestUtils.createUser(
            'Standard User',
            'TestGrants2020@salesforce.test.com'
        )) {
            // 'Standard User' profile does not have edit access on the DoNotCall field by default.
            testRecord.DoNotCall = true;
            try {
                SERVICE.verifyIsCreateable(testRecord);
            } catch (SecurityService.DoesNotHaveFLSForCreateException e) {
                actualException = e;
            } catch (Exception e) {
                System.assert(
                    false,
                    String.format(
                        'A {0} should have been thrown, but a {1} was thrown instead.',
                        new List<String>{
                            SecurityService.DoesNotHaveFLSForCreateException.class
                                .getName(),
                            e.getTypeName()
                        }
                    )
                );
            }
        }

        Test.stopTest();
        System.assertNotEquals(
            null,
            actualException,
            'Expecting a ' +
            SecurityService.DoesNotHaveFLSForCreateException.class.getName() +
            ' to be thrown.'
        );
    }

    //////////////////////////////////////////////////////////////////////////
    // getRecordAccess tests
    //
    /**
     * shouldReturnUserRecordAccessWithUserId
     * Should return UserRecordAccess record for the running user's User record.
     */
    @IsTest
    public static void shouldReturnUserRecordAccessWithUserId() {
        UserRecordAccess recordsAccess;

        Test.startTest();
        recordsAccess = SERVICE.getUserRecordAccess(runningUserId, runningUserId);
        Test.stopTest();
        System.assertNotEquals(
            null,
            recordsAccess,
            'We should have pulled back at least one UserRecordAccess from the running user'
        );
    }

    /**
     * shouldReturnUserRecordAccessWithUserId
     * Should return UserRecordAccess for the User record of the running user
     */
    @IsTest
    public static void shouldReturnUserRecordAccessWithoutUserId() {
        UserRecordAccess recordsAccess;

        Test.startTest();
        recordsAccess = SERVICE.getUserRecordAccess(runningUserId);
        Test.stopTest();
        System.assertNotEquals(
            null,
            recordsAccess,
            'We should have pulled back at least one UserRecordAccess from the running user'
        );
    }

    /**
     * shouldReturnUserRecordAccessAndBeAccurateAsMinimalProfileUser
     * Should return UserRecordAccess for the inserted Account record as
     * the Minimim Access profile test user, and verify access levels are locked down
     */
    @IsTest
    public static void shouldReturnUserRecordAccessAndBeAccurateAsMinimalProfileUser() {
        User simpleUser = TestUtils.createUser(
            'Minimum Access - Salesforce',
            'TesGrants2020@salesforce.test.com'
        );
        insert simpleUser;

        UserRecordAccess recordsAccess;
        Account testAccount = TestUtils.createAccount('Should not have access');
        insert testAccount;

        Test.startTest();

        System.runAs(simpleUser) {
            System.assertNotEquals(
                null,
                simpleUser.Id,
                'The test User did not insert: ' + simpleUser
            );
            recordsAccess = SERVICE.getUserRecordAccess(simpleUser.Id, testAccount.Id);
        }
        Test.stopTest();
        System.assertNotEquals(
            null,
            recordsAccess,
            'We should have pulled back at least one UserRecordAccess from the running user'
        );
        // verify the UserRecordAccess is for record we expect
        System.assertEquals(testAccount.Id, recordsAccess.RecordId);
        // The test user should NOT have Read,Delete,Edit, OR TransferAccess
        System.assertEquals(false, recordsAccess.HasReadAccess);
        System.assertEquals(false, recordsAccess.HasDeleteAccess);
        System.assertEquals(false, recordsAccess.HasEditAccess);
        System.assertEquals(false, recordsAccess.HasTransferAccess);
        // The test user should have the Maximum access level of 'None'
        System.assertEquals('None', recordsAccess.MaxAccessLevel);
    }

    /**
     * shouldReturnUserRecordAccessMapWithGetRecordsAccessWithRecords
     * Should return a Map of <Id, UserRecordAccess> for the records as the running user
     */
    @IsTest
    public static void shouldReturnUserRecordAccessMapWithGetRecordsAccessWithRecords() {
        Map<ID, UserRecordAccess> recordsAccess = new Map<ID, UserRecordAccess>();
        Set<Id> records = new Set<Id>{ runningUserId };
        Test.startTest();
        recordsAccess = SERVICE.getRecordsAccessForUser(records);
        Test.stopTest();
        System.assertNotEquals(
            null,
            recordsAccess,
            'We should have pulled back at least one UserRecordAccess from the running user'
        );
    }

    /**
     * shouldReturnMapOfIdToHasTransferAccessForRecords description
     * Should return a map of <Id, Boolean> with the value of HasTransferAccess as the boolean for the records provided
     */
    @isTest
    public static void shouldReturnMapOfIdToHasTransferAccessForRecords() {
        Set<Id> recordIds = new Set<Id>{ runningUserId };

        Map<Id, Boolean> recordToTransferAccess = new Map<Id, Boolean>();
        Test.startTest();
        recordToTransferAccess = SERVICE.getHasTransferAccess(recordIds);
        Test.stopTest();
        System.assertNotEquals(
            null,
            recordToTransferAccess.get(runningUserId),
            'The UserRecordAccess should have a HasTransferAccess value not null'
        );
    }

    /**
     * shouldReturnMapOfIdToHasReadAccessForRecords
     * Should return a map of <Id, Boolean> with the value of HasReadAccess as the boolean for the records provided
     */
    @isTest
    public static void shouldReturnMapOfIdToHasReadAccessForRecords() {
        Set<Id> recordIds = new Set<Id>{ runningUserId };

        Map<Id, Boolean> recordToReadAccess = new Map<Id, Boolean>();
        Test.startTest();
        recordToReadAccess = SERVICE.getHasReadAccess(recordIds);
        Test.stopTest();
        System.assertNotEquals(
            null,
            recordToReadAccess.get(runningUserId),
            'The UserRecordAccess should have a HasReadAccess value not null'
        );
    }

    /**
     * shouldThrowExceptionWhenGetRecordsAccessWithoutRecords
     * Should throw an exception when getRecordsAccessForUser is called with blank set of records
     */
    @IsTest
    public static void shouldThrowExceptionWhenGetRecordsAccessWithoutRecords() {
        Exception actualException;
        Map<ID, UserRecordAccess> recordsAccess = new Map<ID, UserRecordAccess>();
        Set<Id> records;

        Test.startTest();
        try {
            recordsAccess = SERVICE.getRecordsAccessForUser(records);
        } catch (SecurityService.NoRecordsToCheckSecurityException e) {
            actualException = e;
        } catch (Exception e) {
            System.assert(
                false,
                String.format(
                    'A {0} should have been thrown, but a {1} was thrown instead.',
                    new List<String>{
                        SecurityService.NoRecordsToCheckSecurityException.class.getName(),
                        e.getTypeName()
                    }
                )
            );
        }

        Test.stopTest();
        System.assertNotEquals(
            null,
            actualException,
            'Expecting a ' +
            SecurityService.NoRecordsToCheckSecurityException.class.getName() +
            ' to be thrown.'
        );
    }

    /**
     * shouldThrowExceptionWhenGetRecordsAccessWithoutRecordsOverload
     * Should throw an exception when getRecordsAccessForUser is called with blank set of records with a provided userId
     */
    @IsTest
    public static void shouldThrowExceptionWhenGetRecordsAccessWithoutRecordsOverload() {
        Exception actualException;
        Map<ID, UserRecordAccess> recordsAccess = new Map<ID, UserRecordAccess>();
        Set<Id> records;

        Test.startTest();
        try {
            recordsAccess = SERVICE.getRecordsAccessForUser(runningUserId, records);
        } catch (SecurityService.NoRecordsToCheckSecurityException e) {
            actualException = e;
        } catch (Exception e) {
            System.assert(
                false,
                String.format(
                    'A {0} should have been thrown, but a {1} was thrown instead.',
                    new List<String>{
                        SecurityService.NoRecordsToCheckSecurityException.class.getName(),
                        e.getTypeName()
                    }
                )
            );
        }

        Test.stopTest();
        System.assertNotEquals(
            null,
            actualException,
            'Expecting a ' +
            SecurityService.NoRecordsToCheckSecurityException.class.getName() +
            ' to be thrown.'
        );
    }

    //////////////////////////////////////////////////////////////////////////
    // FLS  Insert tests
    //
    /**
     * testHasFLSAccessInsertGoodField
     */
    @IsTest
    private static void testHasFLSAccessInsertGoodField() {
        Boolean canAccessContactName = SERVICE
            .hasFLSAccessForFields('Contact', new List<String>{ 'LastName' }, 'insert');
        System.assert(
            canAccessContactName,
            'Has insert perms on Contact.LastName, expect true'
        );
    }

    @IsTest
    private static void testHasFLSAccessInsertBadObjectName() {
        Boolean badObjectName = SERVICE
            .hasFLSAccessForFields('TestObject', new List<String>{ 'Test' }, 'insert');
        System.assert(!badObjectName, 'Bad object name, expect false');
    }

    /**
     * testHasFLSAccessInsertBadFieldName
     */
    @IsTest
    private static void testHasFLSAccessInsertBadFieldName() {
        Boolean badFieldName = SERVICE
            .hasFLSAccessForFields(
                'Contact',
                new List<String>{ 'BadFieldName__123' },
                'insert'
            );
        System.assert(!badFieldName, 'Bad field name, expect false');
    }

    /**
     * testHasFLSAccessInsertNonCreatableField
     */
    @IsTest
    private static void testHasFLSAccessInsertNonCreatableField() {
        Boolean nonCreatableField = SERVICE
            .hasFLSAccessForFields(
                'Contact',
                new List<String>{ 'LastModifiedById' },
                'insert'
            );
        System.assert(!nonCreatableField, 'Can not modify system field, expect false');
    }

    //////////////////////////////////////////////////////////////////////////
    // FLS Upsert tests
    //

    /**
     * testHasFLSAccessUpsertBadFieldName
     */
    @IsTest
    private static void testHasFLSAccessUpsertBadFieldName() {
        Boolean nonExistentField = SERVICE
            .hasFLSAccessForFields(
                'Contact',
                new List<String>{ 'BadObjectName__123' },
                'upsert'
            );
        System.assert(!nonExistentField, 'Bad field name, expect false');
    }

    /**
     * testHasFLSAccessUpsertNonReparentable
     */
    @IsTest
    private static void testHasFLSAccessUpsertNonReparentable() {
        Boolean nonUpdateableField = SERVICE
            .hasFLSAccessForFields(
                Schema.sObjectType.User.getName(),
                new List<String>{ Schema.sObjectType.User.fields.Id.getName() },
                'upsert'
            );
        System.assert(!nonUpdateableField, 'Non-reparentable lookup, expect false');
    }

    /**
     * testHasFLSAccessUpsertGoodField
     */
    @IsTest
    private static void testHasFLSAccessUpsertGoodField() {
        Boolean editableField = SERVICE
            .hasFLSAccessForFields('Contact', new List<String>{ 'FirstName' }, 'upsert');
        System.assert(editableField, 'Editable field, expect true');
    }

    //////////////////////////////////////////////////////////////////////////
    // FLS Update tests
    //
    /**
     * testHasFLSAccessUpdateGoodField description
     */
    @IsTest
    private static void testHasFLSAccessUpdateGoodField() {
        Boolean editableField = SERVICE
            .hasFLSAccessForFields('Contact', new List<String>{ 'FirstName' }, 'update');
        System.assert(editableField, 'Editable field, expect true');
    }

    /**
     * testHasFLSAccessUpdateBadFieldName description
     *
     */
    @IsTest
    private static void testHasFLSAccessUpdateBadFieldName() {
        Boolean fieldCantUpdate = SERVICE
            .hasFLSAccessForFields(
                'Contact',
                new List<String>{ 'LastModifiedById' },
                'update'
            );
        System.assert(!fieldCantUpdate, 'Field we cant update, expect false');
    }

    /**
     * testHasFLSAccessUpdateBadFieldName The hasFLSAccess method should skip over Id fields in update.
     * These are not updateable but needed in update call
     */
    @IsTest
    private static void testHasFLSAccessUpdateShouldSkipIdField() {
        Boolean idField = SERVICE
            .hasFLSAccessForFields(
                'Contact',
                new List<String>{ 'Id', 'FirstName' },
                'update'
            );
        System.assert(
            idField,
            'Id field is skipped because not updateable, but FirstName should be editable, expect true'
        );
    }

    //////////////////////////////////////////////////////////////////////////
    // FLS Read tests
    //

    /**
     * testHasFLSAccessReadGoodField
     */
    @IsTest
    private static void testHasFLSAccessReadGoodField() {
        Boolean readableField = SERVICE
            .hasFLSAccessForFields('Contact', new List<String>{ 'FirstName' }, 'read');
        System.assert(readableField, 'Readable field, expect true');
    }

    /**
     * testHasFLSAccessNoFLSField
     */
    @IsTest
    private static void testHasFLSAccessNoFLSField() {
        Boolean noFLSField;
        System.runAs(TestUtils.createUser('Standard User', 'Test989@test.com')) {
            // test user has no custom object permissions
            noFLSField = SERVICE
                .hasFLSAccessForFields(
                    'Contact',
                    new List<String>{ 'DoNotCall' },
                    'read'
                );
        }
        System.assert(!noFLSField, 'Custom field name, expect false');
    }

    /**
     * testGetAccessibleFields
     */
    @IsTest
    private static void testGetAccessibleFields() {
        Test.startTest();
        Set<DescribeFieldResult> expected;
        Set<DescribeFieldResult> actual;
        System.runAs(TestUtils.createUser('Standard User', 'Test989@test.com')) {
            expected = new Set<DescribeFieldResult>{
                Schema.SObjectType.Contact.Fields.FirstName
            };
            Set<DescribeFieldResult> fields = new Set<DescribeFieldResult>{
                Schema.SObjectType.Contact.Fields.FirstName,
                Schema.SObjectType.Contact.Fields.DoNotCall
            };
            actual = SERVICE.getAccessibleFields(fields);
        }
        Test.stopTest();

        System.assertEquals(expected, actual);
    }

    //////////////////////////////////////////////////////////////////////////
    // Object Access tests
    //

    /**
     * testHasObjectAccessWithStandardObjectsAsAdmin
     */
    @IsTest
    private static void testHasObjectAccessWithStandardObjectsAsAdmin() {
        Boolean canCreateContact = SERVICE
            .hasObjectAccess(
                Contact.SObjectType,
                SecurityService.CRUDAccessType.CREATEABLE
            );
        System.assert(canCreateContact, 'Has Create perms on Contact, expect true');

        Boolean canReadContact = SERVICE
            .hasObjectAccess(
                Contact.SObjectType,
                SecurityService.CRUDAccessType.READABLE
            );
        System.assert(canReadContact, 'Has Read perms on Contact, expect true');

        Boolean canUpdateContact = SERVICE
            .hasObjectAccess(
                Contact.SObjectType,
                SecurityService.CRUDAccessType.UPDATEABLE
            );
        System.assert(canUpdateContact, 'Has Update perms on Contact, expect true');

        Boolean canDeleteContact = SERVICE
            .hasObjectAccess(
                Contact.SObjectType,
                SecurityService.CRUDAccessType.DELETEABLE
            );
        System.assert(canDeleteContact, 'Has Delete perms on Contact, expect true');
    }

    /**
     * testHasObjectAccessWithNullSObjectType description
     */
    @IsTest
    private static void testHasObjectAccessWithNullSObjectType() {
        Boolean nullSObjectType = SERVICE
            .hasObjectAccess(null, SecurityService.CRUDAccessType.READABLE);
        System.assert(!nullSObjectType, 'Null SObjectType, expect false');
    }

    /**
     * testHasObjectAccessWithNullCRUDAccessType
     */
    @IsTest
    private static void testHasObjectAccessWithNullCRUDAccessType() {
        Boolean nullCRUDAccessType = SERVICE.hasObjectAccess(Contact.SObjectType, null);
        System.assert(!nullCRUDAccessType, 'Null CRUDAccessType, expect false');
    }

    /**
     * securityExceptionShouldReturnLabels A test to confirm our exceptions return messages we expect
     */
    @IsTest
    public static void securityExceptionShouldReturnLabels() {
        test.startTest();
        SecurityService.DoesNotHaveLevelOfAccessForActionException ex1 = new SecurityService.DoesNotHaveLevelOfAccessForActionException();
        SecurityService.DoesNotHaveUpdateForObjectException ex2 = new SecurityService.DoesNotHaveUpdateForObjectException();
        SecurityService.DoesNotHaveReadAccessForObjectException ex3 = new SecurityService.DoesNotHaveReadAccessForObjectException();
        SecurityService.DoesNotHaveFLSForEditException ex4 = new SecurityService.DoesNotHaveFLSForEditException();
        SecurityService.DoesNotHaveFLSForReadException ex5 = new SecurityService.DoesNotHaveFLSForReadException();
        SecurityService.DoesNotHaveFLSForCreateException ex6 = new SecurityService.DoesNotHaveFLSForCreateException();
        SecurityService.DoesNotHaveCreateAccessForObjectException ex7 = new SecurityService.DoesNotHaveCreateAccessForObjectException();
        test.stopTest();

        //Test each message for the label that should be tied to it
        System.assertEquals(
            System.Label.Does_Not_Have_Level_Of_Access_Required_Message,
            ex1.getMessage()
        );
        System.assertEquals(
            System.Label.Does_Not_Have_Update_Access_For_Object_Message,
            ex2.getMessage()
        );
        System.assertEquals(
            System.Label.Does_Not_Have_Read_Access_For_Object_Message,
            ex3.getMessage()
        );
        System.assertEquals(
            System.Label.Does_Not_Have_Edit_FLS_Access_Message,
            ex4.getMessage()
        );
        System.assertEquals(
            System.Label.Does_Not_Have_Read_FLS_Access_Message,
            ex5.getMessage()
        );
        System.assertEquals(
            System.Label.Does_Not_Have_Create_FLS_Access_Message,
            ex6.getMessage()
        );
        System.assertEquals(
            System.Label.Does_Not_Have_Create_Access_For_Object_Message,
            ex7.getMessage()
        );
    }
}
