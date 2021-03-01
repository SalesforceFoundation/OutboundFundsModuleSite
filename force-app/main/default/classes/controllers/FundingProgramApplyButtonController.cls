public with sharing class FundingProgramApplyButtonController {
    /**
     * @description Retrieve Application form's API Name
     * @return      String
     */
    @AuraEnabled(cacheable=true)
    public static String getFundingProgramApplicationFormApiName() {
        if (!Schema.SObjectType.outfunds__Funding_Program__c.isAccessible()) {
            System.AuraHandledException auraHandledException = new AuraHandledException(
                System.Label.Does_Not_Have_Read_Access_For_Object_Message
            );
            auraHandledException.setMessage(
                System.Label.Does_Not_Have_Read_Access_For_Object_Message
            );
            throw auraHandledException;
        }
        if (
            !Schema.SObjectType.outfunds__Funding_Program__c.fields.ApplicationForm__c.isAccessible()
        ) {
            System.AuraHandledException auraHandledException = new AuraHandledException(
                System.Label.Does_Not_Have_Read_FLS_Access_Message
            );
            auraHandledException.setMessage(
                System.Label.Does_Not_Have_Read_FLS_Access_Message
            );
            throw auraHandledException;
        }

        return Schema.SObjectType.outfunds__Funding_Program__c.fields.ApplicationForm__c.getName();
    }
}
