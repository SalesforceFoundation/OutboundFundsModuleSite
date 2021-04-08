/*
 * Copyright (c) 2021, salesforce.com, inc.
 * All rights reserved.
 * SPDX-License-Identifier: BSD-3-Clause
 * For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/BSD-3-Clause
 */

/**
 * For the original lightning/navigation mock that comes by default with
 * @salesforce/sfdx-lwc-jest, see:
 * https://github.com/salesforce/sfdx-lwc-jest/blob/master/src/lightning-stubs/navigation/navigation.js
 */
export const CurrentPageReference = jest.fn();

const NAVIGATE_SYMBOL = "Navigate";
const GENERATE_URL_SYMBOL = "GenerateUrl";

let _navigatePageReference,
    _generatePageReference,
    _replace,
    _url = "https://www.example.com";

const Navigate = Symbol(NAVIGATE_SYMBOL);
const GenerateUrl = Symbol(GENERATE_URL_SYMBOL);
export const NavigationMixin = (Base) => {
    return class extends Base {
        [Navigate](pageReference, replace) {
            _navigatePageReference = pageReference;
            _replace = replace;
        }
        [GenerateUrl](pageReference) {
            _generatePageReference = pageReference;
            return new Promise((resolve) => resolve(_url));
        }
    };
};
NavigationMixin.Navigate = Navigate;
NavigationMixin.GenerateUrl = GenerateUrl;

/*
 * Tests do not have access to the internals of this mixin used by the
 * component under test so save a reference to the arguments the Navigate method is
 * invoked with and provide access with this function.
 */
export const getNavigateCalledWith = () => {
    return {
        pageReference: _navigatePageReference,
        replace: _replace,
    };
};

export const getGenerateUrlCalledWith = () => ({
    pageReference: _generatePageReference,
});

export const setGenerateUrl = (url) => {
    _url = url;
};

export const resetNavigationMixinMocks = () => {
    _navigatePageReference = undefined;
    _generatePageReference = undefined;
    _replace = undefined;
    _url = "https://www.example.com";
};
