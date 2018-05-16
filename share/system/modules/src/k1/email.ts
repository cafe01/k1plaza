
declare var require: any

export class Email {
    
    from = null
    to = null
    subject = null
    body = null
    template = null
    htmlTemplate = null

    constructor(params) {

        // from
        this.from = params.from
        if (!this.from) {
            console.warn('[Email] opção "from" não foi definida')
        }

        // to
        this.to = params.to
        if (!this.to) {
            throw console.error('[Email] opção "to" é obrigatória')
        }

        // subject
        this.subject = params.subject
        if (!this.subject) {
            throw console.error('[Email] opção "subject" é obrigatória')
        }
        
        // body        
        this.body = params.body
        if (typeof this.body == "string" && this.body.length) { 
            
            // error
            if (params.template || params.htmlTemplate)
                throw console.error('[Email] opção "body" não pode ser utilizada junto com "template" ou "htmlTemplate"')

        }
        else {

            if (!(params.template || params.htmlTemplate))
                throw '[Email] está faltando uma das opções para o corpo do email! ("body", "template" e/ou "htmlTemplate")'

            this.template = params.template
            this.htmlTemplate = params.htmlTemplate
        }        

        // console.log("new Email", this)
    }

    send() {
        
        // prepare params
        let params = {}
        Object.keys(this)
              .filter((key) => typeof this[key] == "string")
              .forEach((key) => params[key] = this[key])
        
        if (params["htmlTemplate"])
            params["html_template"] = params["htmlTemplate"]
            delete params["htmlTemplate"]

        // enqueue job
        let jobs = require("k1/jobs")
        return jobs.push("send_email", params)
    }
}