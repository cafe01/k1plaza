
var Form = require("k1/form"),
    form = new Form({
        name: 'testForm',
        fields: ["name", "email:email", { name: "message", type: "textarea", required: false }],
        action: function(values) {
            return [values.name, values.email, values.message].join(':')
        }

    });

var fields = form.fields;
test.ok(Array.isArray(fields), "fields array")

test.is(fields.length, 4, 'field count')


test.is(form.name, 'testForm', 'form name')
test.like(form.getField("name"), { name: 'name', type: 'text', required: true }, 'field name')
test.like(form.getField("email"), { name: 'email', type: 'email', required: true }, 'field email')
test.like(form.getField("message"), { name: 'message', type: 'textarea', required: false }, 'field message')



var values = { name: 'User', email: 'user@example.com', message: "hello!", _csrf: 'foo' }
var result = form.process(values)

test.is(result.success, true, 'process - success')
test.is(result.fields, values, 'values')

test.is(form.action(result.fields), 'User:user@example.com:hello!', 'action')
