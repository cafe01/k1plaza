"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
var Email = /** @class */ (function () {
    function Email(params) {
        this.from = null;
        this.to = null;
        this.subject = null;
        this.body = null;
        this.template = null;
        this.htmlTemplate = null;
        this.attachments = null;
        // from
        this.from = params.from;
        if (!this.from) {
            console.warn('[Email] opção "from" não foi definida');
        }
        // to
        this.to = params.to;
        if (!this.to) {
            throw console.error('[Email] opção "to" é obrigatória');
        }
        // subject
        this.subject = params.subject;
        if (!this.subject) {
            throw console.error('[Email] opção "subject" é obrigatória');
        }
        // body        
        this.body = params.body;
        if (typeof this.body == "string" && this.body.length) {
            // error
            if (params.template || params.htmlTemplate)
                throw console.error('[Email] opção "body" não pode ser utilizada junto com "template" ou "htmlTemplate"');
        }
        else {
            if (!(params.template || params.htmlTemplate))
                throw '[Email] está faltando uma das opções para o corpo do email! ("body", "template" e/ou "htmlTemplate")';
            this.template = params.template;
            this.htmlTemplate = params.htmlTemplate;
        }
        // attachment
        if (params.attachments) {
            this.attachments = Array.isArray(params.attachments)
                ? params.attachments
                : [params.attachments];
        }
        // console.log("new Email", this)
    }
    Email.prototype.send = function () {
        var _this = this;
        // prepare params
        var params = {};
        Object.keys(this)
            .filter(function (key) { return _this[key] != undefined; })
            .forEach(function (key) { return params[key] = _this[key]; });
        if (params["htmlTemplate"])
            params["html_template"] = params["htmlTemplate"];
        delete params["htmlTemplate"];
        // enqueue job
        var jobs = require("k1/jobs");
        return jobs.push("send_email", params);
    };
    return Email;
}());
exports.Email = Email;
