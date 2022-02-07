
import { fetch } from "k1/fetch"

export class MailChimp {

    dc = null
    key = null
    baseUrl = null

    constructor(dc, key) {

        if (!dc || !key) {
            throw new Error("Faltando parametros 'dc' e/ou 'key'.")
        }

        this.dc = dc
        this.key = key
        this.baseUrl = `http://username:${this.key}@${this.dc}.api.mailchimp.com/3.0`
    }

    request(method, path, json) {

        let fetchParams = {
            method: method,
            json: json
        }

        return fetch(`${this.baseUrl}/${path}`, fetchParams).then((res) => {

            // console.log(`Mailchimp API response: ${res.status} ${res.statusText}`, res.body)
            return res.json()

        })
    }
}