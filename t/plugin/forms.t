use Test::K1Plaza;
use Test::Mojo;


my $app = app();
my $t = Test::Mojo->new;
$t->app($app);

my $api = $app->api('AppInstance');
$api->register_app('foobarsite');

# grab token for each request
my ($csrf_token, $stash);
$t->app->hook(after_dispatch => sub {
    my $c = shift;
    $csrf_token = $c->csrf_token;
    $stash = $c->stash;
});


# unknown form
$t->post_ok('/.form/unknown' => {'Host' => 'foobarsite'})
  ->status_is(404);

# missing csrf token
$t->post_ok('/.form/contato' => {'Host' => 'foobarsite'})
  ->status_is(403);

# invalid form fields
# diag "CSRF Token: $csrf_token";
my $form = {
    _csrf => $csrf_token
};
$t->post_ok('/.form/contato' => {'Host' => 'foobarsite', 'Accept' => 'application/json' } => json => $form)
  ->json_is('/success', 0)
  ->json_like('/errors/0', qr/Campo/)
  ->status_is(200);

# diag "Response body: ".$t->tx->res->body;

# valid form fields
$form = {
    _csrf => $csrf_token,
    name => 'Foo',
    email => 'foo@email.com',
    message => 'okay'
};

$t->post_ok('/.form/contato' => {'Host' => 'foobarsite', 'Accept' => 'application/json' } => json => $form)
  ->json_is('/success', 1)
  ->status_is(200);

$stash->{test_form_action} = $form->{email};

$t->post_ok('/.form/contato' => {'Host' => 'foobarsite'} => form => $form)
  ->status_is(302, 'redirect if not json');


done_testing();


{
    package K1Plaza::Form::Action::Test;
    use Mojo::Base '-base';

    sub process {
        my ($self, $ctx) = @_;
        $ctx->{tx}->stash->{test_form_action} = $ctx->{form}->field('email')->value;
    }
}
