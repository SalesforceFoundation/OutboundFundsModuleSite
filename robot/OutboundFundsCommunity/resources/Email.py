import random
import requests
import re
import string
from BaseObjects import BaseOutboundFundsCommunityPage
from cumulusci.robotframework.utils import selenium_retry
from OutboundFundsCommunity import outboundfundscommunity_lex_locators

@selenium_retry
class Email(BaseOutboundFundsCommunityPage):
    def get_tag(self, email):
        split = re.split("[.@]", email)
        tag = split[1]
        return tag

    def generate_random_password(self):
        """Generates a random community password"""
        letters = string.ascii_letters
        num = string.digits
        all = letters + num
        password = "".join(random.sample(all, 15))
        return password

    def set_new_password(self, password):
        """Sets new password for user"""
        locator_new_password_input = outboundfundscommunity_lex_locators["password"][
            "new_password"
        ]
        locator_confirm_password_input = outboundfundscommunity_lex_locators[
            "password"
        ]["confirm_password"]
        locator_change_password_button = outboundfundscommunity_lex_locators[
            "password"
        ]["change_password"]
        new_password_input = self.selenium.driver.find_element_by_xpath(
            locator_new_password_input
        )
        new_password_input.send_keys(password)
        confirm_password_input = self.selenium.driver.find_element_by_xpath(
            locator_confirm_password_input
        )
        confirm_password_input.send_keys(password)
        self.selenium.click_element(locator_change_password_button)
