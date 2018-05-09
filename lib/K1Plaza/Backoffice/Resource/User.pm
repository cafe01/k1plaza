package K1Plaza::Backoffice::Resource::User;
use Mojo::Base 'K1Plaza::Resource::DBIC';
use Data::Printer;

use mro;


sub _api {
    my $c = shift;
    my $api = $c->api('User')->with_related('roles');
    my $appid = $c->req->query_params->param('appid') or die "Missing appid query param.";
    $api->app_instance_id($appid);
    $api;
}



1;
