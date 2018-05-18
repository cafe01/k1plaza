
declare var require

import { FormField } from "k1/form/field"

export class RecaptchaField extends FormField {
   
    key: null
    secret: null

    constructor(config) {
        config.type = config.name = "recaptcha"

        super(config)

        this.key = config.key
        this.secret = config.secret

        if (!this.key) {
            console.error("Faltando a configuração 'key' para o campo recaptcha.")
        }

        if (!this.secret) {
            console.error("Faltando a configuração 'secret' para o campo recaptcha.")
        }

        // mandatory name
        this.name = 'g-recaptcha-response'
    }

    renderElement() {
        let $ = require("k1/jquery")
        return $('<div class="g-recaptcha" data-key=""/>')
    }

    fillElement(element) {        
        if (typeof this.key == "string") {
            element.attr("data-sitekey", this.key)
        }        
    }

    findElement(rootElement) {
        return rootElement.find("div.g-recaptcha")
    }

}