from robot.libraries.BuiltIn import BuiltIn


class BaseOutboundFundsCommunityPage:
    @property
    def OutboundFundsCommunity(self):
        return self.builtin.get_library_instance("OutboundFundsCommunity")

    @property
    def pageobjects(self):
        return self.builtin.get_library_instance("cumulusci.robotframework.PageObjects")

    @property
    def builtin(self):
        return BuiltIn()

    @property
    def cumulusci(self):
        return self.builtin.get_library_instance("cumulusci.robotframework.CumulusCI")

    @property
    def salesforce(self):
        return self.builtin.get_library_instance("cumulusci.robotframework.Salesforce")

    @property
    def selenium(self):
        return self.builtin.get_library_instance("SeleniumLibrary")
