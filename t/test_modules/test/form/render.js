
var FormClass = require("k1/form").Form,
    form = new FormClass({
        name: 'testForm',
        fields: ["name", "email:email", { name: "message", type: "textarea", required: false }],
        action: function(values) {
            return [values.name, values.email, values.message].join(':')
        }

    });


var rendered = form.render();

test.is(rendered.find('textarea').size(), 1, 'textarea')


// process
var result = form.process({ name: 'Carlos Fernando', message: "Hello!" })
// test.diag("form result", JSON.stringify(result))

test.is(rendered.find("span").size(), 0, 'no error elements')

rendered = form.render()
test.is(rendered.attr("method"), "post", "method")
test.is(rendered.attr("action"), "/.form/testForm", "action")
test.is(rendered.find('input[name="name"]').attr('value'), 'Carlos Fernando', 'rendered input value')

var email = rendered.find('input[name="email"]')
test.is(email.attr('value'), undefined, 'email is empty')


// test.diag(rendered.as_html())

// errors
test.is(email.attr('class'), 'form-control error error-required', 'email error')
test.ok(rendered.find("span").size(), 'error elements')
