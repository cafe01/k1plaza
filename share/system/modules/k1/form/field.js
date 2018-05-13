"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
var htmlAttributes = ["name", "type", "id", "class", "placeholder", "value", "title"];
var FormField = /** @class */ (function () {
    function FormField(params) {
        if (params === void 0) { params = {}; }
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
        // params
        for (var _i = 0, _a = htmlAttributes.concat(["required", "tag", "wrapper"]); _i < _a.length; _i++) {
            var opt = _a[_i];
            if (params.hasOwnProperty(opt)) {
                this[opt] = params[opt];
            }
        }
        // error: missing name
        if (this.name == undefined) {
            console.error("[FormField] missing 'name' config");
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
        this.value = value;
    };
    FormField.prototype.render = function () {
        var $ = require("k1/jquery");
        // element
        var element = $("<" + this.tag + " />");
        for (var _i = 0, htmlAttributes_1 = htmlAttributes; _i < htmlAttributes_1.length; _i++) {
            var attr = htmlAttributes_1[_i];
            if (this[attr])
                element.attr(attr, this[attr]);
        }
        if (this.required)
            element.attr("required", "required");
        // wrapper
        if (!this.wrapper)
            return element;
        var wrapper = $("<" + this.wrapper.tag + "/>");
        if (this.wrapper.class)
            wrapper.add_class(this.wrapper.class);
        wrapper.append(element);
        return wrapper;
    };
    FormField.prototype.fillElement = function (element) {
        if (this.hasOwnProperty("value"))
            element.attr("value", this.value);
    };
    return FormField;
}());
exports.FormField = FormField;
