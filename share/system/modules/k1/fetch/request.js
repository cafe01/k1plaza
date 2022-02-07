"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
var headers_1 = require("./headers");
var Request = /** @class */ (function () {
    function Request(url, init) {
        if (init === void 0) { init = {}; }
        // url
        this.url = url;
        // method
        this.method = init.method || 'GET';
        // headers
        this.headers = new headers_1.Headers(init.headers || {});
        // json
        if (init.json) {
            this.json = init.json;
            this.headers.set('Content-Type', 'application/json');
        }
    }
    Request.prototype.toObject = function () {
        return {
            method: this.method,
            url: this.url,
            headers: this.headers.toObject()
        };
    };
    return Request;
}());
exports.Request = Request;
