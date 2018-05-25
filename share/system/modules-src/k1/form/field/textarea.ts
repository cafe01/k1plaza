import { FormField } from "k1/form/field"


export class TextAreaField extends FormField {
    type = 'textarea'
    tag = 'textarea'

    renderElement() :any {
        return super.renderElement()
            .remove_attr('value')
            .remove_attr('type')
    }

    fillElement(el) :any {        
        if (this.value != undefined)
            el.text(this.value)

        this.renderError(el)
    }
}