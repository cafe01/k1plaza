
var Field = require("k1/form/field/textarea").TextAreaField,
    field = new Field({
        name: 'message',
        required: false,
        class: 'form-control'
    })

test.is(field.name, 'message', 'name')
test.is(field.type, 'textarea', 'type')

field.setValue("Loren")

var rendered = field.render().find("textarea")
test.diag(rendered.as_html())

test.is(rendered.attr('name'), 'message', 'attr: name')
test.is(rendered.attr('class'), 'form-control', 'attr: class')
test.is(rendered.attr('required'), undefined, 'attr: required')
test.is(rendered.attr('type'), undefined, 'attr: type')
test.is(rendered.attr('value'), undefined, 'attr: value')
test.is(rendered.text(), 'Loren', "value")

