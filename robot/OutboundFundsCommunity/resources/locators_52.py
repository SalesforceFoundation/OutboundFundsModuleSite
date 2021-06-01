# * Copyright (c) 2021, salesforce.com, inc.
# * All rights reserved.
# * SPDX-License-Identifier: BSD-3-Clause
# * For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/BSD-3-Clause
# *

# Spring '21 locators
outboundfundscommunity_lex_locators = {
    "app_launcher": {
        "view_all_button": "//button[text()='View All']",
        "app_link": "//p[contains(@title,'{}')]",
        "app_link_search_result": "//mark[contains(text(),'{}')]",
        "search_input": "//input[contains(@placeholder,'Search apps or items...')]",
    },
    "action_locators": {
        "community_login_error": "//div[contains(@class, 'slds-modal__container')]/div[contains(@class, 'modal-body')]/div[contains(text(), 'Looks like this portal user is not a member of a community or your community is down')]",
        "login_to_community": "//span[contains(text(), 'Log in to')]",
        "show_more_actions": "//div[contains(@class, 'windowViewMode-normal oneContent active lafPageHost')]//lightning-button-menu[contains(@class,'slds-dropdown-trigger')]/button[contains(@class, 'slds-button_icon-border-filled')]",
    },
    "community_locators": {
        "quick_action_button": "//a//div[@title='{}']",
        "header": "//h1//div[contains(@class, 'entityNameTitle') and text()='{}']",
        "header_title": "//h2[(contains(@class, 'slds-card__header-title'))]//span[contains(text(),'{}')] ",
        "list_view_dropdown": "//div[contains(@class, 'triggerLink')]//div/button[@title='Select List View']",
        "list_view_dropdown_options": "//li[contains(@role, 'presentation')]/a//span[contains(text(),'{}')]",
    },
    "new_record": {
        "label": "//label[text()='{}']",
        "title": "//h2[contains(@class, 'inlineTitle') and text()='{}']",
        "field_label": "//div[./*/*[text()='{}']]",
        "edit_title": "//h2[contains(@class, 'title') and text()='{}']",
        "list": "//div[contains(@class,'forcePageBlockSectionRow')]/div[contains(@class,'forcePageBlockItem')]/div[contains(@class,'slds-hint-parent')]/div[@class='slds-form-element__control']/div[.//span[text()='{}']][//div[contains(@class,'uiMenu')]//a[@class='select']]",
        "text_field": "//div[contains(@class, 'uiInput')][.//label[contains(@class, 'uiLabel')][.//span[text()='{}']]]//*[self::input or self::textarea]",
        "dropdown_field": "//lightning-combobox[./label[text()='{}']]/div//input[contains(@class,'combobox__input')]",
        "dropdown_value": "//div[contains(@class,'slds-listbox')]//lightning-base-combobox-item//span[text()='{}']",
        "flexipage-list": '//lightning-combobox[./label[text()="{}"]]//input[contains(@class,"combobox__input")]',
        "dd_selection": "//lightning-base-combobox-item[@data-value='{}']",
        "button": "//button[contains(@class, 'slds-button')  and text()='{}']",
        "lookup_field": "//div[contains(@class, 'autocompleteWrapper')]//input[@title='{}']",
        "lightning_datepicker": "//label[text()='{}']/following-sibling::div",
        "lightning_lookup": "//label[text()='{}']/following-sibling::div//input",
        "lookup_value": "//div[contains(@class, 'listContent')]//div[contains(@class, 'slds-truncate') and @title='{}']",
        "checkbox": "//div[contains(@class,'uiInputCheckbox')]/label/span[text()='{}']/../following-sibling::input[@type='checkbox']",
        "field_input": '//label[text()="{}"]/following-sibling::div//*[self::input or self::textarea]',
        "open_date_picker": "//div[@class='slds-form-element__control']/div[.//span[text()='{}']]//div//a[contains(@class,'datePicker-openIcon display')]",
        "datepicker_popup": "//table[@class='calGrid' and @role='grid']",
        "select_date": "//div[contains(@class,'uiDatePickerGrid')]/table[@class='calGrid']//*[text()='{}']",
        "text-field": "//label/span[text()='{}']/../following-sibling::input",
        "footer_button": "//lightning-button//button[text()='{}']",
        "datepicker": "//*[text()='{}']",
    },
    "confirm": {
        "check_value": "//div[contains(@class, 'forcePageBlockItem') or contains(@class, 'slds-form-element_stacked')][.//span[text()='{}']]//following-sibling::div[.//span[contains(@class, 'test-id__field-value')]]//*[text()='{}']",
        "check_status": "//div[contains(@class, 'field-label-container')][.//span[text()='{}']]//following-sibling::div[.//span[contains(@class, 'test-id__field-value')]]/span//lightning-formatted-text[text()='{}']",
        "check_numbers": "//div[contains(@class, 'field-label-container')][.//span[text()='{}']]//following-sibling::div[.//span[contains(@class, 'test-id__field-value')]]/span//lightning-formatted-number[text()='{}']",
    },
    "tab": {
        "tab_header": "//a[@class='slds-tabs_default__link' and text()='{}']",
        "record_detail_tab": "//a[contains(@data-label,'{}')]",
        "verify_header": "//div[contains(@class, 'entityNameTitle')]",
        "verify_details": "//div[contains(@class, 'slds-form-element')][.//span[text()='{}']]//following-sibling::div[.//span[contains(@class, 'test-id__field-value')]]/span",
    },
    "related": {
        "title": '//div[contains(@class, "slds-card")]/header[.//span[@title="{}"]]',
        "button": "//div[contains(@class, 'forceRelatedListSingleContainer')][.//img][.//span[@title='{}']]//a[@title='{}']",
        "count": "//tbody/tr/td[1]",
        "flexi_button": "//div[@lst-listviewmanagerheader_listviewmanagerheader][.//span[@title='{}']]//lightning-button//button[text()='{}']",
    },
    "details": {
        "button": "//button[contains(@class, 'slds-button') and text() = '{}']",
        "header": "//h1//div[contains(@class, 'entityNameTitle') and contains(text(),'{}')]",
    },
    "header_title": "//h2[(contains(@class, 'inlineTitle') or contains(@class, 'slds-text-heading') or contains(@class, 'listTitle') or contains(@class, 'slds-hyphenate')) and contains(text(),'{}')]",
    "link": "//a[contains(text(),'{}')]",
    "modal_field": "//label[contains(@class, 'uiLabel')][.//div[text()='{}']]//*[self::input or self::textarea]",
    "amount_field": "//lightning-formatted-rich-text/span[text()='{}']/../../../lightning-input/div/input",
    "flexi_link": "//a//span[text()='{}']",
    "flexipage-popup": "//div[contains(@class, 'slds-is-open')][contains(@class, 'slds-combobox')]",
<<<<<<< Updated upstream
    "upload_file": "//span[contains(@class,'slds-file-selector__button')]",
    "upload_modal": "//button//span[text()='{}']",
=======
    "upload_files": {
        "file_manager": "//span[text()='Or drop files']",
        "upload_button": "//input[@type='file' and contains(@class,'slds-file-selector__input')]",
        "upload_modal": "//button//span[text()='{}']",
        "delete_file": "//a//span[contains(@class, 'slds-assistive-text')and contains(text(),'Delete File')]",
    },
    "toast_message": "//div[contains(@class,'toastContent')]/child::div/span[text()=\"{}\"]",
    "toast_close": "//span[contains(@class, 'toastMessage') and text()=\"{}\"]/ancestor::div//button[@title='Close']",
>>>>>>> Stashed changes
}
