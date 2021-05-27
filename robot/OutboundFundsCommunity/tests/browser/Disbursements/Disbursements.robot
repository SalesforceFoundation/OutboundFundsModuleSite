*** Settings ***
Documentation  Create an awarded funding request and add disbursemnt
Resource       robot/OutboundFundsCommunity/resources/OutboundFundsCommunity.robot
Library        cumulusci.robotframework.PageObjects
...            robot/OutboundFundsCommunity/resources/FundingRequestPageObject.py
...            robot/OutboundFundsCommunity/resources/OutboundFundsCommunity.py
...            robot/OutboundFundsCommunity/resources/DisbursementsPageObject.py

Suite Setup     Run keywords
...             Open Test Browser
...             Setup Test Data
Suite Teardown  Capture Screenshot And Delete Records And Close Browser

*** Keywords ***
Setup Test Data
    [Documentation]                   Create data to run tests
    ${ns} =                           Get OBF Namespace Prefix
    Set Suite Variable                ${ns}
    ${fundingprogram} =               API Create Funding Program
    Set suite variable                ${fundingprogram}
    ${contact} =                      API Create Contact
    Store Session Record              Contact                              ${contact}[Id]
    Set suite variable                ${contact}
    ${funding_request1} =             API Create Funding Request
    ...                               ${fundingprogram}[Id]     ${contact}[Id]
    ...                               ${ns}Status__c=Awarded
    ...                               ${ns}Awarded_Amount__c=100000
    Store Session Record              ${ns}Funding_Request__c         ${funding_request}[Id]
    Set suite variable                ${funding_request1}
    ${funding_request2} =             API Create Funding Request
    ...                               ${fundingprogram}[Id]     ${contact}[Id]
    ...                               ${ns}Status__c=Awarded
    ...                               ${ns}Awarded_Amount__c=100000
    Store Session Record              ${ns}Funding_Request__c         ${funding_request}[Id]
    Set suite variable                ${funding_request2}
    ${date_1} =                         Get current date    result_format=%m/%d/%Y  increment=1 day
    ${date_2} =                         Get current date    result_format=%m/%d/%Y  increment=10 day
    Set suite variable                  ${date_1}
    Set suite variable                  ${date_2}

*** Test Case ***
New Disbursement on a Funding Request via Create Disbursements button
    [Documentation]                             Creates a Funding Request via API.
    ...                                         Verifies that Funding Request is created and
    ...                                         add a new Disbursement
    [tags]                                      feature:FundingRequest
    Go To Page                                  Listing          ${ns}Funding_Request__c
    Click Link With Text                        ${funding_request1}[Name]
    Wait Until Loading Is Complete
    Current Page Should Be                      Details          Funding_Request__c
    Click Button                                Create Disbursements
    wait until modal is open
    Populate Field                              Number of Disbursements     4
    Populate Field                              Interval    4
    Populate Field                              Amount      80000
    click button                                Calculate
    Wait Until Element Is Visible               text:Scheduled Date
    Save Disbursement
    Current Page Should Be                      Details          Funding_Request__c
    Validate Field Value                        Unpaid Disbursements    contains    $80,000.00
    Validate Field Value                        Available for Disbursement  contains    $20,000.00

New Diisbursement via Related List
    [Documentation]                             Creates a Funding Request via API.
    ...                                         Verifies that Funding Request is created and
    ...                                         add a new Disbursement via Related list
    [tags]                                      feature:FundingRequest
    Go To Page                                  Listing          ${ns}Funding_Request__c
    Click Link With Text                        ${funding_request2}[Name]
    Wait Until Loading Is Complete
    Current Page Should Be                      Details          Funding_Request__c
    Click Tab                                   Disbursements
    click related list wrapper button           Disbursements           New
    Wait For Modal                              New                     Disbursement
    Populate Field                              Amount          10000
    Select Value from Picklist                  Status          Scheduled
    Select Value from Picklist                  Type            Initial
    Select Value from Picklist                  Disbursement Method         Check
    Add Date                                    Scheduled Date              ${date_1}
    Add Date                                    Disbursement Date           ${date_2}
    Click Save
    ${ds_name}=                                 API Get Name Based on Id  ${ns}Disbursement__c
    ...                                         ${ns}Funding_Request__c=${funding_request2}[Name]
    ...                                         ${ns}Status__c=Scheduled
    Verify Toast Message                        Disbursement "${ds_name}" was created.
    Click link with text                        ${ds_name}
    Current Page Should Be                      Details          Disbursements__c
    Validate Field Value                        Funding Request    contains    ${funding_request2}[Name]
    Validate Field Value                        Amount  contains    $10,000.00
