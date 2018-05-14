import { FormField } from "k1/form/field"

export class TextAreaField extends FormField {
    type = 'textarea'
    tag = 'textarea'


    render() :any {
        let el = super.render()
        el.text(this.value)
        el.remove_attr('value')
        return el
    }
}