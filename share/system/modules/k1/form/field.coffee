
module.exports = class FormField

    htmlAttributes = [ 'name', 'type', 'id', 'class', 'placeholder', 'value', 'title' ]

    constructor: (params) ->
        params = if typeof params == "object" then params else name: params

        # render options
        @tag = params.tag or 'input'
        @class = params.class or 'form-control'

        @wrapper = if params.hasOwnProperty('wrapper') then params.wrapper else
            tag: 'div'
            class: 'form-group'

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
    setValue: (v) ->
        # TODO validate
        @value = v

    fillElement: (element) ->
        element.attr('value', @value) if @hasOwnProperty('value')

    render: ->
        $ = require('k1/jquery')

        # element
        element = $("<#{@tag} />")
        for attr in htmlAttributes
            element.attr attr, @[attr] if @[attr]

        element.attr 'required', 'required' if @required

        # wrapper
        return element unless @wrapper
        wrapper = $("<#{@wrapper.tag}/>")
        wrapper.add_class(@wrapper.class) if @wrapper.class
        wrapper.append(element)
        wrapper
