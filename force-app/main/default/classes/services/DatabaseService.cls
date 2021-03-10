public with sharing class DatabaseService {
    @TestVisible
    private SecurityService securityService = new SecurityService();

    public DatabaseService() {
    }

    /**
     * Exceptions specific to calling the service methods
     */
    public with sharing class DatabaseUpdateException extends Exception {
    }

    public with sharing class DatabaseInsertException extends Exception {
    }

    /**
     * Stubbable "wrapper" of System.Savepoint.  Instances are constructed with a
     * null System.Savepoint, so instances can be safely stubbed.
     */
    public with sharing class Savepoint {
        @TestVisible
        private System.Savepoint savepoint;

        /**
         * Private access so production code cannot construct this class.
         * Production code must go through DatabaseService.Savepoint setSavepoint().
         */
        @TestVisible
        private Savepoint() {
        }
    }

    /**
     * Stubbable "wrapper" of Database.SaveResult. We cannot mock Database directly as the operations are key words
     */
    public virtual with sharing class SaveResult {
        private List<DatabaseService.Error> errors;
        private Id recordId;
        public Boolean success;

        @TestVisible
        protected SaveResult(
            List<DatabaseService.Error> errors,
            Id recordId,
            Boolean isSuccess
        ) {
            this.errors = errors;
            this.recordId = recordId;
            this.success = isSuccess;
        }

        public List<DatabaseService.Error> getErrors() {
            return this.errors;
        }

        public Id getId() {
            return this.recordId;
        }

        public Boolean isSuccess() {
            return this.success;
        }
    }

    public with sharing class Error {
        private List<String> fields;
        private String message;
        private System.StatusCode statusCode;

        @TestVisible
        private Error(List<String> fields, String message, System.StatusCode statusCode) {
            this.fields = fields;
            this.message = message;
            this.statusCode = statusCode;
        }

        public List<String> getFields() {
            return this.fields;
        }

        public String getMessage() {
            return this.message;
        }

        public System.StatusCode getStatusCode() {
            return this.statusCode;
        }
    }

    /**
     * This is the only way to get a DatabaseService.Savepoint in production code.
     * @return   A DatabaseService.Savepoint with its System.Savepoint set.
     */
    public DatabaseService.Savepoint setSavepoint() {
        final DatabaseService.Savepoint savepoint = new DatabaseService.Savepoint();
        savepoint.savepoint = System.Database.setSavepoint();
        return savepoint;
    }

    /**
     * Rolls back to the savepoint's System.Savepoint.
     * @param  savepoint Pass in a DatabaseService.Savepoint returned by setSavepoint().
     */
    public void rollback(DatabaseService.Savepoint savepoint) {
        System.Database.rollback(savepoint.savepoint);
    }

    @TestVisible
    private List<DatabaseService.SaveResult> getSaveResults(
        List<Database.SaveResult> databaseSaveResults
    ) {
        List<DatabaseService.SaveResult> results = new List<DatabaseService.SaveResult>();
        for (Database.SaveResult databaseSaveResult : databaseSaveResults) {
            List<DatabaseService.Error> databaseServiceErrors = new List<DatabaseService.Error>();
            for (Database.Error error : databaseSaveResult.getErrors()) {
                databaseServiceErrors.add(
                    new DatabaseService.Error(
                        error.getFields(),
                        error.getMessage(),
                        error.getStatusCode()
                    )
                );
            }
            DatabaseService.SaveResult result = new DatabaseService.SaveResult(
                databaseServiceErrors,
                databaseSaveResult.getId(),
                databaseSaveResult.isSuccess()
            );
            results.add(result);
        }
        return results;
    }

    /**
     * insertRecords This implemented in preperation of chunk update protection.
     * @param  records This is a list of SObjects
     * @return return List of Database.SaveResult
     */
    public List<DatabaseService.SaveResult> insertRecords(
        List<SObject> records,
        Boolean allOrNothing
    ) {
        List<sObject> recordsToInsert = reorderListBySObjectType(records);
        this.securityService.verifyIsCreateable(recordsToInsert);
        return this.getSaveResults(System.Database.insert(recordsToInsert, allOrNothing));
    }

    /**
     * insertRecords This implemented in preperation of chunk update protection.
     * @param  records This is a list of SObjects
     * @return return List of Database.SaveResult
     */
    public List<DatabaseService.SaveResult> insertRecords(List<SObject> records) {
        return this.insertRecords(records, true);
    }

    /**
     * updateRecords This implemented in preperation of chunk update protection.
     * @param  records This is a list of SObjects
     * @return return List of Database.SaveResult
     */
    public List<DatabaseService.SaveResult> updateRecords(
        List<SObject> records,
        Boolean allOrNothing
    ) {
        List<sObject> recordsToUpdate = reorderListBySObjectType(records);
        this.securityService.verifyIsUpdateable(recordsToUpdate);
        return this.getSaveResults(System.Database.update(recordsToUpdate, allOrNothing));
    }

    public List<DatabaseService.SaveResult> updateRecords(List<SObject> records) {
        return this.updateRecords(records, true);
    }

    /**
     * Deletes a list of records and returns the result
     * @param  recordIds Pass in a list of Ids for records to delete
     * @return   A list of Database.DeleteResult resulting from the delete operation
     */
    public List<Database.DeleteResult> deleteRecordsById(List<Id> recordIds) {
        return Database.delete(recordIds);
    }

    /**
     * Orders a list of sObjects by grouping them based on their sObjectType. This is to help prevent DML update errors (chunking)
     * @param  records Pass in a list of Ids for records to delete
     * @return   A grouped list of sObjects
     */
    private List<sObject> reorderListBySObjectType(List<sObject> records) {
        List<sObject> groupedList = new List<sObject>();
        Map<Schema.SObjectType, List<sObject>> mapRecordsBySObjectType = new Map<Schema.SObjectType, List<sObject>>();
        for (sObject record : records) {
            Schema.SObjectType recordSObjectType = record.getSObjectType();
            if (!mapRecordsBySObjectType.containsKey(recordSObjectType)) {
                mapRecordsBySObjectType.put(recordSObjectType, new List<sObject>());
            }
            mapRecordsBySObjectType.get(recordSObjectType).add(record);
        }
        for (List<sObject> sObjects : mapRecordsBySObjectType.values()) {
            groupedList.addAll(sObjects);
        }
        return groupedList;
    }
}
