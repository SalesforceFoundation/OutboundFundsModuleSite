# * Copyright (c) 2021, salesforce.com, inc.
# * All rights reserved.
# * SPDX-License-Identifier: BSD-3-Clause
# * For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/BSD-3-Clause
# *

from cumulusci.robotframework.utils import capture_screenshot_on_error
from cumulusci.robotframework.pageobjects import ListingPage
from cumulusci.robotframework.pageobjects import DetailPage
from cumulusci.robotframework.pageobjects import pageobject
from BaseObjects import BaseOutboundFundsCommunityPage
from OutboundFundsCommunity import outboundfundscommunity_lex_locators


@pageobject("Listing", "Funding Program")
class CommunityFundingProgramPage(BaseOutboundFundsCommunityPage, ListingPage):
    def _is_current_page(self):
        """Verify we are on the Experience Builder Page
        by verifying that the url contains '/outfunds__Funding_Program__c/Default'
        """
        self.selenium.wait_until_location_contains(
            "/outfunds__Funding_Program__c/Default",
            message="Current page is not a Funding Program Listing Page",
        )


@pageobject("Details", "Funding Program")
class CommunityFundingProgramDetailPage(BaseOutboundFundsCommunityPage, DetailPage):
    @capture_screenshot_on_error
    def _is_current_page(self):
        """Verify we are on the Community Funding Program Detail Page
        by verifying that the Header Title 'Funding Program Name'
        """
        locator = outboundfundscommunity_lex_locators["community_locators"][
            "header"
        ].format("Funding Program")
        self.selenium.wait_until_page_contains_element(
            locator, error="Header title is not 'Funding Program' as expected"
        )

    def click_program_button(self, title):
        """Click on Apply Button on Community Funding Program Detail Page"""
        locator = outboundfundscommunity_lex_locators["community_locators"][
            "quick_action_button"
        ].format(title)
        self.selenium.set_focus_to_element(locator)
        self.selenium.click_element(locator)
        header_locator = outboundfundscommunity_lex_locators["header_title"].format(
            title
        )
        self.selenium.wait_until_page_contains_element(
            header_locator, error="Header title is not 'Apply' as expected"
        )

    def populate_apply_form(self, **kwargs):
        """Populates standard event form with the field-value pairs"""
        for key, value in kwargs.items():
            if key == "Requested Amount":
                if self.OutboundFundsCommunity.latest_api_version == 52.0:
                    locator = outboundfundscommunity_lex_locators[
                        "amount_field"
                    ].format(key)
                else:
                    locator = outboundfundscommunity_lex_locators["modal_field"].format(
                        key
                    )
                self.selenium.get_webelement(locator).send_keys(value)
            elif key == "Requested For":
                locator = outboundfundscommunity_lex_locators["modal_field"].format(key)
                self.selenium.get_webelement(locator).send_keys(value)
            else:
                raise Exception("Locator for {} is not found on the page".format(key))

    def click_next(self):
        """Click on Next button in Apply Modal"""
        locator = outboundfundscommunity_lex_locators["details"]["button"].format(
            "Next"
        )
        self.selenium.set_focus_to_element(locator)
        self.selenium.click_element(locator)
        self.selenium.wait_until_page_contains("Add attachments.")
        self.selenium.click_element(locator)
        self.selenium.wait_until_page_contains("Upload Documentation")

    def click_upload_modal_button(self, title):
        """Click Upload Modal button on an application"""
        locator = outboundfundscommunity_lex_locators["upload_files"][
            "upload_modal"
        ].format(title)
        self.selenium.get_webelement(locator).click()
