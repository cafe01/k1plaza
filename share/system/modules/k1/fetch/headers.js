"use strict";
var __assign = (this && this.__assign) || Object.assign || function(t) {
    for (var s, i = 1, n = arguments.length; i < n; i++) {
        s = arguments[i];
        for (var p in s) if (Object.prototype.hasOwnProperty.call(s, p))
            t[p] = s[p];
    }
    return t;
};
Object.defineProperty(exports, "__esModule", { value: true });
var Headers = /** @class */ (function () {
    function Headers(init) {
        if (init === void 0) { init = {}; }
        this.headers = null;
        this.headers = __assign({}, init);
    }
    Headers.prototype.append = function (key, value) {
        if (this.headers.hasOwnProperty(key)) {
            this.headers[key] = this.headers[key] + ", " + value;
        }
        else {
            this.headers[key] = value;
        }
    };
    Headers.prototype.set = function (key, value) {
        this.headers[key] = value;
    };
    Headers.prototype.get = function (key) {
        return this.headers[key];
    };
    Headers.prototype.delete = function (key) {
        delete this.headers[key];
    };
    Headers.prototype.has = function (key) {
        return this.headers.hasOwnProperty(key);
    };
    Headers.prototype.keys = function () {
        return Object.keys(this.headers);
    };
    Headers.prototype.toObject = function () {
        return __assign({}, this.headers);
    };
    return Headers;
}());
exports.Headers = Headers;
