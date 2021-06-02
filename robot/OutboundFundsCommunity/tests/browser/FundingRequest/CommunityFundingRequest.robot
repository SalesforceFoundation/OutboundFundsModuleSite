# * Copyright (c) 2021, salesforce.com, inc.
# * All rights reserved.
# * SPDX-License-Identifier: BSD-3-Clause
# * For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/BSD-3-Clause
# *

*** Settings ***
Documentation  Create a Funding Program
Resource       robot/OutboundFundsCommunity/resources/OutboundFundsCommunity.robot
Library        cumulusci.robotframework.PageObjects
...            robot/OutboundFundsCommunity/resources/CommunityFundingRequestPageObject.py
...            robot/OutboundFundsCommunity/resources/CommunityFundingProgramPageObject.py

Suite Setup     Run keywords
...             Open Test Browser
...             Setup Test Data
#Suite Teardown  Capture Screenshot and Delete Records and Close Browser


*** Keywords ***
Setup Test Data
    ${ns}=                            Get OBF Namespace Prefix
    Set suite variable                ${ns}
    ${path} =                         Normalize Path     ${CURDIR}/../../../test_data/requirement.txt
    Set Suite Variable                ${path}
    ${fundingprogram} =               API Create Funding Program
    Set suite variable                &{fundingprogram}
    ${contact_id} =                   API Get Contact Id for Robot Test User
    ...                               Walker
    Set Suite Variable                ${contact_id}
    ${awardedfunding_request} =         API Create Funding Request           ${fundingprogram}[Id]     ${contact_id}
    ...                                 ${ns}Status__c=Awarded          ${ns}Awarded_Amount__c=100000
    Store Session Record                ${ns}Funding_Request__c         ${awardedfunding_request}[Id]
    Set suite variable                  ${awardedfunding_request}

*** Test Cases ***
Add Funding Request Via Apply on Funding Program
    [Documentation]                             Add Funding Request on a funding Program in community
    ...                                         via "Apply" button on Funding Program
    [tags]                                      feature:FundingRequest     feature:Community
    Go To Community As Robot Test User          ${contact_id}
    Wait Until Element Is Visible               text:Find Funding Opportunities
    click Portal Tab                            Funding Programs
    Current Page Should Be                      Listing     Funding Program
    Click Link With Text                        ${fundingprogram}[Name]
    Current Page Should be                      Details       Funding Program
    Click Program Button                        Apply
    Populate Apply Form                         Requested Amount=20000
    ...                                         Requested For=Education
    Click Next
    Choose File                                 //input[@type='file' and contains(@class,'slds-file-selector__input')]      ${path}
    Click Button                                Done
    Click Button                                Next
    Current Page Should be                      Details       Funding Request

Submit a New Funding Request
    [Documentation]                             Submit a New Funding Request
    [tags]                                      feature:Funding Request     feature:Community
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
    Submit Application
    Click Button                                Next
    Click Button                                Finish
    Current Page Should be                      Details       Funding Request

Verify User Cannot Re-Submit Application
    [Documentation]                             Re-Submit a  Funding Request
    [tags]                                      feature:Funding Request     feature:Community
    Go To Community As Robot Test User                ${contact_id}
    Wait Until Element Is Visible               text:Find Funding Opportunities
    Click Portal Tab                            My Application
    Click Link With Text                        ${awardedfunding_request}[Name]
    Current Page Should be                      Details       Funding Request
    Submit Application
    Wait Until Element Is Visible               text:This application cannot be submitted at this time.
    Click Button                                Finish
    Current Page Should be                      Details       Funding Request

