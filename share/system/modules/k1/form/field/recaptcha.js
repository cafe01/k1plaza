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
var RecaptchaField = /** @class */ (function (_super) {
    __extends(RecaptchaField, _super);
    function RecaptchaField(config) {
        var _this = this;
        config.type = config.name = "recaptcha";
        _this = _super.call(this, config) || this;
        _this.key = config.key;
        _this.secret = config.secret;
        if (!_this.key) {
            console.error("Faltando a configuração 'key' para o campo recaptcha.");
        }
        if (!_this.secret) {
            console.error("Faltando a configuração 'secret' para o campo recaptcha.");
        }
        // mandatory name
        _this.name = 'g-recaptcha-response';
        return _this;
    }
    RecaptchaField.prototype.renderElement = function () {
        var $ = require("k1/jquery");
        return $('<div class="g-recaptcha" data-key=""/>');
    };
    RecaptchaField.prototype.fillElement = function (element) {
        if (typeof this.key == "string") {
            element.attr("data-sitekey", this.key);
        }
    };
    return RecaptchaField;
}(field_1.FormField));
exports.RecaptchaField = RecaptchaField;
