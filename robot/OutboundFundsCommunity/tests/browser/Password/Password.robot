*** Settings ***

Resource       robot/OutboundFundsCommunity/resources/OutboundFundsCommunity.robot
Library        robot/OutboundFundsCommunity/resources/Email.py
Library        cumulusci.robotframework.PageObjects
...            robot/OutboundFundsCommunity/resources/ContactPageObject.py
...            robot/OutboundFundsCommunity/resources/GuestUserPageObject.py
...            robot/OutboundFundsCommunity/resources/CommunityLoginPageObject.py
...            robot/OutboundFundsCommunity/resources/CommunitySelfRegisterPageObject.py
...            robot/OutboundFundsCommunity/resources/CommunityHomePageObject.py

Suite Setup     Run keywords
...             Open Test Browser
...             Setup Test Data
Suite Teardown  Capture Screenshot and Delete Records and Close Browser

*** Keywords ***
Setup Test Data
    ${ns}=                                      Get OBF Namespace Prefix
    Set suite variable                          ${ns}
    ${username} =                               API Get User Name for User
    ...                                         Walker
    Set Suite Variable                          ${username}
    ${community_url} =                          Get Community URL
    Set Suite Variable                          ${community_url}
    ${email} =                                  API Get Email for User      Walker
    Set Suite Variable                          ${email}
    ${tag} =                                    Get Tag         ${email}
    Set Suite Variable                          ${tag}
    ${random_password} =                        Generate Random Password
    Set Suite Variable                          ${random_password}
    Enable Public Access for Guest User
    API Activate Community

*** Test Cases ***
Forgot Password
    [Documentation]                             Go through password reset flow
    [tags]                                      feature:Password
    Go To                                       ${community_url}
    Current Page Should Be                      Home    Guest User Community
    Go To Log In Page
    Current Page Should Be                      Login   Community
    Click Forgot Your Password Link
    Current Page Should Be                      ForgotPassword  Community
    Input Username                              ${username}
    Click Reset Password
    Current Page Should Be                      CheckPasswordResetEmail     Community

