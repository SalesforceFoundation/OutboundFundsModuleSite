/*
 * Copyright (c) 2021, salesforce.com, inc.
 * All rights reserved.
 * SPDX-License-Identifier: BSD-3-Clause
 * For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/BSD-3-Clause
 */

/**
 * Grants read sharing-access to an account's Portal Role And Subordinates for all Funding Programs where the account has a Funding Request.
 */

// Query Funding Requests related to an Account.
final List<Schema.outfunds__Funding_Request__c> fundingRequests = [
    SELECT Id, outfunds__FundingProgram__c, outfunds__Applying_Organization__c
    FROM outfunds__Funding_Request__c
    WHERE outfunds__Applying_Organization__c IN (SELECT Id FROM Account)
];

// Get Group IDs for the Accounts' Portal Role And Subordinates.
final Set<Id> accountIds = new Set<Id>();
for (Schema.outfunds__Funding_Request__c fundingRequest : fundingRequests) {
    accountIds.add(fundingRequest.outfunds__Applying_Organization__c);
}

final Map<Id, Id> portalRoleAndSubordinateGroupIdsByAccountId = new Map<Id, Id>();
for (
    Schema.Group g : [
        SELECT
            Id,
            TYPEOF Related
                WHEN UserRole THEN PortalAccountId
            END
        FROM Group
        WHERE
            Type = 'RoleAndSubordinates'
            AND RelatedId IN (
                SELECT Id
                FROM UserRole
                WHERE PortalAccountId IN :accountIds
            )
    ]
) {
    portalRoleAndSubordinateGroupIdsByAccountId.put(
        (Id) g.getSObject('Related').get('PortalAccountId'),
        g.Id
    );
}

// Create Funding Program shares granting read access.
final List<Schema.outfunds__Funding_Program__Share> fundingProgramShares = new List<Schema.outfunds__Funding_Program__Share>();
for (Schema.outfunds__Funding_Request__c fundingRequest : fundingRequests) {
    final Id groupId = portalRoleAndSubordinateGroupIdsByAccountId.get(
        fundingRequest.outfunds__Applying_Organization__c
    );
    if (groupId != null) {
        fundingProgramShares.add(
            new Schema.outfunds__Funding_Program__Share(
                ParentId = fundingRequest.outfunds__FundingProgram__c,
                UserOrGroupId = groupId,
                AccessLevel = 'Read'
            )
        );
    }
}
insert fundingProgramShares;
