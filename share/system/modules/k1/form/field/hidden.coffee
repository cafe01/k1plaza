FormField = require("k1/form/field")
module.exports = class HiddenField extends FormField
    constructor: ->
        super(arguments...)
        @type = 'hidden'
        @wrapper = null
