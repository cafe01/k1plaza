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
var HiddenField = /** @class */ (function (_super) {
    __extends(HiddenField, _super);
    function HiddenField() {
        var _this = _super !== null && _super.apply(this, arguments) || this;
        _this.type = 'hidden';
        _this.wrapper = null;
        return _this;
    }
    return HiddenField;
}(field_1.FormField));
exports.HiddenField = HiddenField;
