
var FormClass = require("k1/form"),
    form = new FormClass({});

var fields = form.fields;
test.ok(Array.isArray(fields), "fields array")
test.is(fields.length, 0, '0 fields');
