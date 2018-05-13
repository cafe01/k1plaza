declare var require: any

import { Form } from 'k1/form'

class FormLoader {
    
    load(formName: string, formConfig = {}) {
        
        try {
            let formModule = require(`form/${formName}`),
                FormClass;

            if (typeof formModule.default == "function") {
                FormClass = formModule.default
            }
            else {
                FormClass = Form               
                formConfig = formModule
            }

            formConfig["name"] = formName
            // console.log("form", formName, formConfig)
            return new FormClass(formConfig)
        }
        catch (e) {
            console.error `error loading form '${formName}'`
            throw `invalid form: '${formName}'`
        }
    }
}

let singleton = new FormLoader()

export { singleton as default, FormLoader}
