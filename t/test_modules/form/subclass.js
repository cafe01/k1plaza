

var Form = require("k1/form").Form

exports.default = exports.Subclass = function() {
    this.fields = ["name", "email:email"]
    this.action = function() { return "subclass action ok" }
    Form.apply(this, arguments)
}
