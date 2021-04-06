"""
 * Copyright (c) 2021, salesforce.com, inc.
 * All rights reserved.
 * SPDX-License-Identifier: BSD-3-Clause
 * For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/BSD-3-Clause
 *
"""

from cumulusci.robotframework.pageobjects import DetailPage
from cumulusci.robotframework.pageobjects import ListingPage
from cumulusci.robotframework.pageobjects import pageobject
from BaseObjects import BaseOutboundFundsCommunityPage


@pageobject("Listing", "Contact")
class ContactListingPage(BaseOutboundFundsCommunityPage, ListingPage):
    object_name = "Contact"


@pageobject("Detail", "Contact")
class ContactDetailPage(BaseOutboundFundsCommunityPage, DetailPage):
    object_name = "Contact"
