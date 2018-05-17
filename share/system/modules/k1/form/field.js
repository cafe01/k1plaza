"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
var htmlAttributes = ["name", "type", "id", "class", "placeholder", "value", "title"];
var FormField = /** @class */ (function () {
    function FormField(params) {
        if (params === void 0) { params = {}; }
        this.label = null;
        this.name = null;
        this.type = "text";
        this.value = null;
        this.required = true;
        this.tag = "input";
        this.class = "form-control";
        this.wrapper = {
            tag: "div",
            class: "form-group"
        };
        this.errors = [];
        // params
        for (var _i = 0, _a = htmlAttributes.concat(["required", "tag", "wrapper"]); _i < _a.length; _i++) {
            var opt = _a[_i];
            if (params.hasOwnProperty(opt)) {
                this[opt] = params[opt];
            }
        }
        // error: missing name
        if (this.name == undefined) {
            console.error("[FormField] missing field 'name'", params);
            throw ("missing form field 'name'");
        }
        // parse type from name
        var match;
        if (match = this.name.match(/(\w+):(\w+)/)) {
            this.name = match[1];
            this.type = match[2];
        }
        // console.log("new form field", this)
    }
    FormField.prototype.setValue = function (value) {
        // required
        if (this.required && (typeof value != "string" || !value.match(/\S/))) {
            this.errors.push({
                type: 'required',
                field: this.name,
                message: "Campo obrigatório."
            });
            return false;
        }
        // TODO type validation
        this.value = value;
        return true;
    };
    FormField.prototype.isValid = function () {
        return this.errors.length == 0;
    };
    FormField.prototype.render = function () {
        // wrapper
        var $ = require("k1/jquery");
        var wrapperConfig = this.wrapper || { tag: 'div', class: null };
        var wrapper = $("<" + wrapperConfig.tag + "/>");
        if (wrapperConfig.class) {
            wrapper.add_class(wrapperConfig.class);
        }
        // element
        var element = this.renderElement();
        wrapper.append(element);
        // return only children if configured with null wrapper
        return this.wrapper ? wrapper : wrapper.children();
    };
    FormField.prototype.renderElement = function () {
        // element
        var $ = require("k1/jquery");
        var element = $("<" + this.tag + " />");
        for (var _i = 0, htmlAttributes_1 = htmlAttributes; _i < htmlAttributes_1.length; _i++) {
            var attr = htmlAttributes_1[_i];
            if (this[attr])
                element.attr(attr, this[attr]);
        }
        if (this.required)
            element.attr("required", "required");
        // fill value
        this.fillElement(element);
        return element;
    };
    FormField.prototype.fillElement = function (element) {
        if (this.value != undefined)
            element.attr("value", this.value);
        this.renderError(element);
    };
    FormField.prototype.renderError = function (element) {
        if (this.errors.length == 0)
            return;
        var error = this.errors[0];
        element.add_class("error error-" + error.type);
        var $ = require("k1/jquery");
        var span = $("<span/>")
            .text(error.message)
            .attr('class', "error_message")
            .insert_after(element);
    };
    return FormField;
}());
exports.FormField = FormField;
