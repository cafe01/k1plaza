use Test::K1Plaza;


my $js = app->build_controller->js;


isa_ok $js, 'JavaScript::V8::CommonJS';

js_test("native/jquery");

js_test("form/field");
js_test("form/field/text");
js_test("form/field/email");
js_test("form/field/textarea");
js_test("form/class");
js_test("form/instance");
js_test("form/render");

done_testing;
