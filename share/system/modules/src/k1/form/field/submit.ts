import { FormField } from "k1/form/field"

export class SubmitField extends FormField {
    constructor(config) {

        config.name     = config.name || 'submit'
        config.required = config.required || false
        config.class    = config.class || 'btn btn-primary'
        config.type     = 'submit'
        super(config)
    }

}