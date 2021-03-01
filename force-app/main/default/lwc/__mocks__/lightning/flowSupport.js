/**
 * FLOW ATTRIBUTE CHANGE EVENT:
 * Event for flow runtime contained components to fire to inform the runtime that a component property has changed.
 */
export class FlowAttributeChangeEvent extends CustomEvent {
    constructor(property, value) {
        super("lightning__flowattributechange", {
            composed: true,
            bubbles: true,
            detail: { value, property },
        });
    }
}

/**
 * BASE FLOW NAVIGATION EVENT:
 * Base flow runtime navigation event to request navigation to another screen or to complete the flow.
 */
class BaseFlowNavigationEvent extends CustomEvent {
    constructor(navigationTarget) {
        super("lightning__flownavigation", {
            composed: true,
            bubbles: true,
            detail: { navigationTarget },
        });
    }
}

/**
 * FLOW NAVIGATION EVENT -- BACK:
 * Flow navigation event that requests navigation to the previous screen.
 */
export class FlowNavigationBackEvent extends BaseFlowNavigationEvent {
    constructor() {
        super("BACK");
    }
}

/**
 * FLOW NAVIGATION EVENT -- NEXT:
 * Flow navigation event that requests navigation to the next screen.
 */
export class FlowNavigationNextEvent extends BaseFlowNavigationEvent {
    constructor() {
        super("NEXT");
    }
}

/**
 * FLOW NAVIGATION EVENT -- PAUSE:
 * Flow navigation event that requests the runtime pause the flow.
 */
export class FlowNavigationPauseEvent extends BaseFlowNavigationEvent {
    constructor() {
        super("PAUSE");
    }
}

/**
 * FLOW NAVIGATION EVENT -- NEXT:
 * Flow navigation event that requests the runtime terminate the flow.
 */
export class FlowNavigationFinishEvent extends BaseFlowNavigationEvent {
    constructor() {
        super("FINISH");
    }
}
