"""
 * Copyright (c) 2021, salesforce.com, inc.
 * All rights reserved.
 * SPDX-License-Identifier: BSD-3-Clause
 * For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/BSD-3-Clause
 *
"""

import logging
import random
import string
import warnings

from BaseObjects import BaseOutboundFundsCommunityPage
from robot.libraries.BuiltIn import RobotNotRunningError
from locators_51 import outboundfundscommunity_lex_locators as locators_51
from cumulusci.robotframework.utils import selenium_retry, capture_screenshot_on_error

locators_by_api_version = {
    51.0: locators_51,  # Spring '21
}
# will get populated in _init_locators
outboundfundscommunity_lex_locators = {}


@selenium_retry
class OutboundFundsCommunity(BaseOutboundFundsCommunityPage):
    ROBOT_LIBRARY_SCOPE = "GLOBAL"
    ROBOT_LIBRARY_VERSION = 1.0

    def __init__(self, debug=False):
        self.debug = debug
        self.current_page = None
        self._session_records = []
        # Turn off info logging of all http requests
        logging.getLogger("requests.packages.urllib3.connectionpool").setLevel(
            logging.WARN
        )
        self._init_locators()

    def _init_locators(self):
        try:
            client = self.cumulusci.tooling
            response = client._call_salesforce(
                "GET", "https://{}/services/data".format(client.sf_instance)
            )
            self.latest_api_version = float(response.json()[-1]["version"])
            if self.latest_api_version not in locators_by_api_version:
                warnings.warn(
                    "Could not find locator library for API %d"
                    % self.latest_api_version
                )
                self.latest_api_version = max(locators_by_api_version.keys())
        except RobotNotRunningError:
            # We aren't part of a running test, likely because we are
            # generating keyword documentation. If that's the case, assume
            # the latest supported version
            self.latest_api_version = max(locators_by_api_version.keys())
        locators = locators_by_api_version[self.latest_api_version]
        outboundfundscommunity_lex_locators.update(locators)

    def get_namespace_prefix(self, name):
        parts = name.split("__")
        if parts[-1] == "c":
            parts = parts[:-1]
        if len(parts) > 1:
            return parts[0] + "__"
        else:
            return ""

    def get_obf_namespace_prefix(self):
        if not hasattr(self.cumulusci, "_describe_result"):
            self.cumulusci._describe_result = self.cumulusci.sf.describe()
        objects = self.cumulusci._describe_result["sobjects"]
        fundingprogram_object = [o for o in objects if o["label"] == "Funding Program"][
            0
        ]
        return self.get_namespace_prefix(fundingprogram_object["name"])

    def _check_if_element_exists(self, xpath):
        """Checks if the given xpath exists
        this is only a helper function being called from other keywords
        """
        elements = int(self.selenium.get_element_count(xpath))
        return True if elements > 0 else False

    def check_if_element_exists(self, xpath):
        """Checks if an element with given xpath exists"""
        elements = self.selenium.get_element_count(xpath)
        return True if elements > 0 else False

    def new_random_string(self, len=5):
        """Generate a random string of fixed length """
        return "".join(random.choice(string.ascii_lowercase) for _ in range(len))

    def generate_new_string(self, prefix="Robot Test"):
        """Generates a random string with Robot Test added as prefix"""
        return "{PREFIX} {RANDOM}".format(
            PREFIX=prefix, RANDOM=self.new_random_string(len=5)
        )

    def random_email(self, prefix="robot_", suffix="example.com"):
        """
        Return a random fake email address.
        :param prefix: Some text to put in front of the randomized part of the username.
                   Defaults to "robot_"
        :type  prefix: str
        :param suffix: The domain part of the email address.
                   Defaults to "example.com"
        :type  suffix: str
        :returns: The fake email address.
        :rtype: str
        """
        return "{PREFIX}{RANDOM}@{SUFFIX}".format(
            PREFIX=prefix, RANDOM=self.new_random_string(len=5), SUFFIX=suffix
        )

    def click_link_with_text(self, text):
        """Click on link with passed text"""
        locator = outboundfundscommunity_lex_locators["link"].format(text)
        self.selenium.wait_until_page_contains_element(locator)
        element = self.selenium.driver.find_element_by_xpath(locator)
        self.selenium.driver.execute_script("arguments[0].click()", element)

    def click_save(self):
        """Click Save button in modal's footer"""
        locator = outboundfundscommunity_lex_locators["new_record"][
            "footer_button"
        ].format("Save")
        self.selenium.scroll_element_into_view(locator)
        self.salesforce._jsclick(locator)

    def validate_field_value(self, field, status, value, section=None):
        """If status is 'contains' then the specified value should be present in the field
        'does not contain' then the specified value should not be present in the field
        """
        if section is not None:
            section = "text:" + section
            self.selenium.scroll_element_into_view(section)
        list_found = False
        locators = outboundfundscommunity_lex_locators["confirm"].values()
        if status == "contains":
            for i in locators:
                print("inside for loop")
                locator = i.format(field, value)
                print(locator)
                if self.check_if_element_exists(locator):
                    print(f"element exists {locator}")
                    actual_value = self.selenium.get_webelement(locator).text
                    print(f"actual value is {actual_value}")
                    assert (
                        value == actual_value
                    ), "Expected {} value to be {} but found {}".format(
                        field, value, actual_value
                    )
                    list_found = True
                    break
        if status == "does not contain":
            for i in locators:
                locator = i.format(field, value)
                if self.check_if_element_exists(locator):
                    print(f"locator is {locator}")
                    raise Exception(f"{field} should not contain value {value}")
            list_found = True

        assert list_found, "locator not found"

    def click_tab(self, label):
        """Click on a tab on a record page"""
        locator = outboundfundscommunity_lex_locators["tab"]["tab_header"].format(label)
        self.selenium.wait_until_element_is_enabled(
            locator, error="Tab button is not available"
        )
        element = self.selenium.driver.find_element_by_xpath(locator)
        self.selenium.driver.execute_script("arguments[0].click()", element)

    @capture_screenshot_on_error
    def click_flexipage_dropdown(self, title, value):
        """Click the lightning dropdown to open it and select value"""
        locator = outboundfundscommunity_lex_locators["new_record"][
            "flexipage-list"
        ].format(title)
        option = outboundfundscommunity_lex_locators["span"].format(value)
        self.selenium.wait_until_page_contains_element(locator)
        self.selenium.scroll_element_into_view(locator)
        element = self.selenium.driver.find_element_by_xpath(locator)
        try:
            self.selenium.get_webelement(locator).click()
            self.wait_for_locator("flexipage-popup")
            self.selenium.scroll_element_into_view(option)
            self.selenium.click_element(option)
        except Exception:
            self.builtin.sleep(1, "waiting for a second and retrying click again")
            self.selenium.driver.execute_script("arguments[0].click()", element)
            self.wait_for_locator("flexipage-popup")
            self.selenium.scroll_element_into_view(option)
            self.selenium.click_element(option)

    def click_related_list_wrapper_button(self, heading, button_title):
        """ loads the related list  and clicks on the button on the list """
        locator = outboundfundscommunity_lex_locators["related"]["flexi_button"].format(
            heading, button_title
        )
        self.salesforce._jsclick(locator)
        self.salesforce.wait_until_loading_is_complete()

    def login_to_community_as_user(self):
        """ Click on 'Show more actions' drop down and select the option to log in to community as user """
        locator_actions = outboundfundscommunity_lex_locators["action_locators"][
            "show_more_actions"
        ]
        locator_login_link = outboundfundscommunity_lex_locators["action_locators"][
            "login_to_community"
        ]

        self.selenium.wait_until_page_contains_element(
            locator_actions,
            error=f"Show more actions drop down with locator '{locator_actions}' is not available on the page",
        )
        self.selenium.click_element(locator_actions)
        self.selenium.wait_until_page_contains_element(
            locator_login_link,
            error="'Log in to Experience as user' option is not available in the list of actions",
        )
        self.selenium.click_element(locator_login_link)

    @capture_screenshot_on_error
    def click_portal_tab(self, title):
        """Click on Navigation Tab in Community"""
        locator = outboundfundscommunity_lex_locators["link"].format(title)
        if self.check_if_element_exists(locator):
            ele = self.selenium.get_webelement(locator)
            classname = ele.get_attribute("class")
            if "comm-hide" in classname:
                self.click_more_button()
            else:
                self.selenium.click_element(locator)

    @capture_screenshot_on_error
    def populate_modal_form(self, **kwargs):
        """This keyword validates , identifies the element and populates value"""
        for key, value in kwargs.items():
            if key in (
                "Application Date",
                "Close Date",
                "Due Date",
                "Completed date",
            ):
                locator = outboundfundscommunity_lex_locators["new_record"][
                    "lightning_datepicker"
                ].format(key)
                if self.check_if_element_exists(locator):
                    element = self.selenium.driver.find_element_by_xpath(locator)
                    self.selenium.driver.execute_script(
                        "arguments[0].scrollIntoView(true)", element
                    )
                    self.selenium.wait_until_element_is_visible(locator)
                    self.selenium.set_focus_to_element(locator)
                    self.select_from_date_picker(key, value)
                else:
                    self.builtin.log(f"Element {key} not found")

            elif key in ("Status", "Type", "Application Form"):
                locator = outboundfundscommunity_lex_locators["new_record"][
                    "dropdown_field"
                ].format(key)
                selection_value = outboundfundscommunity_lex_locators["new_record"][
                    "dropdown_value"
                ].format(value)
                if self.check_if_element_exists(locator):
                    self.selenium.set_focus_to_element(locator)
                    self.selenium.wait_until_element_is_visible(locator)
                    self.selenium.scroll_element_into_view(locator)
                    self.salesforce._jsclick(locator)
                    self.selenium.wait_until_element_is_visible(selection_value)
                    self.selenium.click_element(selection_value)

            elif key in (
                "Funding Program",
                "Applying Contact",
                "Assigned",
                "Primary Contact",
            ):
                self.salesforce.populate_lookup_field(key, value)

            elif key in (
                "Funding Request Name",
                "Description",
                "Requested Amount",
                "Number of Disbursements",
                "Interval",
                "Amount",
                "Requirement Name",
                "Funding Program Name",
            ):
                locator = outboundfundscommunity_lex_locators["new_record"][
                    "field_input"
                ].format(key)
                self.salesforce._populate_field(locator, value)
            else:
                raise Exception("Locator for {} is not found on the page".format(key))

    @capture_screenshot_on_error
    def click_related_list_link(self, text):
        """Click on link with passed text"""
        locator = outboundfundscommunity_lex_locators["flexi_link"].format(text)
        self.selenium.wait_until_page_contains_element(locator)
        element = self.selenium.driver.find_element_by_xpath(locator)
        self.selenium.driver.execute_script("arguments[0].click()", element)

    @capture_screenshot_on_error
    def save_disbursement(self):
        """Click Save Disbursement"""
        locator = outboundfundscommunity_lex_locators["details"]["button"].format(
            "Save"
        )
        self.selenium.set_focus_to_element(locator)
        self.selenium.get_webelement(locator).click()

    def select_from_date_picker(self, title, value):
        """Opens the date picker by clicking on the date picker icon given the title of the field and select a date"""
        locator = outboundfundscommunity_lex_locators["new_record"][
            "lightning_datepicker"
        ].format(title)
        self.selenium.scroll_element_into_view(locator)
        self.selenium.set_focus_to_element(locator)
        self.selenium.get_webelement(locator).click()
        locator_date = outboundfundscommunity_lex_locators["new_record"][
            "datepicker"
        ].format(value)
        self.selenium.set_focus_to_element(locator_date)
        self.selenium.get_webelement(locator_date).click()
