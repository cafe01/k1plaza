declare var require: any

import { FormField } from "./form/field"
import { TextField } from "./form/field/text"
import { TextAreaField } from "./form/field/textarea"
import { EmailField } from "./form/field/email"
import { HiddenField } from "./form/field/hidden"
import { SubmitField } from "./form/field/submit"
import { FileField } from "./form/field/file"
import { RecaptchaField } from "./form/field/recaptcha"


let fieldTypes = [
    TextField, 
    TextAreaField, 
    EmailField, 
    SubmitField, 
    HiddenField, 
    FileField, 
    RecaptchaField
]

let typeMap = {}

for (let Type of fieldTypes) {
    let typeSample = new Type({ name: "sample" })
    typeMap[typeSample.type] = Type
}

let _createField = function(params: string | object | FormField) : FormField {
    
    if (params instanceof FormField) return params
    
    if (typeof params == "string") {
        params = { name: params }
    }
    
    // expand "name:type" definition
    if (params["name"]) {
        let match = params["name"].match(/(\w+):(\w+)/)
        if (match) {
            params["name"] = match[1]
            params["type"] = match[2]
        }
    }

    if (!params["type"]) params["type"] = "text"

    let FieldType = typeMap[params["type"]]

    if (FieldType) {
        return new FieldType(params);
    }
    else {
        console.error(`Invalid form field type: `, params)
        throw `Invalid form field type "${params['type']}"`
    }
}

class Form {

    name = null

    fields: FormField[]

    isProcessed = false

    isValid = false

    constructor(config: any = {}) {

        // name
        if (config["name"]) {
            this.name = config["name"]
        }

        // fields  
        // console.log("fields", this.fields)
        let fields = this.fields || []    
        if (Array.isArray(config.fields)) {
            fields.push(...config.fields)
        }

        this.fields = fields.map(_createField)

        // csrf token
        this.fields.push( new HiddenField({ name: '_csrf' }))

        // action
        if (typeof config.action == "function") {
            this.action = config.action
        }

    }

    action () { }

    getField (name: string): FormField {

        for (let field of this.fields) {
            if (field.name == name) return field
        }

        return;
    }

    process (values: object) {

        let errors = []
        var valid = {}
        
        for (let field of this.fields) {
            
            let value = values[field.name]
            
            if (field.setValue(value)) {
                valid[field.name] = value
            }
            else {
                errors.push(...field.errors)
            }
            
        }        

        // return result
        this.isProcessed = true
        this.isValid = errors.length == 0        

        // console.log "valid fields", valid
        return this.isValid ? {
            success: true,
            fields: valid
        } : {
            success: false,
            errors: errors
        }        
    }

    render (element): object {

        let $ = require('k1/jquery')
        let formEl = element || $('<form/>')
    
        formEl.attr({
            action:  `/.form/${this.name}`,
            method: "post",
            name: this.name
        })
    
        // element is empty, render complete form
        if (formEl.find('input, textarea').size() == 0) {

            this.fields
                .forEach( f => f.render().append_to(formEl) )
        }
        else {
            // render field values
            for (let field of this.fields) {
                let fieldEl = formEl.find(`*[name='${field.name}']`)
                if (fieldEl.size() == 0) continue
                field.fillElement(fieldEl)
                field.renderError(fieldEl)
            }
    
            if (formEl.find('input[name="_csrf"]').size() == 0) {
                this.getField("_csrf").render().append_to(formEl)
            }
        }

        // enctype multipart/form-data
        if (this.fields.filter((f) => f.type == "file").length > 0) {
            formEl.attr("enctype", "multipart/form-data")
        }

        return formEl
    }



}

export { 
    Form, 
    FormField, 
    TextField, 
    TextAreaField, 
    EmailField, 
    SubmitField, 
    HiddenField, 
    FileField, 
    RecaptchaField
}