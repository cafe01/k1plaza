FormField = require("k1/form/field")
module.exports = class TextField extends FormField
    constructor: ->
        super(arguments...)
        @type = 'email'
