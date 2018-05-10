
module.exports = class FormField

    htmlAttributes = [ 'name', 'type', 'id', 'class', 'placeholder', 'value', 'title' ]

    tag: 'input'
    wrapper:
        tag: 'div'
        class: ''

    constructor: (params) ->
        params = if typeof params == "object" then params else name: params

        # name
        @name = params.name
        unless @name
            console.error "[FormField] missing 'name' config"
            throw "missing form field 'name'"

        # type
        unless @type = params.type
            if match = @name.match(/(\w+):(\w+)/)
                @name = match[1]
                @type = match[2]
            else
                @type = 'text'

        # required
        @required = if typeof params.required == "boolean" then params.required else true

        # other options
        for attr in ['label', htmlAttributes...]
            @[attr] = params[attr] if not @[attr]? and params[attr]?

        # console.log 'this field', @

    render: ->
        $ = require('k1/jquery')
        element = $("<#{@tag} />")
        for attr in htmlAttributes
            element.attr attr, @[attr] if @[attr]
        element.attr 'required', 'required' if @required
        element
