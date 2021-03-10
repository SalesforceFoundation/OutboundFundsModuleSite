public with sharing class SecurityService {
    public SecurityService() {
    }

    @TestVisible
    private Id runningUserId = UserInfo.getUserId();

    public enum CRUDAccessType {
        CREATEABLE,
        READABLE,
        UPDATEABLE,
        DELETEABLE
    }

    /**
     * Exceptions that are intended to make their way to the user
     * We override the getMessage to return our desired label.
     */

    public with sharing class DoesNotHaveLevelOfAccessForActionException extends SecurityServiceException {
        public override string getMessage() {
            return System.Label.Does_Not_Have_Level_Of_Access_Required_Message;
        }
    }
    public with sharing class DoesNotHaveUpdateForObjectException extends SecurityServiceException {
        public override string getMessage() {
            return System.Label.Does_Not_Have_Update_Access_For_Object_Message;
        }
    }
    public with sharing class DoesNotHaveReadAccessForObjectException extends SecurityServiceException {
        public override string getMessage() {
            return System.Label.Does_Not_Have_Read_Access_For_Object_Message;
        }
    }
    public with sharing class DoesNotHaveCreateAccessForObjectException extends SecurityServiceException {
        public override string getMessage() {
            return System.Label.Does_Not_Have_Create_Access_For_Object_Message;
        }
    }
    public with sharing class DoesNotHaveFLSForEditException extends SecurityServiceException {
        public override string getMessage() {
            return System.Label.Does_Not_Have_Edit_FLS_Access_Message;
        }
    }
    public with sharing class DoesNotHaveFLSForReadException extends SecurityServiceException {
        public override string getMessage() {
            return System.Label.Does_Not_Have_Read_FLS_Access_Message;
        }
    }
    public with sharing class DoesNotHaveFLSForCreateException extends SecurityServiceException {
        public override string getMessage() {
            return System.Label.Does_Not_Have_Create_FLS_Access_Message;
        }
    }

    public virtual with sharing class SecurityServiceException extends Exception {
    }

    /**
     * Exceptions specific to calling the service methods correctly
     */
    public with sharing class NoRecordsToCheckSecurityException extends Exception {
    }

    public with sharing class NoUserToCheckSecurityException extends Exception {
    }

    /////////////////////////////////////////////////////////////////////////////
    // These methods are for CRUD/FLS checks and access levels

    /**
     * verifyIsUpdateable
     * Verify if we have Update CRUD and FLS access to a specific record SObject
     * @param  record record description
     */
    public void verifyIsUpdateable(SObject record) {
        if (record == null) {
            throw new NoRecordsToCheckSecurityException();
        }
        SObjectType objectType = record.getSObjectType();
        // Check CRUD using permvalidator methods
        if (this.hasObjectAccess(objectType, CRUDAccessType.UPDATEABLE) == false) {
            System.debug(
                '||Grants|| - User does not have Update permission for object: ' +
                objectType
            );
            //TODO SWITCH OUT TEXT WITH LABEL
            throw new DoesNotHaveUpdateForObjectException();
        }
        Map<String, Object> fieldsToValues = record.getPopulatedFieldsAsMap();
        // Remember Id is never updateable (it's immutable) but is required for update.  Skip checking Id field is updateable.
        List<String> fieldsToVerify = new List<String>(fieldsToValues.keySet());
        String objectName = String.valueOf(objectType);
        Boolean isUpdateable = this.hasFLSAccessForFields(
            objectName,
            fieldsToVerify,
            'update'
        );
        if (isUpdateable == false) {
            System.debug(
                '||Grants|| - User does not have access to update fields for record: ' +
                record.get('Id')
            );
            //TODO SWITCH OUT WITH LABEL
            throw new DoesNotHaveFLSForEditException();
        }
    }

    /**
     * verifyIsUpdateable
     * Verify if we have Update CRUD and FLS access against a list of record SObjects
     * NOTE: This is 'All or Nothing' as in, as soon as it iterates on a record that is not updateable it throws an exception
     * @param  records
     */
    public void verifyIsUpdateable(List<SObject> records) {
        if (records == null) {
            throw new NoRecordsToCheckSecurityException();
        }
        for (SObject record : records) {
            this.verifyIsUpdateable(record);
        }
    }

    /**
     * verifyIsCreatable
     * Verify if we have Create CRUD and FLS access to a specific record SObject
     * @param  record record description
     */
    public void verifyIsCreateable(SObject record) {
        if (record == null) {
            throw new NoRecordsToCheckSecurityException();
        }
        SObjectType objectType = record.getSObjectType();
        // Check CRUD using permvalidator methods
        if (this.hasObjectAccess(objectType, CRUDAccessType.CREATEABLE) == false) {
            System.debug(
                '||Grants|| - User does not have Create permission for object: ' +
                objectType
            );
            //TODO SWITCH OUT TEXT WITH LABEL
            throw new DoesNotHaveCreateAccessForObjectException();
        }
        Map<String, Object> fieldsToValues = record.getPopulatedFieldsAsMap();
        // Remember Id is never updateable (it's immutable) but is required for update.  Skip checking Id field is updateable.
        List<String> fieldsToVerify = new List<String>(fieldsToValues.keySet());
        String objectName = String.valueOf(objectType);
        Boolean isCreateable = this.hasFLSAccessForFields(
            objectName,
            fieldsToVerify,
            'insert'
        );
        if (isCreateable == false) {
            System.debug(
                '||Grants|| - User does not have access to update fields for record: ' +
                record.get('Id')
            );
            //TODO SWITCH OUT WITH LABEL
            throw new DoesNotHaveFLSForCreateException();
        }
    }

    /**
     * verifyIsCreateable
     * Verify if we have Create CRUD and FLS access against a list of record SObjects
     * NOTE: This is 'All or Nothing' as in, as soon as it iterates on a record that is not updateable it throws an exception
     * @param  records
     */
    public void verifyIsCreateable(List<SObject> records) {
        if (records == null) {
            throw new NoRecordsToCheckSecurityException();
        }
        for (SObject record : records) {
            this.verifyIsCreateable(record);
        }
    }

    /**
     * hasFLSAccessForFields Returns true/false if given a list of fields, and what type of operation ('update')
     * TODO - switch strings with enum or constants
     */
    public Boolean hasFLSAccessForFields(
        String objectName,
        List<String> fields,
        String operation
    ) {
        try {
            Schema.DescribeSobjectResult[] results = Schema.describeSObjects(
                new List<String>{ objectName }
            );
            Map<String, Schema.SObjectField> fieldsMap = results[0].fields.getMap();
            if (operation == 'insert') {
                for (String fieldName : fields) {
                    if (!fieldsMap.get(fieldName).getDescribe().isCreateable()) {
                        return false;
                    }
                }
            }
            if (operation == 'update') {
                for (String fieldName : fields) {
                    if (fieldName.equalsIgnoreCase('Id')) {
                        continue;
                    }

                    if (!fieldsMap.get(fieldName).getDescribe().isUpdateable()) {
                        return false;
                    }
                }
            }
            if (operation == 'upsert') {
                for (String fieldName : fields) {
                    if (
                        !fieldsMap.get(fieldName).getDescribe().isCreateable() ||
                        !fieldsMap.get(fieldName).getDescribe().isUpdateable()
                    ) {
                        return false;
                    }
                }
            }
            if (operation == 'read') {
                for (String fieldName : fields) {
                    if (!hasFieldReadAccess(fieldsMap.get(fieldName).getDescribe())) {
                        return false;
                    }
                }
            }
            return true;
        } catch (Exception e) {
            return false;
        }
    }

    /**
     * hasFieldReadAccess Checks for read access on a specific field
     * @param  field The describeFieldResult we will use to determine if there is read access
     * @return       return Boolean
     */
    public Boolean hasFieldReadAccess(DescribeFieldResult field) {
        return field.isAccessible();
    }

    /**
     * getAccessibleFields Returns the accessible fields from a set of DescribeFieldResult
     * @param  fields The set of DescribeFieldResults we will use to determine which have read access
     * @return        return A set of DescribeFieldResults with fields removed that do not have read access
     */
    public Set<DescribeFieldResult> getAccessibleFields(Set<DescribeFieldResult> fields) {
        for (DescribeFieldResult field : fields) {
            if (!hasFieldReadAccess(field)) {
                fields.remove(field);
            }
        }

        return fields;
    }

    /**
     * hasObjectAccess Gives us a true/false for the given AccessType for an SObjectType
     * @param  sObjectType sObjectType The SObjectType (i.e. Schema.SObjectType.Contact) we want to check access against
     * @param  accessType  accessType The enum value for which CRUD accesstype we want to check access
     * @return             return Boolean
     */
    public Boolean hasObjectAccess(SObjectType sObjectType, CRUDAccessType accessType) {
        if (sObjectType == null) {
            return false;
        }

        switch on accessType {
            when CREATEABLE {
                return sObjectType.getDescribe().isCreateable();
            }
            when READABLE {
                return sObjectType.getDescribe().isAccessible();
            }
            when UPDATEABLE {
                return sObjectType.getDescribe().isUpdateable();
            }
            when DELETEABLE {
                return sObjectType.getDescribe().isDeletable();
            }
            when else {
                return false;
            }
        }
    }

    /////////////////////////////////////////////////////////////////////////////
    // Methods below are for getting and accessing the UserRecordAccess object
    // UserRecordAccess is an object that gives us an easy way to verify sharing AND crud for a specific record.

    /**
     * getUserRecordAccess returns single user record access with userId provided
     * @param  recordId recordId description
     * @return          return description
     */
    public UserRecordAccess getUserRecordAccess(Id userId, Id recordId) {
        Map<Id, UserRecordAccess> recordToAccess = this.getRecordsAccessForUser(
            userId,
            new Set<Id>{ recordId }
        );
        return recordToAccess.get(recordId);
    }

    /**
     * getUserRecordAccess SINGLE get user record access without providing userid (for running user)
     * @param  recordId recordId description
     * @return          return description
     */
    public UserRecordAccess getUserRecordAccess(Id recordId) {
        return this.getUserRecordAccess(this.runningUserId, recordId);
    }

    /**
     * getHasTransferAccess 'All Or Nothing' check for HasTransferRecord access against a set of Ids
     * NOTE: This uses the UserRecordAccess object which is used to check access against specified records and includes sharing access
     * @param  recordIds recordIds Set of Ids for the records we want to check access against
     * @return           return Map<Id,Boolean> = {recordId => true}
     */
    public Map<Id, Boolean> getHasTransferAccess(Set<Id> recordIds) {
        Map<Id, Boolean> recordToTransferAccess = new Map<Id, Boolean>();

        for (UserRecordAccess access : this.getRecordsAccessForUser(recordIds).values()) {
            recordToTransferAccess.put(access.RecordId, access.HasTransferAccess);
        }
        return recordToTransferAccess;
    }

    /**
     * getHasReadAccess 'All Or Nothing' check for HasReadAccess access against a set of Ids
     * NOTE: This uses the UserRecordAccess object which is used to check access against specified records and includes sharing access
     * @param  recordIds recordIds Set of Ids for the records we want to check access against
     * @return           return Map<Id,Boolean> = {recordId => true}
     */
    public Map<Id, Boolean> getHasReadAccess(Set<Id> recordIds) {
        Map<Id, Boolean> recordToReadAccess = new Map<Id, Boolean>();

        for (UserRecordAccess access : this.getRecordsAccessForUser(recordIds).values()) {
            recordToReadAccess.put(access.RecordId, access.HasReadAccess);
        }
        return recordToReadAccess;
    }

    /**
     * getRecordsAccessForUser Queries for the UserRecordAccess records for the specified records and userId
     * Note - this one is public so as to be potentially used in other services who may need more complex record access check
     * @param  userId  userId The Id of the User we need to get the Access for
     * @param  records records The set of Ids for the Records we need to get level of access
     * @return         return Map<Id, UserRecordAccess> = {recordId, UserRecordAccess{}}
     */
    public Map<Id, UserRecordAccess> getRecordsAccessForUser(Id userId, Set<Id> records) {
        if (records == null) {
            throw new NoRecordsToCheckSecurityException();
        }
        Map<ID, UserRecordAccess> recordAccess = new Map<ID, UserRecordAccess>();
        for (UserRecordAccess accessRecord : [
            SELECT
                RecordId,
                HasReadAccess,
                HasDeleteAccess,
                HasEditAccess,
                HasTransferAccess,
                MaxAccessLevel
            FROM UserRecordAccess
            WHERE UserId = :userId AND RecordId IN :records
        ]) {
            recordAccess.put(accessRecord.recordId, accessRecord);
        }

        return recordAccess;
    }

    /**
     * getRecordsAccessForUser Queries for the UserRecordAccess records for the specified records and the userId of the running user
     * @param  records records The set of Ids for the Records we need to get level of access
     * @return         return Map<Id, UserRecordAccess> = {recordId, UserRecordAccess{}}
     */
    @TestVisible
    private Map<Id, UserRecordAccess> getRecordsAccessForUser(Set<Id> records) {
        return this.getRecordsAccessForUser(this.runningUserId, records);
    }
}
