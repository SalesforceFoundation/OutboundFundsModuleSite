# * Copyright (c) 2021, salesforce.com, inc.
# * All rights reserved.
# * SPDX-License-Identifier: BSD-3-Clause
# * For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/BSD-3-Clause
# *

*** Settings ***

Resource       cumulusci/robotframework/Salesforce.robot
Library        OutboundFundsCommunity.py
Library        DateTime
Library        cumulusci.robotframework.PageObjects
...            robot/OutboundFundsCommunity/resources/ContactPageObject.py
...            robot/OutboundFundsCommunity/resources/CommunityHomePageObject.py

*** Keywords ***

Capture Screenshot and Delete Records and Close Browser
    [Documentation]                 This keyword will capture a screenshot before closing
    ...                             the browser and deleting records when test fails
    Run Keyword If Any Tests Failed      Capture Page Screenshot
    Close Browser
    Delete Session Records

API Create Account
    [Documentation]                 Create an Account for user
    [Arguments]                     &{fields}
    ${name} =                       Generate New String
    ${account_id} =                 Salesforce Insert  Account
    ...                             Name=${name}
    ...                             &{fields}
    &{account} =                    Salesforce Get  Account  ${account_id}
    [return]                        &{account}

API Get Group Id
    [Documentation]         Returns the ID of a Group
    [Arguments]             &{fields}
    ${result} =             SOQL Query
    ...                     SELECT Id FROM Group WHERE DeveloperName = 'AllCustomerPortalUsers'
    &{Id} =                 Get From List  ${result['records']}  0
    [return]                ${Id}[Id]

API Create Contact
    [Documentation]                 Create a contact via API
    [Arguments]                     &{fields}
    ${contact_id} =                 Salesforce Insert  Contact
    ...                             FirstName=${faker.first_name()}
    ...                             LastName=${faker.last_name()}
    ...                             &{fields}
    &{contact} =                    Salesforce Get  Contact  ${contact_id}
    [Return]                        &{contact}

API Create Contact for User
    [Documentation]                 Create a contact via API for user creation
    [Arguments]                     ${account_id}   &{fields}
    ${email}=                       Random Email
    ${contact_id} =                 Salesforce Insert  Contact
    ...                             FirstName=${faker.first_name()}
    ...                             LastName=${faker.last_name()}
    ...                             AccountId=${account_id}
    ...                             Email=${email}
    ...                             &{fields}
    &{contact} =                    Salesforce Get  Contact  ${contact_id}
    [Return]                        &{contact}

API Create Funding Program
    [Documentation]                 Create a Funding Program via API
    [Arguments]                     &{fields}
    ${ns} =                         Get OBF Namespace Prefix
    ${funding_program_name} =       Generate New String
    ${start_date} =                 Get Current Date  result_format=%Y-%m-%d
    ${end_date} =                   Get Current Date  result_format=%Y-%m-%d    increment=90 days
    ${funding_program_id} =         Salesforce Insert  ${ns}Funding_Program__c
    ...                             Name=${funding_program_name}
    ...                             ${ns}Start_Date__c=${start_date}
    ...                             ${ns}End_Date__c=${end_date}
    ...                             ${ns}Status__c=In Progress
    ...                             ${ns}Total_Program_Amount__c=100000
    ...                             ${ns}Description__c=Robot API Program
    ...                             &{fields}
    &{fundingprogram} =             Salesforce Get  ${ns}Funding_Program__c  ${funding_program_id}
    Share Funding Program           ${funding_program_id}
    [Return]                        &{fundingprogram}

API Create Funding Request
    [Documentation]                 Create a Funding Request via API
    [Arguments]                     ${funding_program_id}   &{fields}
    ${ns} =                         Get OBF Namespace Prefix
    ${contact_id} =                 API Get Contact Id for Robot Test User  Walker
    ${funding_request_name} =       Generate New String
    ${application_date} =           Get Current Date  result_format=%Y-%m-%d
    ${funding_request_id} =         Salesforce Insert  ${ns}Funding_Request__c
    ...                             Name=${funding_request_name}
    ...                             ${ns}Applying_Contact__c=${contact_id}
    ...                             ${ns}Status__c=In Progress
    ...                             ${ns}Requested_Amount__c=100000
    ...                             ${ns}FundingProgram__c=${funding_program_id}
    ...                             ${ns}Requested_For__c=Education
    ...                             ${ns}Application_Date__c=${application_date}
    ...                             &{fields}
    &{funding_request} =            Salesforce Get  ${ns}Funding_Request__c  ${funding_request_id}
    Store Session Record            ${ns}Funding_Request__c   ${funding_request_id}
    [Return]                        &{funding_request}

API Create Requirement on a Funding Request
    [Documentation]                 Create a Requirement on a Funding Request via API
    [Arguments]                     ${funding_request_id}     &{fields}
    ${requirement_name} =           Generate New String
    ${ns}=                          Get OBF Namespace Prefix
    ${due_date} =                   Get Current Date  result_format=%Y-%m-%d    increment=30 days
    ${user_id} =                    API Get User Id for Robot Test User  Walker
    ${contact_id} =                 API Get Contact Id for Robot Test User  Walker
    ${requirement_id} =             Salesforce Insert  ${ns}Requirement__c
    ...                             Name=${requirement_name}
    ...                             ${ns}Primary_Contact__c=${contact_id}
    ...                             ${ns}Due_Date__c=${due_date}
    ...                             ${ns}Assigned__c=${user_id}
    ...                             ${ns}Status__c=Open
    ...                             ${ns}Funding_Request__c=${funding_request_id}
    ...                             ${ns}Type__c=Review
    ...                             outfunds_comm__IsAddFilesVisible__c=true
    ...                             &{fields}
    &{requirement} =                Salesforce Get  ${ns}Requirement__c  ${requirement_id}
    Store Session Record            ${ns}Requirement__c   ${requirement_id}
    [Return]                        &{requirement}

API Create Disbursement on a Funding Request
    [Documentation]                 Create a Disbursement on a Funding Request via API
    [Arguments]                     ${funding_request_id}  &{fields}
    ${ns} =                         Get OBF Namespace Prefix
    ${scheduled_date} =             Get Current Date  result_format=%Y-%m-%d    increment=5 days
    ${disbursement_date} =          Get Current Date  result_format=%Y-%m-%d    increment=10 days
    ${disbursement_id} =            Salesforce Insert  ${ns}Disbursement__c
    ...                             ${ns}Funding_Request__c=${funding_request_id}
    ...                             ${ns}Amount__c=5000
    ...                             ${ns}Status__c=Scheduled
    ...                             ${ns}Scheduled_Date__c=${scheduled_date}
    ...                             ${ns}Type__c=Initial
    ...                             ${ns}Disbursement_Date__c=${disbursement_date}
    ...                             ${ns}Disbursement_Method__c=Check
    ...                             &{fields}
    &{disbursement} =               Salesforce Get  ${ns}Disbursement__c  ${disbursement_id}
    Store Session Record            ${ns}disbursement__c   ${disbursement_id}
    [Return]                        &{disbursement}

API Get Id
    [Documentation]                 Returns the ID of a record identified by the given field_name
    ...                             and field_value input for a specific object
    [Arguments]                     ${obj_name}    &{fields}
    @{records} =                    Salesforce Query      ${obj_name}
    ...                             select=Id
    ...                             &{fields}
    &{Id} =                         Get From List  ${records}  0
    [return]                        ${Id}[Id]

API Get Email for User
    [Documentation]         Returns the Email of a User
    [Arguments]             ${last_name}    &{fields}
    ${result} =             SOQL Query
    ...                     SELECT Email FROM Contact where LastName LIKE '${last_name}'
    ${email} =              Get From List  ${result['records']}  0
    [return]                ${email}[Email]

API Get User Name for User
    [Documentation]         Returns the Username of a User
    [Arguments]             ${last_name}    &{fields}
    ${result} =             SOQL Query
    ...                     SELECT Username FROM User where LastName LIKE '${last_name}' and IsActive=True
    ${user_name} =          Get From List  ${result['records']}  0
    [return]                ${user_name}[Username]

API Activate Community
    [Documentation]             Activates community to live
    ${network_id} =             API Get Id
    ...                         Network     Name=Funding Program Portal
    API Update Record           Network     ${network_id}    Status=Live

Enable Public Access for Guest User
    [Documentation]             Setup Community for Public access
    Go To Setup Home
    Go To Community Builder
    Get Window Titles
    Switch Window               title=Experience Builder
    Enable Public Access

Share Funding Program
    [Documentation]         Share New Funding Program with Community User
    [Arguments]             ${funding_program_id}       &{fields}
    ${ns} =                 Get OBF Namespace Prefix
    ${group_id} =           API Get Group Id
    ${share_id}             Salesforce Insert   ${ns}Funding_Program__Share
    ...                     UserOrGroupId=${group_id}
    ...                     ParentId=${funding_program_id}
    ...                     AccessLevel=Read
    ...                     RowCause=Manual
    ...                     &{fields}
    &{access} =             Salesforce Get  ${ns}Funding_Program__Share  ${share_id}
    [Return]                &{access}

Go To Community As Robot Test User
    [Documentation]                 Go to the given CONTACT_ID detail page and log in to community
    [Arguments]                     ${contact_id}
    Go To Page                      Detail      Contact       ${contact_id}
    wait until loading is complete
    ${contact_name} =               API Get Name Based on Id     Contact     Id=${contact_id}
    Current Page Should Be          Detail      Contact
    Capture Page Screenshot
    Login To Community As User
    Capture Page Screenshot
    Current Page Should Be          Home        Community

API Get Name Based on Id
    [Documentation]                 Returns the Name of a record identified by the given field_name
    ...                             and field_value input for a specific object
    [Arguments]                     ${obj_name}    &{fields}
    @{records} =                    Salesforce Query      ${obj_name}
    ...                             select=Name
    ...                             &{fields}
    &{Name} =                       Get From List  ${records}  0
    [return]                        ${Name}[Name]

API Get Contact Id for Robot Test User
    [Documentation]         Returns the ID of Robot Walker
    [Arguments]             ${last_name}     &{fields}
    ${result} =             API Get Id      Contact         LastName=${last_name}
    [return]                ${result}

API Get User Id for Robot Test User
    [Documentation]         Returns the ID of a Robot Test User
    [Arguments]             ${last_name}     &{fields}
    ${result} =             API Get Id      User         LastName=${last_name}
    [return]                ${result}