package K1Plaza::Plugin::Minion;
use Mojo::Base 'Mojolicious::Plugin';

sub register {
    my ($self, $app, $args) = @_;
    my $config = $app->config;

    $app->plugin('Minion' => { mysql => {
        dsn      => "dbi:mysql:dbname=$config->{db_name};host=$config->{db_host};port=$config->{db_port}",
        username => $config->{db_username},
        password => $config->{db_password},
    }});

    $app->plugin('Minion::Admin' => { route =>  $args->{route} });

    $app->plugin('K1Plaza::Task::DeployRepository');
    $app->plugin('K1Plaza::Task::Email');
    $app->minion->remove_after(60*60*24*7);
}












1;
