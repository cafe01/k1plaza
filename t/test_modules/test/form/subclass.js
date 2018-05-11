
var Subclass = require("form/subclass"),
    form = new Subclass(),
    form2 = new Subclass();

test.is(form.fields.length, 3, 'fields');
test.is(form2.fields.length, 3, 'fields');

test.is(form.action(), 'subclass action ok', 'action');
