
import { Headers } from "./headers"

export class Request {

    method: String
    url: String
    headers: Headers
    body: String
    form: Object
    json: Object

    constructor(url, init:any = {}) {

        // url
        this.url = url

        // method
        this.method = init.method || 'GET'

        // headers
        this.headers = new Headers(init.headers || {})

        // json
        if (init.json) {
            this.json = init.json
            this.headers.set('Content-Type', 'application/json')
        }
    }

    toObject() :object {

        return {
            method: this.method,
            url: this.url,
            headers: this.headers.toObject()
        }
    }

}