import { FormField } from "k1/form/field"

export class SubmitField extends FormField {
    constructor(params) {
        params.name = params.name || 'submit'
        params.class = params.class || 'btn btn-primary'
        super(params)
        this.type = 'submit'
        this.required = false
    }
}