# * Copyright (c) 2021, salesforce.com, inc.
# * All rights reserved.
# * SPDX-License-Identifier: BSD-3-Clause
# * For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/BSD-3-Clause
# *

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
            "/fundseekerportal/s", message="Current page is not a Fundseeker Portal"
        )
        self.selenium.wait_until_page_contains("Find Funding Opportunities")
