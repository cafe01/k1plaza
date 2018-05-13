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
var SubmitField = /** @class */ (function (_super) {
    __extends(SubmitField, _super);
    function SubmitField(params) {
        var _this = this;
        params.name = params.name || 'submit';
        params.class = params.class || 'btn btn-primary';
        _this = _super.call(this, params) || this;
        _this.type = 'submit';
        _this.required = false;
        return _this;
    }
    return SubmitField;
}(field_1.FormField));
exports.SubmitField = SubmitField;
