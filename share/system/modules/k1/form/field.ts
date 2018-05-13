
declare var require: any

let htmlAttributes = [ "name", "type", "id", "class", "placeholder", "value", "title" ]

export class FormField {

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
    
    constructor(params = {}) {

        // params
        for (let opt of [...htmlAttributes, "required", "tag", "wrapper"]) {
            if (params.hasOwnProperty(opt)) {
                this[opt] = params[opt]
            }
        }

        // error: missing name
        if (this.name == undefined) {
            console.error("[FormField] missing 'name' config")
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
        this.value = value
    }

    render() : any {
        let $ = require("k1/jquery")

        // element
        let element = $(`<${this.tag} />`)
        for (let attr of htmlAttributes) {
            if (this[attr]) element.attr(attr, this[attr])
        }
            
        if (this.required) element.attr("required", "required")

        // wrapper
        if (!this.wrapper) return element
        let wrapper = $(`<${this.wrapper.tag}/>`)
        if (this.wrapper.class)
            wrapper.add_class(this.wrapper.class)

        wrapper.append(element)
        return wrapper
    }

    fillElement(element) {
        if (this.hasOwnProperty("value")) element.attr("value", this.value)        
    }
}
 
  