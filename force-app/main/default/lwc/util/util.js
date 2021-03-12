import { ShowToastEvent } from "lightning/platformShowToastEvent";
//Used to get namespace from org
import isAddFilesVisibleField from "@salesforce/schema/outfunds__Requirement__c.IsAddFilesVisible__c";

/**
 * Returns if value equals undefined or null
 * @param {*} value - Anything
 */
export const isNull = (value) => {
    return value === undefined || value === null;
};

/**
 * @param label        If replacements is an Array, reference replacements by index,
 *                     e.g. {0}, {1}, similar to Apex's String.format(...).
 *                     Else if replacements is an Object, reference replacements
 *                     via key, e.g. {firstName}.
 * @param replacements Typically, an Array or Object
 */
export const formatLabel = (label, replacements) => {
    let formattedLabel = isNull(label) ? "" : label;
    if (replacements) {
        const t = typeof replacements;
        const args =
            "string" === t || "number" === t
                ? Array.prototype.slice.call(replacements)
                : replacements;
        for (let key in args) {
            if (Object.prototype.hasOwnProperty.call(args, key)) {
                formattedLabel = formattedLabel.replace(
                    new RegExp("\\{" + key + "\\}", "gi"),
                    args[key]
                );
            }
        }
    }

    return formattedLabel;
};

export const showToast = (lightningElement, title, message, variant) => {
    let mode = variant === "error" ? "sticky" : "pester";
    const toast = new ShowToastEvent({
        title: title,
        message: message,
        variant: variant,
        mode: mode,
    });
    lightningElement.dispatchEvent(toast);
};

export const debug = (data, logger = "log") => {
    console[logger](JSON.stringify(data, null, 2));
};

export const prefixNamespace = (value) => {
    let namespace = isAddFilesVisibleField.fieldApiName.substring(
        0,
        isAddFilesVisibleField.fieldApiName.indexOf("IsAddFilesVisible__c")
    );

    return namespace + value;
};

export default { formatLabel, isNull, showToast, prefixNamespace, debug };
