
var Form = require("k1/form").Form,
    form = new Form({});

var fields = form.fields;
test.ok(Array.isArray(fields), "fields array")
test.is(fields.length, 1, '1 fields');
