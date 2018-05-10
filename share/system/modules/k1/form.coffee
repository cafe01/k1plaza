
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
        @name = config.name or 'defultName'

        # fields
        @fields = []
        if Array.isArray(config.fields)
            @fields = for f in config.fields
                field = _createField(f)
                # console.log field
                field

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
            if field.required and !value?
                errors.push
                    message: "Campo obrigatório"
                    field: field.name
                continue

            # TODO type validation

            # add valid value
            valid[field.name] = value
            @getField(field.name).value = value

        # return result
        @processed = true
        @isValid = errors.length == 0

        if @isValid
            success: true
            fields: valid
        else
            success: false
            errors: errors

    render: ->
        $ = require('k1/jquery')
        form = $('<form/>')
        form.attr
            action:  "/.form/#{@name}"
            name: @name

        for field in @fields
            field.render().append_to form

        form
