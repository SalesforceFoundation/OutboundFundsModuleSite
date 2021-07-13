from cumulusci.robotframework.pageobjects import HomePage
from cumulusci.robotframework.pageobjects import pageobject
from BaseObjects import BaseGrantsPage
from Grants import grants_lex_locators


@pageobject("Home", "Guest User Community")
class CommunityHomePage(BaseGrantsPage, HomePage):
    def _is_current_page(self):
        """Verify we are on the Guest User Portal Home Page
        by verifying that the url contains '/fundingprograms'
        """
        self.selenium.wait_until_location_contains(
            "/fundingprograms/s", message="Current page is not a Community Portal"
        )
        self.selenium.wait_until_page_contains("Our Grant Programs")

    def click_down_arrow(self):
        """Clicks down arrow to show more nav bar options"""
        locator_down_arrow = grants_lex_locators["guest_user"]["down_arrow"]
        self.selenium.click_element(locator_down_arrow)

    def click_funding_program_link(self):
        """Clicks Funding Program nav bar link from More dropdown"""
        locator_funding_program = grants_lex_locators["guest_user"]["funding_program"]
        self.selenium.click_element(locator_funding_program)

    def go_to_sign_up_page(self):
        """Clicks on sign up link"""
        locator_sign_up_link = grants_lex_locators["guest_user"]["sign_up"]
        self.selenium.click_element(locator_sign_up_link)

    def go_to_log_in_page(self):
        """Clicks on log in link"""
        locator_log_in_button = grants_lex_locators["password"]["log_in_button"]
        self.selenium.click_element(locator_log_in_button)
