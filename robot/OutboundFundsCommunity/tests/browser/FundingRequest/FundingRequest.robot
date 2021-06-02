# * Copyright (c) 2021, salesforce.com, inc.
# * All rights reserved.
# * SPDX-License-Identifier: BSD-3-Clause
# * For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/BSD-3-Clause
# *

*** Settings ***

Documentation  Create Funding Request, Add a Requirement, and
...            Add Disbursement on an Awarded Funding Request
Resource       robot/OutboundFundsCommunity/resources/OutboundFundsCommunity.robot
Library        cumulusci.robotframework.PageObjects
...            robot/OutboundFundsCommunity/resources/FundingRequestPageObject.py

Suite Setup     Run keywords
...             Open Test Browser
...             Setup Test Data
Suite Teardown  Capture Screenshot And Delete Records And Close Browser

*** Keywords ***
Setup Test Data
    [Documentation]                     Create data to run tests
    ${ns} =                             Get OBF Namespace Prefix
    Set Suite Variable                  ${ns}
    ${fundingprogram} =                 API Create Funding Program
    Store Session Record                ${ns}Funding_Program__c     ${fundingprogram}[Id]
    Set suite variable                  ${fundingprogram}
    ${contact} =                        API Create Contact
    Store Session Record                Contact     ${contact}[Id]
    Set suite variable                  ${contact}
    ${funding_request} =                API Create Funding Request
    ...                                 ${fundingprogram}[Id]     ${contact}[Id]
    Store Session Record                ${ns}Funding_Request__c         ${funding_request}[Id]
    Set suite variable                  ${funding_request}
    ${awardedfunding_request} =         API Create Funding Request
    ...                                 ${fundingprogram}[Id]     ${contact}[Id]
    ...                                 ${ns}Status__c=Awarded      ${ns}Awarded_Amount__c=100000
    Store Session Record                ${ns}Funding_Request__c     ${awardedfunding_request}[Id]
    Set suite variable                  ${awardedfunding_request}
    ${fr_name} =                        Generate New String
    Set suite variable                  ${fr_name}
    ${req_name} =                       Generate New String
    Set suite variable                  ${req_name}

*** Test Case ***
Create Funding Request Via API
    [Documentation]                             Creates a Funding Request via API.
    ...                                         Verifies that Funding Request is created and
    ...                                         displays under recently viewed Funding Request
    [tags]                                      feature:FundingRequest
    Go To Page                                  Listing          ${ns}Funding_Request__c
    Click Link With Text                        ${funding_request}[Name]
    Wait Until Loading Is Complete
    Current Page Should Be                      Details          Funding_Request__c
    Validate Field Value                        Status  contains    In progress
    Validate Field Value                        Funding Request Name    contains
    ...                                         ${funding_request}[Name]

Create Funding Request via UI
     [Documentation]                            Creates a Funding Request via UI.
     ...                                        Verifies that Funding Request is created.
     [tags]                                     feature:FundingRequest
     Go To Page                                 Listing          ${ns}Funding_Request__c
     Click Object Button                        New
     Wait Until Modal Is Open
     Populate Modal Form                        Funding Request Name=${fr_name}
     ...                                        Application Date=15
     ...                                        Funding Program=${fundingprogram}[Name]
     ...                                        Applying Contact=${contact}[Name]
     Click Save
     Wait Until Modal Is Closed
     Current Page Should Be                     Details           Funding_Request__c
     Validate Field Value                       Funding Request Name    contains    ${fr_name}

Add a Requirement on a Funding Request
    [Documentation]                             Creates a Funding Request via API.
    ...                                         Go to Requirements and add a new Requirement
    [tags]                                      feature:Requirements
    Go To Page                                  Listing          ${ns}Funding_Request__c
    Click Link With Text                        ${funding_request}[Name]
    Wait Until Loading Is Complete
    Current Page Should Be                      Details          Funding_Request__c
    Click Tab                                   Requirements
    Click Related List Wrapper Button           Requirements                               New
    Wait For Modal                              New                                  Requirement
    Populate Modal Form                         Requirement Name=${req_name}
    ...                                         Due Date=15
    ...                                         Primary Contact=${contact}[Name]
    Click Save
    Wait Until Modal Is Closed
    Click Related List Link                     ${req_name}
    Current Page Should Be                      Details          Funding_Request__c
    Validate Field Value                        Requirement Name    contains    ${req_name}
    Validate Field Value                        Primary Contact    contains    ${contact}[Name]

Add a Disbursement on an Awarded Funding Request
    [Documentation]                             Creates a Funding Request via API.
    ...                                         Go to Disbursements and add a new Disbursement
    [tags]                                      feature:Disbursements
    Go To Page                                  Listing          ${ns}Funding_Request__c
    Click Link With Text                        ${awardedfunding_request}[Name]
    Wait Until Loading Is Complete
    Current Page Should Be                      Details          Funding_Request__c
    Click Button                                Create Disbursements
    Wait Until Modal Is Open
    Populate Modal Form                         Number of Disbursements=4
    ...                                         Interval=4
    ...                                         Amount=80000
    Click Button                                Calculate
    Wait Until Element Is Visible               text:Scheduled Date
    Save Disbursement
    Current Page Should Be                      Details          Funding_Request__c
    Validate Field Value                        Unpaid Disbursements    contains    $80,000.00
    Validate Field Value                        Available for Disbursement  contains    $20,000.00