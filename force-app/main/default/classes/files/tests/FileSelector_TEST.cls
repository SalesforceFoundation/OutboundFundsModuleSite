@IsTest
public with sharing class FileSelector_TEST {
    final static string COMMUNITY_USER_EMAIL = 'communitytestuser@salesforce.org';
    final static string ADMIN_USER_EMAIL = 'admintestuser@salesforce.org';

    @TestSetup
    private static void createTestData() {
        UserRole testRole = new UserRole(Name = 'TestRole');
        insert testRole;

        User adminWithRole = TestUtils.createUser(
            'System Administrator',
            ADMIN_USER_EMAIL
        );

        adminWithRole.UserRoleId = testRole.Id;
        insert adminWithRole;

        System.runAs(adminWithRole) {
            Account portalAccount = TestUtils.createAccount('Portal Account');
            insert portalAccount;

            Contact communityContact = TestUtils.createContact(
                'Devon',
                'Berger',
                portalAccount.Id
            );
            insert communityContact;

            User communityUser = TestUtils.createUser(
                'Customer Community Plus User',
                COMMUNITY_USER_EMAIL
            );
            communityUser.ContactId = communityContact.Id;
            insert communityUser;

            PermissionSet communityPermissionSet = TestUtils.createCommunityUserPermissionSet();
            PermissionSetAssignment communityPermissionSetAssignment = new PermissionSetAssignment(
                PermissionSetId = communityPermissionSet.Id,
                AssigneeId = communityUser.Id
            );
            insert communityPermissionSetAssignment;
        }
    }

    public static void createFundingProgramShares(Id userId) {
        String accessLevel = 'Read';
        String fundingProgramShareObject = 'outfunds__Funding_Program__Share';

        // OWD ReadWrite
        Map<String, Schema.SObjectType> globalDescribeMap = Schema.getGlobalDescribe();
        if (!globalDescribeMap.containsKey(fundingProgramShareObject)) {
            return;
        }

        // Funding programs are already shared by a platform mechanism
        List<outfunds__Funding_Program__c> fundingPrograms = [
            SELECT Id
            FROM outfunds__Funding_Program__c
        ];
        if (fundingPrograms.size() == 0) {
            return;
        }

        UserRecordAccess userAccess = [
            SELECT RecordID, HasReadAccess
            FROM UserRecordAccess
            WHERE UserId = :userId AND RecordId = :fundingPrograms[0].Id
        ];
        if (userAccess.HasReadAccess) {
            return;
        }

        // Programs not shared via another mechanism. Create shares
        List<SObject> insertFundingProgramShares = new List<SObject>();
        for (outfunds__Funding_Program__c fundingProgram : [
            SELECT Id
            FROM outfunds__Funding_Program__c
        ]) {
            sObject programShare = Schema.getGlobalDescribe()
                .get(fundingProgramShareObject)
                .newSObject();
            programShare.put('AccessLevel', accessLevel);
            programShare.put('ParentID', fundingProgram.Id);
            programShare.put('RowCause', 'Manual');
            programShare.put('UserOrGroupId', userId);
            insertFundingProgramShares.add(programShare);
        }

        insert insertFundingProgramShares;
    }

    @IsTest
    private static void testContentDocumentLinkByRecordIdsAsCommunityUser() {
        Integer numberOfPrograms = 1;
        Integer numberOfFiles = 3;

        User communityUser = [SELECT Id FROM User WHERE Email = :COMMUNITY_USER_EMAIL];

        outfunds__Funding_Program__c program = TestUtils.createFundingProgram();
        insert program;

        createFundingProgramShares(communityUser.Id);

        TestUtils.createContentDocumentsWithLink(program.Id, 'AllUsers', numberOfFiles);

        List<ContentDocumentLink> actualContentDocumentLinks = new List<ContentDocumentLink>();

        Test.startTest();

        System.runAs(communityUser) {
            FileSelector selector = new FileSelector();
            actualContentDocumentLinks = selector.contentDocumentLinkByRecordIds(
                new Set<Id>{ program.Id }
            );
        }

        Test.stopTest();

        System.assertEquals(
            numberOfFiles,
            actualContentDocumentLinks.size(),
            'Expected ' +
            numberOfFiles +
            ' files associated with program'
        );
    }

    @IsTest
    private static void testContentDocumentsByIdsAsCommunityUser() {
        Integer numberOfPrograms = 1;
        Integer numberOfFiles = 3;

        User communityUser = [SELECT Id FROM User WHERE Email = :COMMUNITY_USER_EMAIL];

        outfunds__Funding_Program__c program = TestUtils.createFundingProgram();
        insert program;

        createFundingProgramShares(communityUser.Id);

        TestUtils.createContentDocumentsWithLink(program.Id, 'AllUsers', numberOfFiles);

        List<ContentDocument> actualContentDocuments = new List<ContentDocument>();
        Set<Id> actualContentDocumentIds = new Set<Id>();

        Test.startTest();

        System.runAs(communityUser) {
            FileSelector selector = new FileSelector();

            Set<Id> contentDocumentIds = getContentDocumentIds(program.Id);

            actualContentDocuments = selector.contentDocumentsByIds(contentDocumentIds);

            for (ContentDocument cd : actualContentDocuments) {
                actualContentDocumentIds.add(cd.Id);
            }
        }

        Test.stopTest();

        System.assertEquals(
            numberOfFiles,
            actualContentDocuments.size(),
            'Expected ' +
            numberOfFiles +
            ' ContentDocument records'
        );

        for (ContentDocumentLink contentDocumentLink : [
            SELECT Id, ContentDocumentId, Visibility
            FROM ContentDocumentLink
            WHERE Visibility = 'AllUsers' AND LinkedEntityId = :program.Id
        ]) {
            System.assert(
                actualContentDocumentIds.contains(contentDocumentLink.ContentDocumentId),
                'Expected ContentDocument Id not found in community user ContentDocument list'
            );
        }
    }

    @IsTest
    private static void testContentDocumentLinkByRecordIdsAsCommunityUserWithoutExplicitRecordShare() {
        Integer numberOfPrograms = 1;
        Integer numberOfFiles = 3;
        Integer countVisibleFundingPrograms = 0; // Funding Programs may be shared by platform mechanism (OWD)

        User communityUser = [SELECT Id FROM User WHERE Email = :COMMUNITY_USER_EMAIL];

        outfunds__Funding_Program__c program = TestUtils.createFundingProgram();
        insert program;

        TestUtils.createContentDocumentsWithLink(program.Id, 'AllUsers', numberOfFiles);

        List<ContentDocumentLink> actualContentDocumentLinks = new List<ContentDocumentLink>();
        Test.startTest();

        System.runAs(communityUser) {
            countVisibleFundingPrograms = [
                SELECT COUNT()
                FROM outfunds__Funding_Program__c
            ];

            FileSelector selector = new FileSelector();
            actualContentDocumentLinks = selector.contentDocumentLinkByRecordIds(
                new Set<Id>{ program.Id }
            );
        }

        Test.stopTest();

        Integer countExpectedFiles = countVisibleFundingPrograms * numberOfFiles;
        System.assertEquals(
            countExpectedFiles,
            actualContentDocumentLinks.size(),
            'Expected ' +
            countExpectedFiles +
            ' files associated with program'
        );
    }

    @IsTest
    private static void testContentDocumentsByIdsAsCommunityUserWithoutExplicitRecordShare() {
        Integer numberOfPrograms = 1;
        Integer numberOfFiles = 3;
        Integer countVisibleFundingPrograms = 0; // Funding Programs may be shared by platform mechanism (OWD)

        User communityUser = [SELECT Id FROM User WHERE Email = :COMMUNITY_USER_EMAIL];

        outfunds__Funding_Program__c program = TestUtils.createFundingProgram();
        insert program;

        TestUtils.createContentDocumentsWithLink(program.Id, 'AllUsers', numberOfFiles);
        Map<Id, ContentDocument> contentDocumentMap = new Map<Id, ContentDocument>(
            [SELECT Id FROM ContentDocument]
        );

        List<ContentDocument> actualContentDocuments = new List<ContentDocument>();

        Test.startTest();

        System.runAs(communityUser) {
            countVisibleFundingPrograms = [
                SELECT COUNT()
                FROM outfunds__Funding_Program__c
            ];

            FileSelector selector = new FileSelector();
            actualContentDocuments = selector.contentDocumentsByIds(
                contentDocumentMap.keyset()
            );
        }

        Test.stopTest();

        Integer countExpectedFiles = countVisibleFundingPrograms * numberOfFiles;
        System.assertEquals(
            countExpectedFiles,
            actualContentDocuments.size(),
            'Expected ' +
            countExpectedFiles +
            ' ContentDocument records'
        );
    }

    @IsTest
    private static void testContentDocumentsByIdsMixedUserShares() {
        Integer numberOfPrograms = 1;
        Integer numberOfFiles = 3;
        Integer expectedFilesFromShares = 2;

        User communityUser = [SELECT Id FROM User WHERE Email = :COMMUNITY_USER_EMAIL];
        User adminUser = [SELECT Id FROM User WHERE Email = :ADMIN_USER_EMAIL];

        outfunds__Funding_Program__c program = TestUtils.createFundingProgram();
        insert program;

        createFundingProgramShares(communityUser.Id);

        TestUtils.createContentDocumentsWithLink(
            program.Id,
            'AllUsers',
            expectedFilesFromShares
        );
        TestUtils.createContentDocumentsWithLink(
            program.Id,
            'InternalUsers',
            numberOfFiles - expectedFilesFromShares
        );

        List<ContentDocument> actualContentDocumentsCommunityUser = new List<ContentDocument>();
        List<ContentDocument> actualContentDocumentsAdminUser = new List<ContentDocument>();

        Test.startTest();

        System.runAs(communityUser) {
            FileSelector selector = new FileSelector();

            Set<Id> contentDocumentIds = getContentDocumentIds(program.Id);

            actualContentDocumentsCommunityUser = selector.contentDocumentsByIds(
                contentDocumentIds
            );
        }

        System.runAs(adminUser) {
            FileSelector selector = new FileSelector();

            Set<Id> contentDocumentIds = getContentDocumentIds(program.Id);

            actualContentDocumentsAdminUser = selector.contentDocumentsByIds(
                contentDocumentIds
            );
        }

        Test.stopTest();

        System.assertEquals(
            expectedFilesFromShares,
            actualContentDocumentsCommunityUser.size(),
            'Expected ' +
            expectedFilesFromShares +
            ' ContentDocument records for the Community User'
        );

        System.assertEquals(
            numberOfFiles,
            actualContentDocumentsAdminUser.size(),
            'Expected ' +
            numberOfFiles +
            ' ContentDocument records for the Admin user'
        );
    }

    @IsTest
    private static void testContentDocumentSharingPrivacy() {
        Integer numberOfPrograms = 1;
        Integer numberOfFiles = 3;
        Integer expectedFilesFromShares = 2;

        User communityUser = [SELECT Id FROM User WHERE Email = :COMMUNITY_USER_EMAIL];
        User adminUser = [SELECT Id FROM User WHERE Email = :ADMIN_USER_EMAIL];

        outfunds__Funding_Program__c program = TestUtils.createFundingProgram();
        insert program;

        createFundingProgramShares(communityUser.Id);

        TestUtils.createContentDocumentsWithLink(program.Id, 'AllUsers', numberOfFiles);

        ContentDocument privateDocument = [
            SELECT Id, SharingPrivacy
            FROM ContentDocument
            LIMIT 1
        ];
        privateDocument.SharingPrivacy = 'P';
        update privateDocument;

        List<ContentDocument> actualContentDocumentsCommunityUser = new List<ContentDocument>();

        Test.startTest();

        System.runAs(communityUser) {
            FileSelector selector = new FileSelector();
            Set<Id> contentDocumentIds = getContentDocumentIds(program.Id);
            actualContentDocumentsCommunityUser = selector.contentDocumentsByIds(
                contentDocumentIds
            );
        }

        Test.stopTest();

        System.assertEquals(
            expectedFilesFromShares,
            actualContentDocumentsCommunityUser.size(),
            'Expected ' +
            expectedFilesFromShares +
            ' files returned to the community user.'
        );
    }

    private static Set<Id> getContentDocumentIds(Id programId) {
        FileSelector selector = new FileSelector();
        List<ContentDocumentLink> contentDocumentLinks = selector.contentDocumentLinkByRecordIds(
            new Set<Id>{ programId }
        );

        Set<Id> contentDocumentIds = new Set<Id>();
        for (ContentDocumentLink communityContentDocumentLink : contentDocumentLinks) {
            contentDocumentIds.add(communityContentDocumentLink.ContentDocumentId);
        }

        return contentDocumentIds;
    }
}
