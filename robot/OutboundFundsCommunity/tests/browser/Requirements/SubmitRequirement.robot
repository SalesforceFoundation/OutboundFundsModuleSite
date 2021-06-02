*** Settings ***

Resource       robot/OutboundFundsCommunity/resources/OutboundFundsCommunity.robot
Library        cumulusci.robotframework.PageObjects
...            robot/OutboundFundsCommunity/resources/OutboundFundsCommunity.py
...            robot/OutboundFundsCommunity/resources/CommunityFundingRequestPageObject.py
...            robot/OutboundFundsCommunity/resources/CommunityFundingProgramPageObject.py
...            robot/OutboundFundsCommunity/resources/CommunityRequirementPageObject.py
...            robot/OutboundFundsCommunity/resources/FundingProgramPageObject.py

Suite Setup     Run keywords
...             Open Test Browser
...             Setup Test Data
Suite Teardown  Capture Screenshot and Delete Records and Close Browser

*** Keywords ***
Setup Test Data
    ${nso}=                           Get OBF Namespace Prefix
    Set Suite Variable                ${nso}
    ${path} =                         Normalize Path     ${CURDIR}/../../../test_data/requirement.txt
    Set Suite Variable                ${path}
    ${fundingprogram} =               API Create Funding Program
    Set suite variable                &{fundingprogram}
    ${user_id} =                      API Get User Id for Robot Test User
    ...                               Walker
    Set Suite Variable                ${user_id}
    ${contact_id} =                   API Get Contact Id for Robot Test User
    ...                               Walker
    Set Suite Variable                ${contact_id}


*** Test Cases ***
Submit a File on a Requirement on a Funding Request
    [Documentation]                             Create a Funding Request via the Community and then create a Requirement
    ...                                         via API and then complete the requirement via the Community
    [tags]                                      W-8079214         feature:Requirement
    Go To Community As Robot Test User                ${contact_id}
    Wait Until Element Is Visible               text:Find Funding Opportunities
    click Portal Tab                            Funding Programs
    Current Page Should Be                      Listing     Funding Program
    Click Link With Text                        ${fundingprogram}[Name]
    Current Page Should be                      Details       Funding Program
    Click Program Button                        Apply
    Populate Apply Form                         Requested Amount=20000
    ...                                         Requested For=Education
    Click Next
    Click Button                                Next
    Current Page Should be                      Details       Funding Request
    ${fundingrequest_id} =                      API Get Id    ${nso}Funding_Request__c
    ...                                         ${nso}FundingProgram__c=${fundingprogram}[Id]
    Set Suite Variable                          ${fundingrequest_id}
    ${requirement}                              API Create Requirement on a Funding Request
    ...                                         ${fundingrequest_id}
    Set Suite Variable                          ${requirement}
    Go To Community As Robot Test User           ${contact_id}
    Wait Until Element Is Visible               text:Find Funding Opportunities
    Click Portal Tab                            My Application
    Click Link With Text                        Robot Walker: ${fundingprogram}[Name]
    Current Page Should be                      Details       Funding Request
    Click Link With Text                        ${requirement}[Name]
    Current Page Should be                      Details       Requirement
    Scroll To Upload Files
    Choose File                                 //input[@type='file' and contains(@class,'slds-file-selector__input')]     ${path}
    Click Button                                Done
    Current Page Should be                      Details       Requirement
    Submit Requirement
    Wait Until Element Is Visible               text:Take a moment to review everything you'd like to submit.
    Click Button                                Next
    Wait Until Element Is Visible               text:Your requirement has been submitted.
    Click Button                                Finish
    Current Page Should be                      Details       Requirement
