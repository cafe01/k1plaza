
var Field = require("k1/form/field/text"),
    field = new Field({
        name: 'foo',
        class: 'form-control'
    });

test.is(field.name, 'foo', 'name');
test.is(field.type, 'text', 'type');

var rendered = field.render()
test.is(rendered.tagname(), 'input', 'rendered tagname');
test.is(rendered.attr('name'), 'foo', 'attr: name');
test.is(rendered.attr('type'), 'text', 'attr: type');
test.is(rendered.attr('class'), 'form-control', 'attr: class');
test.is(rendered.attr('required'), 'required', 'attr: required');
