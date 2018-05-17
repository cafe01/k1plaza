"use strict";
var __extends = (this && this.__extends) || (function () {
    var extendStatics = Object.setPrototypeOf ||
        ({ __proto__: [] } instanceof Array && function (d, b) { d.__proto__ = b; }) ||
        function (d, b) { for (var p in b) if (b.hasOwnProperty(p)) d[p] = b[p]; };
    return function (d, b) {
        extendStatics(d, b);
        function __() { this.constructor = d; }
        d.prototype = b === null ? Object.create(b) : (__.prototype = b.prototype, new __());
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
var field_1 = require("k1/form/field");
var TextAreaField = /** @class */ (function (_super) {
    __extends(TextAreaField, _super);
    function TextAreaField() {
        var _this = _super !== null && _super.apply(this, arguments) || this;
        _this.type = 'textarea';
        _this.tag = 'textarea';
        return _this;
    }
    TextAreaField.prototype.renderElement = function () {
        return _super.prototype.renderElement.call(this)
            .remove_attr('value')
            .remove_attr('type');
    };
    TextAreaField.prototype.fillElement = function (el) {
        if (this.value != undefined)
            el.text(this.value);
        this.renderError(el);
    };
    return TextAreaField;
}(field_1.FormField));
exports.TextAreaField = TextAreaField;
