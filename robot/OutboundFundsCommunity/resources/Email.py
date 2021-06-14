import random
import requests
import re
import string
from BaseObjects import BaseGrantsPage
from cumulusci.robotframework.utils import selenium_retry
from OutboundFundsCommunity import outboundfundscommunity_lex_locators


endpoint = "https://api.testmail.app/api/json?apikey=cc5a1174-6d74-46d4-9ee9-409cc1da75d1&namespace=gms"


@selenium_retry
class Email(BaseGrantsPage):
    def get_reset_password_url(self, tag):
        """Retrieves reset password URL from email sent to user"""
        params = {
            "tag": tag,
            "livequery": "true",
        }
        email_data = requests.get(endpoint, params=params, timeout=30)
        email_json = email_data.json()
        email_text = email_json["emails"][0]["text"]
        reset_password_url = re.search(r"(?P<url>https?://[^\s]+)", email_text).group(
            "url"
        )
        return reset_password_url

    def verify_submit_application_email_received(self, tag):
        """"Verifies if user received the submit application email"""
        params = {
            "tag": tag,
        }
        email_data = requests.get(endpoint, params=params, timeout=60)
        email_json = email_data.json()
        email_subject = email_json["emails"][0]["text"]
        substring = "Weve received your application and will be reviewing it soon"
        if substring in email_subject:
            pass
        else:
            raise Exception("Email not found")

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
