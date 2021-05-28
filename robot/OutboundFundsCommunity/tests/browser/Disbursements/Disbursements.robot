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
    ${funding_request} =              API Create Funding Request
    ...                               ${fundingprogram}[Id]     ${contact}[Id]
    ...                               ${ns}Status__c=Awarded
    ...                               ${ns}Awarded_Amount__c=100000
    Store Session Record              ${ns}Funding_Request__c         ${funding_request}[Id]
    Set suite variable                ${funding_request}
    ${date_1} =                         Get current date    result_format=%m/%d/%Y  increment=1 day
    ${date_2} =                         Get current date    result_format=%m/%d/%Y  increment=10 day
    Set suite variable                  ${date_1}
    Set suite variable                  ${date_2}

*** Test Case ***
New Disbursement via Related List
    [Documentation]                             Creates a Funding Request via API.
    ...                                         Verifies that Funding Request is created and
    ...                                         add a new Disbursement via Related list
    [tags]                                      feature:FundingRequest
    Go To Page                                  Listing          ${ns}Funding_Request__c
    Click Link With Text                        ${funding_request}[Name]
    Wait Until Loading Is Complete
    Current Page Should Be                      Details          Funding_Request__c
    Click Tab                                   Disbursements
    click related list wrapper button           Disbursements           New
    Wait For Modal                              New                     Disbursement
    Populate Field                              Amount          10000
    Select Value from Picklist                  Status          Scheduled
    Select Value from Picklist                  Type            Final
    Select Value from Picklist                  Disbursement Method         EFT
    Add Date                                    Scheduled Date              ${date_1}
    Add Date                                    Disbursement Date           ${date_2}
    Click Save
    Verify Toast Message                        Disbursement
    ${ds_name}=                                 API Get Name Based on Id  ${ns}Disbursement__c
    ...                                         ${ns}Type__c=Final
    ...                                         ${ns}Status__c=Scheduled
    Click Element                               //a//span[text()='${ds_name}']
    Current Page Should Be                      Details          Disbursement__c
    Validate Field Value                        Funding Request    contains    ${funding_request}[Name]
    Validate Field Value                        Amount  contains    $10,000.00
