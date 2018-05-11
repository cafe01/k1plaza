
module.exports = class Form

    _createField = (params) ->
        params = if typeof params == "object" then params else name: params
        unless params.type = params.type
            if params.name? and match = params.name.match(/(\w+):(\w+)/)
                params.name = match[1]
                params.type = match[2]
            else
                params.type = 'text'
        # console.log 'field type', params
        try
            FieldClass = require("k1/form/field/#{params.type}")
        catch
            console.error "[Form] error loading field type '#{params.type}'"
            throw "invalid field"

        new FieldClass(params)

    constructor: (config) ->
        config = config or {}

        # name
        @name = config.name or @name or 'defultName'

        # fields
        @fields = @fields or []
        @fields.push config.fields... if Array.isArray(config.fields)
        @fields = for field in @fields
            _createField(field)

        # csrf token
        HiddenField = require('k1/form/field/hidden')
        @fields.push new HiddenField( name: '_csrf' )

        # action
        if typeof config.action == "function"
            @action = config.action

        # console.log "new form", @fields

    action: -> console.log "default action() called on form ", @name

    getField: (name) ->
        for field in @fields
            if field.name == name
                return field
        return

    process: (values) ->
        errors = []
        valid = {}

        for field in @fields
            value = values[field.name]

            # required
            if field.required and (!value? or !value.match(/\w/))
                errors.push
                    message: "Campo obrigatório"
                    field: field.name
                continue

            # TODO type validation

            # add valid value
            valid[field.name] = value
            field.setValue(value)
            # field.value = value
            # console.log("processed field", @ instanceof Form, field)

        # return result
        @processed = true
        @isValid = errors.length == 0

        # console.log "valud fields", valid
        if @isValid
            success: true
            fields: valid
        else
            success: false
            errors: errors

    render: (element) ->
        $ = require('k1/jquery')
        formEl = element or $('<form/>')

        formEl.attr
            action:  "/.form/#{@name}"
            method: "post"
            name: @name

        # render or fill items
        if formEl.find('input, textarea').size() == 0
            for field in @fields
                field.render().append_to formEl
        else
            for field in @fields
                fieldEl = formEl.find("*[name='#{field.name}']")
                continue unless fieldEl.size()
                field.fillElement(fieldEl)

            if formEl.find('input[name="_csrf"]').size() == 0
                @getField("_csrf").render().append_to formEl


        formEl
