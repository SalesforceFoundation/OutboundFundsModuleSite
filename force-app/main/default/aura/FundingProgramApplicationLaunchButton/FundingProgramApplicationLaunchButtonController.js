({
    doInit: function (component, event, helper) {
        helper.getApplicationFormApiName(component);
    },

    openModal: function (component, event, helper) {
        let recordId = component.get("v.recordId");
        let applicationFormApiName = component.get("v.applicationFormApiName");
        let fundingProgramFlowAPIName = component.get(
            "v.fundingProgram." + applicationFormApiName
        );

        let recordLoadError = component.get("v.recordLoadError");
        let flowInputVariables = [{ name: "recordId", type: "String", value: recordId }];

        if (fundingProgramFlowAPIName && !recordLoadError) {
            console.log("Entered");
            component.set("v.isModalOpen", true);
            let flow = component.find("applyFlow");
            flow.startFlow(fundingProgramFlowAPIName, flowInputVariables);
        } else {
            helper.showToastError();
        }
    },

    closeModal: function (component, event, helper) {
        helper.closeModal(component);
    },

    loadFundingProgramData: function (component, event, helper) {
        component.set("v.displayButton", true);
    },

    handleFlowStatusChange: function (component, event, helper) {
        if (event.getParam("status") === "FINISHED") {
            helper.closeModal(component);
        }
    }
});
