# * Copyright (c) 2021, salesforce.com, inc.
# * All rights reserved.
# * SPDX-License-Identifier: BSD-3-Clause
# * For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/BSD-3-Clause
# *

from cumulusci.robotframework.pageobjects import ListingPage
from cumulusci.robotframework.pageobjects import DetailPage
from cumulusci.robotframework.pageobjects import pageobject
from BaseObjects import BaseOutboundFundsCommunityPage


@pageobject("Listing", "Funding_Request__c")
class FundingRequestListingPage(BaseOutboundFundsCommunityPage, ListingPage):
    def _is_current_page(self):
        """Verify we are on the Funding Request Listing page
        by verifying that the url contains '/view'
        """
        self.selenium.location_should_contain(
            "Funding_Request__c/list?",
            message="Current page is not a Funding Request List view",
        )


@pageobject("Details", "Funding_Request__c")
class FundingRequestDetailPage(BaseOutboundFundsCommunityPage, DetailPage):
    def _is_current_page(self):
        """Verify we are on the Funding Request detail page
        by verifying that the url contains '/view'
        """
        self.selenium.wait_until_location_contains(
            "/view", timeout=60, message="Detail page did not load in 1 min"
        )
