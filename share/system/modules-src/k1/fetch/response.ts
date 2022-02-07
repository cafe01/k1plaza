
import { Headers } from "./headers"

export class Response {

    ok = null
    status = null
    redirected = null
    statusText = null
    url = null
    type = 'basic'
    body = null
    headers = null
    
    constructor(tx) {

        let result = tx.result()

        // ok
        this.ok = result.is_success()

        // redirected
        this.redirected = typeof tx.previous() != "undefined"

        // status
        this.status = result.code()

        // statusText
        this.statusText = result.message()

        // type

        // url
        this.url = tx.req().url().to_string()

        // headers
        this.headers = new Headers(result.headers().to_hash())

        // body
        this.body = result.body()
    }

    json() {
        return JSON.parse(this.body)
    }
}