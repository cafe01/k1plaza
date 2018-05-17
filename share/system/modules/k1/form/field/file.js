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
var FileField = /** @class */ (function (_super) {
    __extends(FileField, _super);
    function FileField(config) {
        var _this = _super.call(this, config) || this;
        _this.type = 'file';
        _this.maxSize = 1024 * 1024 * 20; // 20M
        if (typeof config.maxSize == "number" && config.maxSize < _this.maxSize) {
            _this.maxSize = config.maxSize;
        }
        return _this;
    }
    FileField.prototype.validate = function (value) {
        var isValid = _super.prototype.validate.call(this, value);
        if (!isValid) {
            return false;
        }
        // maxSize
        if (typeof value == "object" && typeof value.size == "number" && value.size > this.maxSize) {
            this.errors.push({
                type: "size",
                field: this.name,
                message: "Arquivo n\u00E3o pode exceder " + this.maxSize + " bytes."
            });
            return false;
        }
        return true;
    };
    return FileField;
}(field_1.FormField));
exports.FileField = FileField;
