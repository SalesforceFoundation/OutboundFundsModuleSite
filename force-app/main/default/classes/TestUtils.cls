@IsTest
public with sharing class TestUtils {
    public static final String TEST_USER_EMAIL = 'temptestuser@grants.example.com';

    public static Integer counter {
        get {
            if (counter == null) {
                counter = 0;
            }
            counter++;

            return counter;
        }
        set;
    }

    private static Integer MOCK_ID_INDEX = 0;

    /**
     * Generates a mocked Id that is guaranteed to be unique within a transaction.
     * @param  sObjectType In tests, you can pass in a SObjectType with Schema.[SObjectType Name].SObjectType.
     * @return             A single mocked Id of sObjectType guaranteed to be unique within a transaction.
     */
    public static Id mockId(Schema.DescribeSObjectResult describe) {
        return describe.getKeyPrefix() +
            String.valueOf(TestUtils.MOCK_ID_INDEX++).leftPad(12, '0');
    }

    /**
     * Generates a mocked Id that is guaranteed to be unique within a transaction.
     * @param  sObjectType In tests, you can pass in a describe with Schema.SObjectType.[SObjectType Name].
     * @return             A single mocked Id of sObjectType guaranteed to be unique within a transaction.
     */
    public static Id mockId(SObjectType sObjectType) {
        return TestUtils.mockId(sObjectType.getDescribe());
    }

    /**
     * Generates mocked Ids that are guaranteed to be unique within a transaction.
     * @param  describe In tests, you can pass in a describe with Schema.SObjectType.[SObjectType Name].
     * @param  size     Number of Ids to generate for this sObjectType
     * @return          List of mocked Ids of sObjectType guaranteed to be unique within a transaction.
     */
    public static List<Id> mockIds(Schema.DescribeSObjectResult describe, Integer size) {
        final List<Id> mockIds = new List<Id>();
        for (Integer i = 0; i < size; i++) {
            mockIds.add(TestUtils.mockId(describe));
        }
        return mockIds;
    }

    /**
     * Generates mocked Ids that are guaranteed to be unique within a transaction.
     * @param  sObjectType In tests, you can pass in a SObjectType with Schema.[SObjectType Name].SObjectType.
     * @param  size        Number of Ids to generate for this sObjectType
     * @return             List of mocked Ids of sObjectType guaranteed to be unique within a transaction.
     */
    public static List<Id> mockIds(SObjectType sObjectType, Integer size) {
        return TestUtils.mockIds(sObjectType.getDescribe(), size);
    }

    public static outfunds__Funding_Program__c createFundingProgram() {
        return createFundingPrograms(1)[0];
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

    public static String generateUniqueString() {
        String uniqueString =
            UserInfo.getOrganizationId() +
            DateTime.now().getTime() +
            Math.abs(Crypto.getRandomInteger());
        return uniqueString;
    }

    public static User createUser(String profileName, String userName) {
        // create user with no custom object permissions to test CRUD checks
        Profile p = [SELECT Id FROM Profile WHERE Name = :profileName];
        String uniqueUsername = (generateUniqueString() + '.' + userName).right(80);
        validateEmail(uniqueUsername);

        User user = new User(
            Alias = 'grantSkr',
            Email = userName,
            EmailEncodingKey = 'UTF-8',
            LastName = 'Testing',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Chicago',
            UserName = uniqueUsername
        );
        return user;
    }

    public static Account createAccount(String accountName) {
        if (String.isBlank(accountName)) {
            return null;
        }
        return new Account(Name = accountName);
    }

    public static Contact createContact(
        String firstName,
        String lastName,
        String accountId
    ) {
        if (String.isBlank(lastName) || string.isBlank(accountId)) {
            return null;
        }
        return new Contact(
            FirstName = firstName,
            LastName = lastName,
            accountId = accountId
        );
    }

    public static PermissionSet createCommunityUserPermissionSet() {
        PermissionSet permissionSet = new PermissionSet(
            Name = 'Test_Community_Permission_Set',
            Label = 'Test Community Permission Set'
        );
        insert permissionSet;

        List<ObjectPermissions> objectPermissions = new List<ObjectPermissions>();

        objectPermissions.add(
            new ObjectPermissions(
                ParentId = permissionSet.Id,
                SobjectType = 'outfunds__Funding_Program__c',
                PermissionsRead = true
            )
        );

        insert objectPermissions;
        return permissionSet;
    }

    public static EmailTemplate createTextEmailTemplate(String templateName) {
        EmailTemplate template = new EmailTemplate();
        template.isActive = true;
        template.Name = templateName;
        template.DeveloperName = templateName + generateUniqueString();
        template.TemplateType = 'text';
        template.FolderId = UserInfo.getUserId();
        template.Body = 'Test Body';
        return template;
    }

    public static outfunds__Funding_Request__c createFundingRequest(
        String name,
        String status,
        Id fundingProgramId,
        Id contactId
    ) {
        outfunds__Funding_Request__c request = new outfunds__Funding_Request__c(
            Name = name,
            outfunds__FundingProgram__c = fundingProgramId,
            outfunds__Status__c = status,
            outfunds__Applying_Contact__c = contactId
        );
        return request;
    }

    private static void validateEmail(String email) {
        // Simple email regex
        // Note: Current pattern does NOT work with top-level domains
        Pattern emailPattern = Pattern.compile('^[\\w\\.-]+@[\\w\\.-]+\\.\\w{2,4}$');
        Matcher patternMatcher = emailPattern.matcher(email);
        System.assert(patternMatcher.matches(), 'Received an invalid email format');
    }

    public static void assertUnexpectedExceptionThrown(
        Type expectedThrower,
        Type expectedExceptionType
    ) {
        System.assert(
            false,
            String.format(
                'Expected {0} to throw an exception of type {1}',
                new List<String>{
                    expectedThrower.getName(),
                    expectedExceptionType.getName()
                }
            )
        );
    }
}
