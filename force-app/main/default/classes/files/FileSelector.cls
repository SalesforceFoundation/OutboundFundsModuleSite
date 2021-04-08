/*
 * Copyright (c) 2021, salesforce.com, inc.
 * All rights reserved.
 * SPDX-License-Identifier: BSD-3-Clause
 * For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/BSD-3-Clause
 */
public with sharing class FileSelector {
    public List<ContentDocumentLink> getContentDocumentLinksByRecordIds(
        Set<Id> recordIds
    ) {
        return [
            SELECT Id, ContentDocumentId, LinkedEntityId
            FROM ContentDocumentLink
            WHERE LinkedEntityId IN :recordIds
            WITH SECURITY_ENFORCED
        ];
    }

    public List<ContentDocument> getContentDocumentsByIds(Set<Id> contentDocumentIds) {
        return [
            SELECT Id, OwnerId, Description, FileExtension, FileType, Title
            FROM ContentDocument
            WHERE Id IN :contentDocumentIds
            WITH SECURITY_ENFORCED
        ];
    }
}
