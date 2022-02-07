
declare var require: any

export interface EmailParams {
    /**
     * Rementente do email.
     *
     * Exemplo: "Website Foobar | Página Contato"
     */
    from:string

    /**
     * Email de destino.
     */
    to:string

    /**
     * Responder para este email.
     */
    replyTo:string

    /**
     * Assunto do email.
     */
    subject:string

    /**
     * Corpo do email.
     *
     * *ATENÇÃO:* Não pode ser utilizado junto com as opções `template` ou `htmlTemplate`
     */
    body:string
    template:string
    htmlTemplate:string
    data:any
    attachments:string
}

/**
* Utilize essa classe para criar e enviar emails.
*
*/
export class Email {

    from = null
    to = null
    subject = null
    body = null
    template = null
    html_template = null
    attachments = null
    template_data:any

    /**
    * Novo email.
    * @param params: Configuração do email a ser enviado.
    */
    constructor(params:EmailParams) {

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

        // replyTo
        this['reply-to'] = params.replyTo

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
            this.html_template = params.htmlTemplate
        }

        // data
        this.template_data = params.data

        // attachment
        if (params.attachments) {
            this.attachments = Array.isArray(params.attachments)
                ? params.attachments
                : [params.attachments]
        }

        // console.log("new Email", this)
    }

    send() {

        // prepare params
        let params = {}
        Object.keys(this)
              .filter((key) => this[key] != undefined)
              .forEach((key) => params[key] = this[key])

        // enqueue job
        let jobs = require("k1/jobs")
        return jobs.push("send_email", params)
    }
}