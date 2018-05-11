FormField = require("k1/form/field")
module.exports = class SubmitField extends FormField
    constructor: (params)->
        params.name = params.name or 'submit'
        params.class = params.class or 'btn btn-primary'
        super(arguments...)
        @type = 'submit'
        @required = false
