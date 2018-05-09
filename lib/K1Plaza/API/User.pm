package K1Plaza::API::User;

use Moose;
use namespace::autoclean;
use utf8;

extends 'Q1::Web::API::User';


__PACKAGE__->meta->make_immutable();

1;