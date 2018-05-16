
var Email = require('k1/email').Email,
    email;

try { new Email({}) } 
catch(e) {
    test.is(e, '[Email] opção "to" é obrigatória', "error: missing 'to'")
}

try { new Email({ to: "foo@example.com" }) } 
catch(e) {
    test.is(e, '[Email] opção "subject" é obrigatória', "error: missing 'subject'")
}

try { new Email({ to: "foo@example.com", subject: "testing" }) } 
catch(e) {
    test.ok(e.match('corpo do email'), "error: missing some body")
}

try { new Email({ to: "foo@example.com", subject: "testing", body: "foo", template: "bar" }) } 
catch(e) {
    test.ok(e.match('junto com "template"'), "error: too much body")
}

try { new Email({ to: "foo@example.com", subject: "testing", body: "foo", template: "bar" }) } 
catch(e) {
    test.ok(e.match('junto com "template"'), "error: too much body")
}


var email = new Email({ to: "foo@example.com", subject: "testing", body: "foo" })
test.like(email, { to: "foo@example.com", subject: "testing", body: "foo" }, "email fields")

// TODO fix minion db connection to test send()
// var job_id = email.send()
// test.ok(job_id.match(/^\d+$/), 'job_id')
