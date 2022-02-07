"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
var request_1 = require("./request");
exports.Request = request_1.Request;
var response_1 = require("./response");
exports.Response = response_1.Response;
function fetch(input, init) {
    var req;
    if (typeof input == "string") {
        req = new request_1.Request(input, init);
    }
    if (!(req instanceof request_1.Request)) {
        throw new Error("invalid Request instance");
    }
    // build native request
    var requestConfig = [req.url, req.headers.toObject()];
    // form
    if (typeof req.form != "undefined") {
        requestConfig.push("form", req.form);
    }
    // json
    if (typeof req.json != "undefined") {
        requestConfig.push("json", req.json);
    }
    console.log("requestConfig", requestConfig);
    var ua = require("k1/ua"), promise = require("k1/promise").new();
    ua[req.method.toLowerCase()].apply(ua, requestConfig.concat([function (ua, tx) {
            var res = new response_1.Response(tx);
            if (res.ok) {
                promise.resolve(res);
            }
            else {
                promise.reject(res);
            }
        }]));
    return promise;
}
exports.fetch = fetch;
