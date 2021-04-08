/*
 * Copyright (c) 2021, salesforce.com, inc.
 * All rights reserved.
 * SPDX-License-Identifier: BSD-3-Clause
 * For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/BSD-3-Clause
 */
@IsTest
public with sharing class FileSelector_TEST {
    private static TestUser.BusinessFundseekerPersona businessFundSeekerPersona = new TestUser.BusinessFundseekerPersona();

    @TestSetup
    private static void createTestData() {
        TestUser.insertPersonasInTestSetup(
            new List<TestUser.Persona>{ FileSelector_TEST.businessFundSeekerPersona }
        );
    }

    public static List<outfunds__Funding_Program__c> createFundingPrograms(
        Integer count
    ) {
        List<outfunds__Funding_Program__c> programs = new List<outfunds__Funding_Program__c>();

        for (Integer i = 0; i < count; i++) {
            outfunds__Funding_Program__c program = new outfunds__Funding_Program__c(
                Name = 'Test Program ' + String.valueOf(count)
            );
            programs.add(program);
        }

        return programs;
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

    public static List<ContentDocumentLink> createContentDocumentsWithLink(
        Id recordId,
        String visibility,
        Integer count
    ) {
        List<ContentDocumentLink> contentDocumentLinks = new List<ContentDocumentLink>();
        List<ContentDocument> contentDocuments = createContentDocuments(count);
        for (ContentDocument cd : contentDocuments) {
            ContentDocumentLink cdl = new ContentDocumentLink(
                ContentDocumentId = cd.Id,
                LinkedEntityId = recordId,
                Visibility = visibility
            );
            contentDocumentLinks.add(cdl);
        }

        insert contentDocumentLinks;
        return contentDocumentLinks;
    }

    public static List<ContentDocument> createContentDocuments(Integer count) {
        // Content Documents cannot be inserted directly.
        // They are created on insertion of ContentVersions
        List<ContentVersion> cvs = new List<ContentVersion>();

        for (Integer i = 0; i < count; i++) {
            ContentVersion cv = new ContentVersion(
                Title = 'Test File ' + String.valueOf(i),
                PathOnClient = 'TestFile' + String.valueOf(i) + '.txt',
                VersionData = Blob.valueOf('Test Text File'),
                IsMajorVersion = true
            );
            cvs.add(cv);
        }
        insert cvs;

        List<Id> contentIds = new List<Id>();
        List<Id> contentVersionIds = new List<Id>();
        for (ContentVersion cv : cvs) {
            contentVersionIds.add(cv.Id);
        }

        for (ContentVersion cv : [
            SELECT Id, ContentDocumentId
            FROM ContentVersion
            WHERE Id IN :contentVersionIds
        ]) {
            contentIds.add(cv.ContentDocumentId);
        }

        return [SELECT Id, Title FROM ContentDocument WHERE Id IN :contentIds];
    }

    private static void validateEmail(String email) {
        // Simple email regex
        // Note: Current pattern does NOT work with top-level domains
        Pattern emailPattern = Pattern.compile('^[\\w\\.-]+@[\\w\\.-]+\\.\\w{2,4}$');
        Matcher patternMatcher = emailPattern.matcher(email);
        System.assert(patternMatcher.matches(), 'Received an invalid email format');
    }

    public static String generateUniqueString() {
        String uniqueString =
            UserInfo.getOrganizationId() +
            DateTime.now().getTime() +
            Math.abs(Crypto.getRandomInteger());
        return uniqueString;
    }

    @IsTest
    private static void testgetContentDocumentLinksByRecordIdsAsCommunityUser() {
        Integer numberOfPrograms = 1;
        Integer numberOfFiles = 3;

        FileSelector_TEST.businessFundSeekerPersona.load();

        outfunds__Funding_Program__c program = createFundingPrograms(1)[0];
        insert program;

        createFundingProgramShares(
            FileSelector_TEST.businessFundSeekerPersona.getUser().Id
        );

        createContentDocumentsWithLink(program.Id, 'AllUsers', numberOfFiles);

        List<ContentDocumentLink> actualContentDocumentLinks = new List<ContentDocumentLink>();

        Test.startTest();

        System.runAs(FileSelector_TEST.businessFundSeekerPersona.getUser()) {
            FileSelector selector = new FileSelector();
            actualContentDocumentLinks = selector.getContentDocumentLinksByRecordIds(
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

        FileSelector_TEST.businessFundSeekerPersona.load();

        outfunds__Funding_Program__c program = createFundingPrograms(1)[0];
        insert program;

        createFundingProgramShares(
            FileSelector_TEST.businessFundSeekerPersona.getUser().Id
        );

        createContentDocumentsWithLink(program.Id, 'AllUsers', numberOfFiles);

        List<ContentDocument> actualContentDocuments = new List<ContentDocument>();
        Set<Id> actualContentDocumentIds = new Set<Id>();

        Test.startTest();

        System.runAs(FileSelector_TEST.businessFundSeekerPersona.getUser()) {
            FileSelector selector = new FileSelector();

            Set<Id> contentDocumentIds = getContentDocumentIds(program.Id);

            actualContentDocuments = selector.getContentDocumentsByIds(
                contentDocumentIds
            );

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
    private static void testgetContentDocumentLinksByRecordIdsAsCommunityUserWithoutExplicitRecordShare() {
        Integer numberOfPrograms = 1;
        Integer numberOfFiles = 3;
        Integer countVisibleFundingPrograms = 0; // Funding Programs may be shared by platform mechanism (OWD)

        FileSelector_TEST.businessFundSeekerPersona.load();

        outfunds__Funding_Program__c program = createFundingPrograms(1)[0];
        insert program;

        createContentDocumentsWithLink(program.Id, 'AllUsers', numberOfFiles);

        List<ContentDocumentLink> actualContentDocumentLinks = new List<ContentDocumentLink>();
        Test.startTest();

        System.runAs(FileSelector_TEST.businessFundSeekerPersona.getUser()) {
            countVisibleFundingPrograms = [
                SELECT COUNT()
                FROM outfunds__Funding_Program__c
            ];

            FileSelector selector = new FileSelector();
            actualContentDocumentLinks = selector.getContentDocumentLinksByRecordIds(
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

        FileSelector_TEST.businessFundSeekerPersona.load();

        outfunds__Funding_Program__c program = createFundingPrograms(1)[0];
        insert program;

        createContentDocumentsWithLink(program.Id, 'AllUsers', numberOfFiles);
        Map<Id, ContentDocument> contentDocumentMap = new Map<Id, ContentDocument>(
            [SELECT Id FROM ContentDocument]
        );

        List<ContentDocument> actualContentDocuments = new List<ContentDocument>();

        Test.startTest();

        System.runAs(FileSelector_TEST.businessFundSeekerPersona.getUser()) {
            countVisibleFundingPrograms = [
                SELECT COUNT()
                FROM outfunds__Funding_Program__c
            ];

            FileSelector selector = new FileSelector();
            actualContentDocuments = selector.getContentDocumentsByIds(
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

        FileSelector_TEST.businessFundSeekerPersona.load();

        outfunds__Funding_Program__c program = createFundingPrograms(1)[0];
        insert program;

        createFundingProgramShares(
            FileSelector_TEST.businessFundSeekerPersona.getUser().Id
        );

        createContentDocumentsWithLink(program.Id, 'AllUsers', expectedFilesFromShares);
        createContentDocumentsWithLink(
            program.Id,
            'InternalUsers',
            numberOfFiles - expectedFilesFromShares
        );

        List<ContentDocument> actualContentDocumentsCommunityUser = new List<ContentDocument>();
        List<ContentDocument> actualContentDocumentsAdminUser = new List<ContentDocument>();

        Test.startTest();

        System.runAs(FileSelector_TEST.businessFundSeekerPersona.getUser()) {
            FileSelector selector = new FileSelector();

            Set<Id> contentDocumentIds = getContentDocumentIds(program.Id);

            actualContentDocumentsCommunityUser = selector.getContentDocumentsByIds(
                contentDocumentIds
            );
        }

        // Run as administrator
        FileSelector selector = new FileSelector();

        Set<Id> contentDocumentIds = getContentDocumentIds(program.Id);

        actualContentDocumentsAdminUser = selector.getContentDocumentsByIds(
            contentDocumentIds
        );

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

        FileSelector_TEST.businessFundSeekerPersona.load();

        outfunds__Funding_Program__c program = createFundingPrograms(1)[0];
        insert program;

        createFundingProgramShares(
            FileSelector_TEST.businessFundSeekerPersona.getUser().Id
        );

        createContentDocumentsWithLink(program.Id, 'AllUsers', numberOfFiles);

        ContentDocument privateDocument = [
            SELECT Id, SharingPrivacy
            FROM ContentDocument
            LIMIT 1
        ];
        privateDocument.SharingPrivacy = 'P';
        update privateDocument;

        List<ContentDocument> actualContentDocumentsCommunityUser = new List<ContentDocument>();

        Test.startTest();

        System.runAs(FileSelector_TEST.businessFundSeekerPersona.getUser()) {
            FileSelector selector = new FileSelector();
            Set<Id> contentDocumentIds = getContentDocumentIds(program.Id);
            actualContentDocumentsCommunityUser = selector.getContentDocumentsByIds(
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
        List<ContentDocumentLink> contentDocumentLinks = selector.getContentDocumentLinksByRecordIds(
            new Set<Id>{ programId }
        );

        Set<Id> contentDocumentIds = new Set<Id>();
        for (ContentDocumentLink communityContentDocumentLink : contentDocumentLinks) {
            contentDocumentIds.add(communityContentDocumentLink.ContentDocumentId);
        }

        return contentDocumentIds;
    }
}
