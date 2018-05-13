
var Field = require("k1/form/field").FormField,
    field = new Field({
        name: 'foo',
        type: 'text',
        class: 'form-control'
    });

test.is(field.name, 'foo', 'name');
test.is(field.type, 'text', 'type');

var rendered = field.render()
// test.diag(rendered.as_html())
test.is(rendered.tagname(), 'div', 'wrapper tag');

var field = rendered.find('input')
test.is(field.attr('name'), 'foo', 'attr: name');
test.is(field.attr('type'), 'text', 'attr: type');
test.is(field.attr('class'), 'form-control', 'attr: class');
test.is(field.attr('required'), 'required', 'attr: required');
