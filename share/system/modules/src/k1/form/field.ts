
declare var require: any

let htmlAttributes = [ "name", "type", "id", "class", "placeholder", "value", "title" ]

export class FormField {

    label = null
    name = null
    type = "text"
    value = null
    required = true
    tag = "input"
    class = "form-control"
    wrapper = {
        tag: "div",
        class: "form-group"
    }

    errors = []
    
    constructor(params = {}) {

        // params
        for (let opt of [...htmlAttributes, "required", "tag", "wrapper"]) {
            if (params.hasOwnProperty(opt)) {
                this[opt] = params[opt]
            }
        }

        // error: missing name
        if (this.name == undefined) {
            console.error("[FormField] missing field 'name'", params)
            throw("missing form field 'name'")
        }
 
        // parse type from name
        let match;
        if (match = this.name.match(/(\w+):(\w+)/)) {
            this.name = match[1]
            this.type = match[2]
        }

        // console.log("new form field", this)
    }

    setValue(value: any) {
        
        // required
        if (this.required && (typeof value != "string" || !value.match(/\S/))) {
            this.errors.push({
                type: 'required',
                field: this.name,
                message: "Campo obrigatório."
            })

            return false
        }
    
        // TODO type validation
        
        this.value = value
        return true
    }

    isValid() {
        return this.errors.length == 0
    }

    render() : any {

        // wrapper
        let $ = require("k1/jquery")
        let wrapperConfig = this.wrapper || { tag: 'div', class: null }
        let wrapper = $(`<${wrapperConfig.tag}/>`)

        if (wrapperConfig.class) {
            wrapper.add_class(wrapperConfig.class)
        }

        // element
        let element = this.renderElement()
        wrapper.append(element)

        // return only children if configured with null wrapper
        return this.wrapper ? wrapper : wrapper.children()
    }

    renderElement() {

        // element
        let $ = require("k1/jquery")
        let element = $(`<${this.tag} />`)

        for (let attr of htmlAttributes) {
            if (this[attr]) element.attr(attr, this[attr])
        }
            
        if (this.required) element.attr("required", "required")

        // fill value
        this.fillElement(element)

        return element
    }

    fillElement(element) {
        if (this.value != undefined) element.attr("value", this.value)   
        this.renderError(element)
    }

    renderError(element) {
        
        if (this.errors.length == 0) return;

        let error = this.errors[0]
        element.add_class(`error error-${error.type}`)
        
        let $ = require("k1/jquery")
        let span = $("<span/>")
            .text(error.message)        
            .attr('class', `error_message`)
            .insert_after(element)
    }

}
 
  