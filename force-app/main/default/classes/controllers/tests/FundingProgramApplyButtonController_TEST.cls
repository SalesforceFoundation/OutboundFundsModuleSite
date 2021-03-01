@IsTest
public with sharing class FundingProgramApplyButtonController_TEST {
    public static final TestUser.MinimalAccessPersona minimalAccessPersona = new TestUser.MinimalAccessPersona();

    @TestSetup
    public static void testSetup() {
        TestUser.insertPersonasInTestSetup(
            new List<TestUser.Persona>{ minimalAccessPersona }
        );
    }

    @IsTest
    private static void shouldThrowAuraExceptionIfNoREADObjectAccess() {
        FundingProgramApplyButtonController_TEST.minimalAccessPersona.load();

        final TestUser.PermissionSetManager permissionSet = FundingProgramApplyButtonController_TEST.minimalAccessPersona.getPermissionSetManager();

        final TestUser.ObjectPermission fundingProgramPermission = permissionSet.getObjectPermission(
            Schema.SobjectType.outfunds__Funding_Program__c
        );

        // Set permissions for this test.
        System.assertEquals(
            false,
            fundingProgramPermission.getRead(),
            'Funding Program should default to not be accessible.'
        );

        permissionSet.save();

        Test.startTest();

        Exception actualException;
        System.runAs(FundingProgramApplyButtonController_TEST.minimalAccessPersona.getUser()) {
            try {
                String applicationFormApiName = FundingProgramApplyButtonController.getFundingProgramApplicationFormApiName();
            } catch (AuraHandledException auraException) {
                actualException = auraException;
            } catch (Exception ex) {
                System.assert(
                    false,
                    String.format(
                        'A {0} should have been thrown, but a {1} was thrown instead.',
                        new List<String>{
                            AuraHandledException.class.getName(),
                            ex.getTypeName()
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
            AuraHandledException.class.getName() +
            ' to be thrown.'
        );
        System.assertEquals(
            System.Label.Does_Not_Have_Read_Access_For_Object_Message,
            actualException.getMessage(),
            'Expected message not thrown in the exception.'
        );
    }

    @IsTest
    private static void shouldThrowAuraExceptionIfNoREADAccessOnApplicationFormField() {
        FundingProgramApplyButtonController_TEST.minimalAccessPersona.load();

        final TestUser.PermissionSetManager permissionSet = FundingProgramApplyButtonController_TEST.minimalAccessPersona.getPermissionSetManager();

        final TestUser.ObjectPermission fundingProgramPermission = permissionSet.getObjectPermission(
            Schema.SobjectType.outfunds__Funding_Program__c
        );

        // Set object access to Funding Program to READ
        fundingProgramPermission.setRead(true);
        final TestUser.FieldPermission applicationFormPermission = fundingProgramPermission.getFieldPermission(
            Schema.outfunds__Funding_Program__c.fields.ApplicationForm__c.getDescribe()
        );

        applicationFormPermission.setRead(false);
        permissionSet.save();

        Test.startTest();

        Exception actualException;
        System.runAs(FundingProgramApplyButtonController_TEST.minimalAccessPersona.getUser()) {
            try {
                String applicationFormApiName = FundingProgramApplyButtonController.getFundingProgramApplicationFormApiName();
            } catch (AuraHandledException auraException) {
                actualException = auraException;
            } catch (Exception ex) {
                System.assert(
                    false,
                    String.format(
                        'A {0} should have been thrown, but a {1} was thrown instead.',
                        new List<String>{
                            AuraHandledException.class.getName(),
                            ex.getTypeName()
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
            AuraHandledException.class.getName() +
            ' to be thrown.'
        );
        System.assertEquals(
            System.Label.Does_Not_Have_Read_FLS_Access_Message,
            actualException.getMessage(),
            'Expected message not thrown in the exception.'
        );
    }

    @IsTest
    private static void shouldReturnApplicationFormName() {
        String applicationFormName = Schema.SObjectType.outfunds__Funding_Program__c.fields.ApplicationForm__c.getName();
        FundingProgramApplyButtonController_TEST.minimalAccessPersona.load();

        final TestUser.PermissionSetManager permissionSet = FundingProgramApplyButtonController_TEST.minimalAccessPersona.getPermissionSetManager();

        final TestUser.ObjectPermission fundingProgramPermission = permissionSet.getObjectPermission(
            Schema.SobjectType.outfunds__Funding_Program__c
        );

        // Set permissions for this test.
        fundingProgramPermission.setRead(true);
        final TestUser.FieldPermission applicationFormPermission = fundingProgramPermission.getFieldPermission(
            Schema.outfunds__Funding_Program__c.fields.ApplicationForm__c.getDescribe()
        );
        applicationFormPermission.setRead(true);

        permissionSet.save();

        Test.startTest();

        Exception actualException;
        String applicationFormApiName;
        System.runAs(FundingProgramApplyButtonController_TEST.minimalAccessPersona.getUser()) {
            try {
                applicationFormApiName = FundingProgramApplyButtonController.getFundingProgramApplicationFormApiName();
            } catch (Exception ex) {
                actualException = ex;
            }
        }
        Test.stopTest();

        System.assertEquals(
            null,
            actualException,
            'Expecting no exception to be thrown.'
        );
        System.assertEquals(applicationFormName, applicationFormAPIName);
    }
}
