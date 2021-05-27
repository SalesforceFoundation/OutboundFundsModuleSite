# * Copyright (c) 2021, salesforce.com, inc.
# * All rights reserved.
# * SPDX-License-Identifier: BSD-3-Clause
# * For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/BSD-3-Clause
# *

from cumulusci.robotframework.pageobjects import DetailPage
from cumulusci.robotframework.pageobjects import pageobject
from BaseObjects import BaseOutboundFundsCommunityPage


@pageobject("Details", "Disbursement__c")
class DisbursementsDetailPage(BaseOutboundFundsCommunityPage, DetailPage):
    def _is_current_page(self):
        """Verify we are on the Disbursements detail page
        by verifying that the url contains '/view'
        """
        self.selenium.wait_until_location_contains(
            "/view", timeout=60, message="Detail page did not load in 1 min"
        )
