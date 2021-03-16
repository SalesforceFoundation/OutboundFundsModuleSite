*** Settings ***
Documentation  Community User Apply for Funding Program
Resource       robot/OutboundFundsCommunity/resources/OutboundFundsCommunity.robot
Library        cumulusci.robotframework.PageObjects
...            robot/OutboundFundsCommunity/resources/OutboundFundsCommunity.py
...            robot/OutboundFundsCommunity/resources/CommunityFundingProgramPageObject.py
...            robot/OutboundFundsCommunity/resources/CommunityFundingRequestPageObject.py

Suite Setup     Run keywords
...             Open Test Browser
...             Setup Test Data
Suite Teardown  Capture Screenshot And Delete Records And Close Browser

*** Keywords ***
Setup Test Data
    [Documentation]                   Create data to run tests
    ${ns} =                           Get OBF Namespace Prefix
    Set Suite Variable                ${ns}
    ${path} =                         Normalize Path    ${CURDIR}/../../../test_data/requirement.txt
    Set Suite Variable                ${path}
    &{fundingprogram} =               API Create Funding Program
    Set suite variable                &{fundingprogram}

*** Test Cases ***
Apply to Funding Program
    [Documentation]                             Add Funding Request on a funding Program in
    ...                                          community via "Apply" button on Funding Program
    [tags]                                      unstable    feature:FundingProgram
    Go To Community As Test User                Contact        Grace Walker
    Wait Until Element Is Visible               text:Our Grant Programs
    Click Portal Tab                            Funding Programs
    Current Page Should Be                      Listing     Funding Program
    Click Link With Text                        ${fundingprogram}[Name]
    Current Page Should be                      Details       Funding Program
    Click Program Button                        Apply
    Populate Apply Form                         Requested Amount=20000
    ...                                         Requested For=Education
    Click Next
    Choose File                                 Grants:upload_file      ${path}
    Click Upload Modal Button                   Done
    Click Button                                Next
    Current Page Should be                      Details       Funding Request