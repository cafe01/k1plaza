
class FormLoader
    constructor: ->

    load: (formName, formConfig = {}) ->
        try
            FormClass = require("form/#{formName}")
            unless typeof FormClass == "function"
                 formConfig = FormClass
                 FormClass = require("k1/form")

            formConfig.name = formName
            form = new FormClass(formConfig)
        catch
            console.error "error loading form '#{formName}'"
            throw "invalid form: '#{formName}'"

        form

module.exports = new FormLoader()
