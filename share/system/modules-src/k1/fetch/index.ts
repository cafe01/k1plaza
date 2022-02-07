
declare var require:any

import { Request } from "./request"
import { Response } from "./response"

function fetch(input, init?) {

    let req: Request;

    if (typeof input == "string") {        
        req = new Request(input, init)
    }

    if (!(req instanceof Request)) {
        throw new Error("invalid Request instance")
    }


    // build native request
    let requestConfig = [req.url, req.headers.toObject()];

    // form
    if (typeof req.form != "undefined") {
        requestConfig.push("form", req.form)
    }

    // json
    if (typeof req.json != "undefined") {
        requestConfig.push("json", req.json)
    }

    console.log("requestConfig",requestConfig)

    let ua = require("k1/ua"),
        promise = require("k1/promise").new()
    
    ua[req.method.toLowerCase()](...requestConfig, function(ua, tx) {

        let res = new Response(tx)
        if (res.ok) {
            promise.resolve(res)
        }
        else {            
            promise.reject(res)
        }
    });

    return promise
}

export { fetch, Request, Response }