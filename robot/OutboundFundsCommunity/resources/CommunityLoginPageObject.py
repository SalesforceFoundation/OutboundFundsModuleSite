from cumulusci.robotframework.pageobjects import BasePage
from cumulusci.robotframework.pageobjects import pageobject
from BaseObjects import BaseOutboundFundsCommunityPage
from OutboundFundsCommunity import outboundfundscommunity_lex_locators


@pageobject("Login", "Community")
class CommunityLoginPage(BaseOutboundFundsCommunityPage, BasePage):
    def _is_current_page(self):
        """Verify we are on the Portal Login Page
        by verifying that the url contains '/fundingprograms/s/login'
        """
        self.selenium.wait_until_location_contains(
            "/fundseekerportal/s/login/", message="Current page is not a Login Page"
        )
        self.selenium.wait_until_page_contains("Forgot your password?")

    def click_forgot_your_password_link(self):
        """Click forgot your password link"""
        locator_forgot_your_password = outboundfundscommunity_lex_locators["password"][
            "forgot_your_password_link"
        ]
        self.selenium.click_element(locator_forgot_your_password)
