({
    getApplicationFormApiName: function (component) {
        var fieldApiNameAction = component.get(
            "c.getFundingProgramApplicationFormApiName"
        );
        fieldApiNameAction.setCallback(this, function (response) {
            let state = response.getState();
            let returnValue = response.getReturnValue();
            if (state === "SUCCESS") {
                let fields = [returnValue];
                component.set("v.fields", fields);
                component.set("v.applicationFormApiName", returnValue);
            }
        });

        $A.enqueueAction(fieldApiNameAction);
    },

    showToastError: function () {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            type: "error",
            message: $A.get("$Label.c.Unknown_Error")
        });
        toastEvent.fire();
    },

    closeModal: function (component) {
        component.set("v.isModalOpen", false);
    }
});
