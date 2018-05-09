package K1Plaza::AppInstance::PazEterna::Resource::Medicos;
use Mojo::Base 'K1Plaza::Resource::DBIC';
use Data::Printer;

use mro;


sub _api {
    my $c = shift;
    $c->api('Medicos');
}



1;
