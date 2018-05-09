package K1Plaza::Plugin::Apis;
use Mojo::Base 'Mojolicious::Plugin';
use K1Plaza::Apis;

sub register {
    my ($self, $app) = @_;

    my $apis = K1Plaza::Apis->new( namespaces => [ref($app).'::API']);

    $app->helper(apis => sub { $apis });

    $app->helper(api => sub {
        $apis->load_api(@_);
    });
}












1;
