from cumulusci.robotframework.pageobjects import HomePage
from cumulusci.robotframework.pageobjects import pageobject
from BaseObjects import BaseOutboundFundsCommunityPage


@pageobject("Home", "Community")
class CommunityHomePage(BaseOutboundFundsCommunityPage, HomePage):
    def _is_current_page(self):
        """Verify we are on the Portal Home Page
        by verifying that the url contains '/outboundfunds'
        """
        self.selenium.wait_until_location_contains(
            "/outboundfunds/s", message="Current page is not a Community Portal"
        )
        self.selenium.wait_until_page_contains("Your OFM Fundings")
