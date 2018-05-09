package K1Plaza::Plugin::Developer;
use Mojo::Base 'Mojolicious::Plugin';

sub register {
    my ($self, $app) = @_;


    # hostnmae hook

    # controller namespace

    # static/templates
    push @{$app->static->paths}, $app->home->child('share/developer/static')->to_string;
    push @{$app->renderer->paths}, $app->home->child('share/developer/template')->to_string;

    # router
    $app->routes->get('/.dev' => { template => 'devops' });

    # dispatch hook
    $app->hook( after_dispatch => sub {

        # has website selected


    });

}












1;
