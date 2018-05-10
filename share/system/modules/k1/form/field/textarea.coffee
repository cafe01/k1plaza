FormField = require("k1/form/field")
module.exports = class TextAreaField extends FormField
    constructor: ->
        super(arguments...)
        @type = 'textarea'
        @tag = 'textarea'
