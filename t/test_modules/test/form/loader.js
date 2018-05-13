
var loader = require("k1/form/loader").default,
    Subclass = require("form/subclass").default;


var form = loader.load("subclass")
// console.log("subclass", form)
test.ok(form instanceof Subclass, "form instance");
test.is(form.name, "subclass", "loaded subclass form")
test.is(form.fields.length, 3, 'fields')

var simple = loader.load("simple")
test.is(simple.name, "simple", "loaded simple form")
test.is(simple.fields.length, 2, 'fields')
