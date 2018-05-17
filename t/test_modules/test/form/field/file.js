
var Field = require("k1/form").FileField,
    field = new Field({
        name: 'upload',
        class: 'form-control'
    });

test.is(field.name, 'upload', 'name');
test.is(field.type, 'file', 'type');


// form enctype
var Form = require("k1/form").Form,
    form = new Form({
        fields: ["name", "file:file"]
    })

test.is(form.render().attr("enctype"), "multipart/form-data", "form enctype")



