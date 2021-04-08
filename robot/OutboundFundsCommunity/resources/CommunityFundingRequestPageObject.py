# * Copyright (c) 2021, salesforce.com, inc.
# * All rights reserved.
# * SPDX-License-Identifier: BSD-3-Clause
# * For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/BSD-3-Clause
# *

from cumulusci.robotframework.pageobjects import DetailPage
from cumulusci.robotframework.pageobjects import pageobject
from BaseObjects import BaseOutboundFundsCommunityPage


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
