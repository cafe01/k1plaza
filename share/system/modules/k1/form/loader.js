"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
var form_1 = require("k1/form");
var FormLoader = /** @class */ (function () {
    function FormLoader() {
    }
    FormLoader.prototype.load = function (formName, formConfig) {
        if (formConfig === void 0) { formConfig = {}; }
        try {
            var formModule = require("form/" + formName), FormClass = void 0;
            if (typeof formModule.default == "function") {
                FormClass = formModule.default;
            }
            else {
                FormClass = form_1.Form;
                formConfig = formModule;
            }
            formConfig["name"] = formName;
            // console.log("form", formName, formConfig)
            return new FormClass(formConfig);
        }
        catch (e) {
            console.error("error loading form '" + formName + "':", e.message);
            throw "invalid form: '" + formName + "'";
        }
    };
    return FormLoader;
}());
exports.FormLoader = FormLoader;
var singleton = new FormLoader();
exports.default = singleton;
