
var Field = require("k1/form/field/textarea"),
    field = new Field({
        name: 'message',
        required: false,
        class: 'form-control'
    })

test.is(field.name, 'message', 'name')
test.is(field.type, 'textarea', 'type')

var rendered = field.render()
test.is(rendered.tagname(), 'textarea', 'rendered tagname')
test.is(rendered.attr('name'), 'message', 'attr: name')
test.is(rendered.attr('type'), 'textarea', 'attr: type')
test.is(rendered.attr('class'), 'form-control', 'attr: class')
test.is(rendered.attr('required'), undefined, 'attr: required')

// test.diag(rendered.as_html())
