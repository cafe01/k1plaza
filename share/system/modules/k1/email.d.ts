export interface EmailParams {
    /**
     * Rementente do email.
     *
     * Exemplo: "Website Foobar | Página Contato"
     */
    from: string;
    /**
     * Email de destino.
     */
    to: string;
    /**
     * Assunto do email.
     */
    subject: string;
    /**
     * Corpo do email.
     *
     * *ATENÇÃO:* Não pode ser utilizado junto com as opções `template` ou `htmlTemplate`
     */
    body: string;
    template: string;
    htmlTemplate: string;
    data: any;
    attachments: string;
}
/**
* Utilize essa classe para criar e enviar emails.
*
*/
export declare class Email {
    from: any;
    to: any;
    subject: any;
    body: any;
    template: any;
    html_template: any;
    attachments: any;
    template_data: any;
    /**
    * Novo email.
    * @param params: Configuração do email a ser enviado.
    */
    constructor(params: EmailParams);
    send(): any;
}
