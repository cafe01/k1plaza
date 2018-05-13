use Test::K1Plaza;


my $js = app->build_controller->js;


isa_ok $js, 'JavaScript::V8::CommonJS';

# p app->js->paths;

js_test("native/jquery");

js_test("form/field");
js_test("form/field/text");
js_test("form/field/email");
js_test("form/field/textarea");
js_test("form/class");
js_test("form/instance");
js_test("form/subclass");
js_test("form/render");
js_test("form/loader");

done_testing;
