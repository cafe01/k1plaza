use Test::K1Plaza;


# prepare app instance
my $c = app->build_controller;
app->api('AppInstance')->register_app('foobarsite');
($c->stash->{__app_instance}) = app->api('AppInstance')->instantiate_by_alias('foobarsite');


# instantiate widget
subtest 'instantiate widget by type' => sub {
    my $widget = $c->widget('Menu');
    isa_ok $widget, 'Q1::Web::Widget::Menu';
};

subtest 'instantiate widget by name' => sub {
    my $widget = $c->widget('slider');
    isa_ok $widget, 'Q1::Web::Widget::Gallery';
};


done_testing;
