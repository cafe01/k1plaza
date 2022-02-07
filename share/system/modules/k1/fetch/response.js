"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
var headers_1 = require("./headers");
var Response = /** @class */ (function () {
    function Response(tx) {
        this.ok = null;
        this.status = null;
        this.redirected = null;
        this.statusText = null;
        this.url = null;
        this.type = 'basic';
        this.body = null;
        this.headers = null;
        var result = tx.result();
        // ok
        this.ok = result.is_success();
        // redirected
        this.redirected = typeof tx.previous() != "undefined";
        // status
        this.status = result.code();
        // statusText
        this.statusText = result.message();
        // type
        // url
        this.url = tx.req().url().to_string();
        // headers
        this.headers = new headers_1.Headers(result.headers().to_hash());
        // body
        this.body = result.body();
    }
    Response.prototype.json = function () {
        return JSON.parse(this.body);
    };
    return Response;
}());
exports.Response = Response;
