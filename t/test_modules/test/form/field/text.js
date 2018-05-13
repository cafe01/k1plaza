
var Field = require("k1/form/field/text").TextField,
    field = new Field({
        name: 'foo',
        class: 'form-control',
        wrapper: {
            tag: 'span',
            class: 'form-group'
        }
    });

test.is(field.name, 'foo', 'name');
test.is(field.type, 'text', 'type');

var wrapper = field.render()
test.is(wrapper.tagname(), 'span', 'wrapper tag')
test.is(wrapper.attr('class'), 'form-group', 'wrapper class')

var rendered = wrapper.find('input')
test.is(rendered.attr('name'), 'foo', 'attr: name');
test.is(rendered.attr('type'), 'text', 'attr: type');
test.is(rendered.attr('class'), 'form-control', 'attr: class');
test.is(rendered.attr('required'), 'required', 'attr: required');
