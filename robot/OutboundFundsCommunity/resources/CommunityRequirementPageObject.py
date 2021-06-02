from cumulusci.robotframework.pageobjects import DetailPage
from cumulusci.robotframework.pageobjects import pageobject
from BaseObjects import BaseOutboundFundsCommunityPage
from OutboundFundsCommunity import outboundfundscommunity_lex_locators
import time


@pageobject("Details", "Requirement")
class CommunityRequirementDetailPage(BaseOutboundFundsCommunityPage, DetailPage):
    def _is_current_page(self):
        """Verify we are on the Community Requirement Details Page
        by verifying that the url contains '/s/requirement/'
        """
        self.selenium.wait_until_location_contains(
            "/fundseekerportal/s/requirement/",
            message="Current page is not a Requirement Page",
        )
        time.sleep(1)
        self.selenium.wait_until_page_contains("Requirement Attachments")

    def scroll_to_upload_files(self):
        """scroll the page to Upload Files Component"""
        locator = outboundfundscommunity_lex_locators["upload_files"]["file_manager"]
        self.selenium.scroll_element_into_view(locator)
        self.selenium.wait_until_element_is_visible(locator)

    def submit_requirement(self):
        locator = outboundfundscommunity_lex_locators["community_locators"][
            "quick_action_button"
        ].format("Submit")
        self.selenium.set_focus_to_element(locator)
        self.selenium.click_element(locator)
