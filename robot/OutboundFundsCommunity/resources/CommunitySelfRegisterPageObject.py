from cumulusci.robotframework.pageobjects import BasePage
from cumulusci.robotframework.pageobjects import pageobject
from BaseObjects import BaseOutboundFundsCommunityPage
from OutboundFundsCommunity import outboundfundscommunity_lex_locators


@pageobject("Register", "Community")
class CommunityRegisterPage(BaseOutboundFundsCommunityPage, BasePage):
    def _is_current_page(self):
        """Verify we are on the Portal Registration Page
        by verifying that the url contains '/fundingprograms/s/login/SelfRegister'
        """
        self.selenium.wait_until_location_contains(
            "/fundseekerportal/s/login/SelfRegister",
            message="Current page is not Self Register Page",
        )
        self.selenium.wait_until_page_contains(
            "Join the community to receive personalized information and customer support."
        )

    def fill_out_self_registration_form(self, first_name, last_name, email):
        """Fills out self-registration form"""
        locator_first_name = outboundfundscommunity_lex_locators["guest_user"][
            "first_name"
        ]
        locator_last_name = outboundfundscommunity_lex_locators["guest_user"][
            "last_name"
        ]
        locator_email = outboundfundscommunity_lex_locators["guest_user"]["email"]
        input_first_name = self.selenium.driver.find_element_by_xpath(
            locator_first_name
        )
        input_first_name.send_keys(first_name)
        input_last_name = self.selenium.driver.find_element_by_xpath(locator_last_name)
        input_last_name.send_keys(last_name)
        input_email = self.selenium.driver.find_element_by_xpath(locator_email)
        input_email.send_keys(email)

    def click_sign_up_button(self):
        """Clicks sign up button"""
        locator_sign_up_button = outboundfundscommunity_lex_locators["guest_user"][
            "sign_up_button"
        ]
        self.selenium.click_element(locator_sign_up_button)


@pageobject("CheckPasswordResetEmail", "Community")
class CommunityCheckPasswordResetEmailPage(BaseOutboundFundsCommunityPage, BasePage):
    def _is_current_page(self):
        """Verify we are on the CheckPasswordResetEmail page
        by verifying that the url contains '/fundingprograms/s/login/CheckPasswordResetEmail'
        """
        locator_now_check_your_email = outboundfundscommunity_lex_locators[
            "guest_user"
        ]["now_check_your_email"]
        self.selenium.wait_until_location_contains(
            "/fundseekerportal/s/login/CheckPasswordResetEmail",
            message="Current page is not CheckPasswordResetEmail Page",
        )
        self.selenium.wait_until_page_contains_element(
            locator_now_check_your_email,
            error="CheckPasswordResetEmail page did not appear",
        )


@pageobject("ForgotPassword", "Community")
class CommunityForgotPasswordPage(BaseOutboundFundsCommunityPage, BasePage):
    def _is_current_page(self):
        """Verify we are on the ForgotPassword page
        by verifying that the url contains '/fundingprograms/s/login/ForgotPassword'
        """
        self.selenium.wait_until_location_contains(
            "/fundseekerportal/s/login/ForgotPassword",
            message="Current page is not ForgotPassword Page",
        )

    def input_username(self, username):
        """Input username in forgot password page"""
        locator_username_input = outboundfundscommunity_lex_locators["password"][
            "username_input"
        ]
        username_input_box = self.selenium.driver.find_element_by_xpath(
            locator_username_input
        )
        username_input_box.send_keys(username)

    def click_reset_password(self):
        """Clicks Reset Password Button"""
        locator_reset_password = outboundfundscommunity_lex_locators["password"][
            "reset_password_button"
        ]
        self.selenium.click_element(locator_reset_password)
