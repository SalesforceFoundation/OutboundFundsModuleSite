*** Settings ***

Resource       robot/OutboundFundsCommunity/resources/OutboundFundsCommunity.robot
Library        cumulusci.robotframework.PageObjects
...            robot/OutboundFundsCommunity/resources/OutboundFundsCommunity.py
...            robot/OutboundFundsCommunity/resources/FundingProgramPageObject.py

Suite Setup     Run keywords
...             Open Test Browser
...             Setup Test Data
Suite Teardown  Capture Screenshot And Delete Records And Close Browser

*** Keywords ***
Setup Test Data
    ${ns} =                           Get OBF Namespace Prefix
    Set Suite Variable                ${ns}
    &{fundingprogram} =               API Create Funding Program
    ${fp_name} =                      Generate New String
    Set suite variable                &{fundingprogram}
    Set suite variable                ${fp_name}

*** Test Case ***
Create Funding Program Via API
    [Documentation]                             Creates a Funding Program via API.
    ...                                         Verifies that Funding Program is created and
    ...                                         displays under recently viewed Funding Program
    [tags]                                      feature:FundingProgram
    Go To Page                                  Listing             ${ns}Funding_Program__c
    Capture Page Screenshot
    Click Link With Text                        ${fundingprogram}[Name]
    Wait Until Loading Is Complete
    Current Page Should Be                      Details             Funding_Program__c

Create Funding Program via UI in OutboundFunds
    [Documentation]                             Creates a Funding Program via UI.
     ...                                        Verifies that Funding Program is created.
     [tags]                                     feature:FundingProgram
     Go To Page                                 Listing             ${ns}Funding_Program__c
     Capture Page Screenshot
     Click Object Button                        New
     Wait Until Modal Is Open
     Populate Field                             Funding Program Name        ${fp_name}
     Populate Field                             Description         Automated Robot Funding Program
     Click Save
     Wait Until Modal Is Closed
     Current Page Should Be                     Details             Funding_Program__c