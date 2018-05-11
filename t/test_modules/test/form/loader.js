
var loader = require("k1/form/loader");


test.is(typeof loader, "object", "is instance")

var form = loader.load("subclass")

test.is(form.name, "subclass", "loaded subclass form")
test.is(form.fields.length, 3, 'fields')

// var simple = loader.load("simple")
// test.is(form.name, "simple", "loaded simple form")
// test.is(form.fields.length, 3, 'fields')
