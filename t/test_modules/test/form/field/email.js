
var Field = require("k1/form/field/email").EmailField,
    field = new Field({
        name: 'email'
    });

test.is(field.name, 'email', 'name');
test.is(field.type, 'email', 'type');

var rendered = field.render().find('input')
test.is(rendered.attr('name'), 'email', 'attr: name');
test.is(rendered.attr('type'), 'email', 'attr: type');
test.is(rendered.attr('required'), 'required', 'attr: required');
