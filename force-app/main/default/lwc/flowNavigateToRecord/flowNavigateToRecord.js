import { LightningElement, api } from "lwc";
import { NavigationMixin } from "lightning/navigation";

export default class FlowNavigateToRecord extends NavigationMixin(LightningElement) {
    @api recordId;

    connectedCallback() {
        this[NavigationMixin.Navigate]({
            type: "standard__recordPage",
            attributes: {
                recordId: this.recordId,
                actionName: "view",
            },
        });
    }
}
