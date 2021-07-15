# * Copyright (c) 2021, salesforce.com, inc.
# * All rights reserved.
# * SPDX-License-Identifier: BSD-3-Clause
# * For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/BSD-3-Clause
# *

from cumulusci.robotframework.pageobjects import DetailPage
from cumulusci.robotframework.pageobjects import BasePage
from cumulusci.robotframework.pageobjects import pageobject
from BaseObjects import BaseOutboundFundsCommunityPage
from OutboundFundsCommunity import outboundfundscommunity_lex_locators


@pageobject("Details", "Funding Request")
class CommunityFundingRequestDetailPage(BaseOutboundFundsCommunityPage, DetailPage):
    def _is_current_page(self):
        """Verify we are on the Community Funding Request Details Page
        by verifying that the url contains '/s/funding-request'
        """
        self.selenium.wait_until_location_contains(
            "/s/funding-request", message="Current page is not a Funding Request Page"
        )
        self.selenium.wait_until_page_contains("Instructions for Applying")

    def submit_application(self):
        """Click on Submit Application button on Application Details page"""
        locator = outboundfundscommunity_lex_locators["community_locators"][
            "quick_action_button"
        ].format("Submit Application")
        self.selenium.set_focus_to_element(locator)
        self.selenium.click_element(locator)

    def click_edit(self):
        """Click on Edit button on Application Details page"""
        locator = outboundfundscommunity_lex_locators["community_locators"][
            "quick_action_button"
        ].format("Edit")
        self.selenium.set_focus_to_element(locator)
        self.selenium.click_element(locator)


@pageobject("Edit", "Funding Request")
class EditFundingRequestPage(BaseOutboundFundsCommunityPage, BasePage):
    def _is_current_page(self):
        """Verify we are on the Edit Funding Request Modal"""
        header_locator = outboundfundscommunity_lex_locators["community_locators"][
            "modal_header"
        ].format("Edit")
        self.selenium.wait_until_page_contains_element(
            header_locator,
            error="Header title is not 'Edit' as expected",
        )

    def edit_application(self, **kwargs):
        for key, value in kwargs.items():
            if key in ("Requested Amount", "Requested For"):
                locator = outboundfundscommunity_lex_locators["new_record"][
                    "text_field"
                ].format(key)
                self.selenium.click_element(locator)
                self.selenium.clear_element_text(locator)
                self.selenium.get_webelement(locator).send_keys(value)
            else:
                raise Exception("Locator for {} is not found on the page".format(key))

    def save_application(self):
        locator = outboundfundscommunity_lex_locators["modal_footer"]
        self.selenium.set_focus_to_element(locator)
        self.selenium.get_webelement(locator).click()
