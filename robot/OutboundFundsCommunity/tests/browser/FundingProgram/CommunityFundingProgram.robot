# * Copyright (c) 2021, salesforce.com, inc.
# * All rights reserved.
# * SPDX-License-Identifier: BSD-3-Clause
# * For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/BSD-3-Clause
# *

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
    ${contact_id} =                   API Get Contact Id for Robot Test User
    ...                               Walker
    Set Suite Variable                ${contact_id}


*** Test Cases ***
Apply to Funding Program
    [Documentation]                             Add Funding Request on a funding Program in
    ...                                         community via "Apply" button on Funding Program
    [tags]                                      feature:FundingProgram
    Go To Community As Robot Test User          ${contact_id}
    Wait Until Element Is Visible               text:Find Funding Opportunities
    Click Portal Tab                            Funding Programs
    Current Page Should Be                      Listing     Funding Program
    Click Link With Text                        ${fundingprogram}[Name]
    Current Page Should be                      Details       Funding Program
    Click Program Button                        Apply
    Populate Apply Form                         Requested Amount=20000
    ...                                         Requested For=Education
    Click Next
    Choose File                                 //input[@type='file' and contains(@class,'slds-file-selector__input')]      ${path}
    Click Upload Modal Button                   Done
    Click Button                                Next
    Current Page Should be                      Details       Funding Request