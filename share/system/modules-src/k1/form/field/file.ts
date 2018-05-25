import { FormField } from "k1/form/field"

export class FileField extends FormField {
    type = 'file'
    maxSize = 1024 * 1024 * 20 // 20M

    constructor(config) {

        super(config)

        if (typeof config.maxSize == "number" && config.maxSize < this.maxSize) {
            this.maxSize = config.maxSize
        }
    }

    validate(value) {
        
        let isValid = super.validate(value)
        if (!isValid) {
            return false
        }

        // maxSize
        if (typeof value == "object" && typeof value.size == "number" && value.size > this.maxSize ) {
            this.errors.push({
                type: "size",
                field: this.name,
                message: `Arquivo não pode exceder ${this.maxSize} bytes.`
            })

            return false
        }

        return true
    }

} 