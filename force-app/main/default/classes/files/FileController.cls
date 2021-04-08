/*
 * Copyright (c) 2021, salesforce.com, inc.
 * All rights reserved.
 * SPDX-License-Identifier: BSD-3-Clause
 * For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/BSD-3-Clause
 */
public with sharing class FileController {
    @TestVisible
    private static FileService fileService = new FileService();

    @AuraEnabled(cacheable=true)
    public static List<ContentDocument> getRecordFiles(Id recordId) {
        try {
            return fileService.getContentDocumentsByRecordId(recordId);
        } catch (Exception e) {
            throw new AuraHandledException(System.Label.File_Retrieval_Error);
        }
    }

    @AuraEnabled
    public static String deleteContentDocument(ContentDocument cd) {
        if (cd.OwnerId != UserInfo.getUserId()) {
            throw new AuraHandledException(System.Label.Delete_File_Error_Message);
        }

        try {
            return JSON.serialize(
                fileService.deleteContentDocuments(new List<ContentDocument>{ cd })
            );
        } catch (Exception e) {
            throw new AuraHandledException(System.Label.Delete_File_Error_Message);
        }
    }
}
