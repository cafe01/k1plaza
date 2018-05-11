package K1Plaza::JS::Request;

use strict;
use warnings;
use Hash::Util::FieldHash 'fieldhash';

fieldhash my %req;

sub new {
    my ($class, $mojo_request) = @_;
    my $self = bless \( my $object ), $class;
    $req{$self} = $mojo_request;
    return $self;
}


sub params {
    my $self = shift;
    $req{$self}->params->to_hash;
}

sub queryParams {
    my $self = shift;
    $req{$self}->query_params->to_hash;
}

sub bodyParams {
    my $self = shift;
    my $req = $req{$self};
    $req->json || $req->query_params->to_hash;
}

sub header {
    my $self = shift;
    my $name = shift or return;
    $req{$self}->headers->header($name);
}


1;
