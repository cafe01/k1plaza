
var Form = require("k1/form"),
    form = new Form({
        name: 'testForm',
        fields: ["name", "email:email", { name: "message", type: "textarea", required: false }],
        action: function(values) {
            return [values.name, values.email, values.message].join(':')
        }

    });


var rendered = form.render();

test.is(rendered.find('textarea').size(), 1, 'textarea')


// process
form.process({ name: 'Carlos Fernando' })
rendered = form.render()

test.is(rendered.find('input[name="name"]').attr('value'), 'Carlos Fernando', 'rendered input value')
// test.diag(rendered.as_html())
