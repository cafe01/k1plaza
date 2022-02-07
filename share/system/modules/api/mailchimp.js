"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
var fetch_1 = require("k1/fetch");
var MailChimp = /** @class */ (function () {
    function MailChimp(dc, key) {
        this.dc = null;
        this.key = null;
        this.baseUrl = null;
        if (!dc || !key) {
            throw new Error("Faltando parametros 'dc' e/ou 'key'.");
        }
        this.dc = dc;
        this.key = key;
        this.baseUrl = "http://username:" + this.key + "@" + this.dc + ".api.mailchimp.com/3.0";
    }
    MailChimp.prototype.request = function (method, path, json) {
        var fetchParams = {
            method: method,
            json: json
        };
        return fetch_1.fetch(this.baseUrl + "/" + path, fetchParams).then(function (res) {
            // console.log(`Mailchimp API response: ${res.status} ${res.statusText}`, res.body)
            return res.json();
        });
    };
    return MailChimp;
}());
exports.MailChimp = MailChimp;
