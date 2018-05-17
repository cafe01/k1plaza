"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
var field_1 = require("./form/field");
exports.FormField = field_1.FormField;
var text_1 = require("./form/field/text");
exports.TextField = text_1.TextField;
var textarea_1 = require("./form/field/textarea");
exports.TextAreaField = textarea_1.TextAreaField;
var email_1 = require("./form/field/email");
exports.EmailField = email_1.EmailField;
var hidden_1 = require("./form/field/hidden");
var submit_1 = require("./form/field/submit");
exports.SubmitField = submit_1.SubmitField;
var file_1 = require("./form/field/file");
exports.FileField = file_1.FileField;
var fieldTypes = [text_1.TextField, textarea_1.TextAreaField, email_1.EmailField, submit_1.SubmitField, hidden_1.HiddenField, file_1.FileField];
var typeMap = {};
for (var _i = 0, fieldTypes_1 = fieldTypes; _i < fieldTypes_1.length; _i++) {
    var Type = fieldTypes_1[_i];
    var typeSample = new Type({ name: "sample" });
    typeMap[typeSample.type] = Type;
}
var _createField = function (params) {
    if (params instanceof field_1.FormField)
        return params;
    if (typeof params == "string") {
        params = { name: params };
    }
    // expand "name:type" definition
    if (params["name"]) {
        var match = params["name"].match(/(\w+):(\w+)/);
        if (match) {
            params["name"] = match[1];
            params["type"] = match[2];
        }
    }
    if (!params["type"])
        params["type"] = "text";
    var FieldType = typeMap[params["type"]];
    if (FieldType) {
        return new FieldType(params);
    }
    else {
        console.error("Invalid form field type: ", params);
        throw "Invalid form field type \"" + params['type'] + "\"";
    }
};
var Form = /** @class */ (function () {
    function Form(config) {
        if (config === void 0) { config = {}; }
        this.name = null;
        this.isProcessed = false;
        this.isValid = false;
        // name
        if (config["name"]) {
            this.name = config["name"];
        }
        // fields  
        // console.log("fields", this.fields)
        var fields = this.fields || [];
        if (Array.isArray(config.fields)) {
            fields.push.apply(fields, config.fields);
        }
        this.fields = fields.map(_createField);
        // csrf token
        this.fields.push(new hidden_1.HiddenField({ name: '_csrf' }));
        // action
        if (typeof config.action == "function") {
            this.action = config.action;
        }
    }
    Form.prototype.action = function () { };
    Form.prototype.getField = function (name) {
        for (var _i = 0, _a = this.fields; _i < _a.length; _i++) {
            var field = _a[_i];
            if (field.name == name)
                return field;
        }
        return;
    };
    Form.prototype.process = function (values) {
        var errors = [];
        var valid = {};
        for (var _i = 0, _a = this.fields; _i < _a.length; _i++) {
            var field = _a[_i];
            var value = values[field.name];
            if (field.setValue(value)) {
                valid[field.name] = value;
            }
            else {
                errors.push.apply(errors, field.errors);
            }
        }
        // return result
        this.isProcessed = true;
        this.isValid = errors.length == 0;
        // console.log "valid fields", valid
        return this.isValid ? {
            success: true,
            fields: valid
        } : {
            success: false,
            errors: errors
        };
    };
    Form.prototype.render = function (element) {
        var $ = require('k1/jquery');
        var formEl = element || $('<form/>');
        formEl.attr({
            action: "/.form/" + this.name,
            method: "post",
            name: this.name
        });
        // element is empty, render complete form
        if (formEl.find('input, textarea').size() == 0) {
            this.fields
                .forEach(function (f) { return f.render().append_to(formEl); });
        }
        else {
            // render field values
            for (var _i = 0, _a = this.fields; _i < _a.length; _i++) {
                var field = _a[_i];
                var fieldEl = formEl.find("*[name='" + field.name + "']");
                if (fieldEl.size() == 0)
                    continue;
                field.fillElement(fieldEl);
                field.renderError(fieldEl);
            }
            if (formEl.find('input[name="_csrf"]').size() == 0) {
                this.getField("_csrf").render().append_to(formEl);
            }
        }
        // enctype multipart/form-data
        if (this.fields.filter(function (f) { return f.type == "file"; }).length > 0) {
            formEl.attr("enctype", "multipart/form-data");
        }
        return formEl;
    };
    return Form;
}());
exports.Form = Form;
