package Q1::Web::API::Payment::DB;

use Moose;
use namespace::autoclean;
use utf8;
use Carp qw/ carp /;


extends 'DBIx::Class::API';
with 'Q1::API::AppInstance::TraitFor::API::BelongsToAppInstance';



sub _prepare_related_status {
    my ($self, $value) = @_;
    return $value if ref $value;
    carp 'invalid payment status' unless defined $value && length $value;
    $self->get_status($value);
}

sub _prepare_related_provider {
    my ($self, $value) = @_;
    return $value if ref $value;
    carp 'invalid payment provider' unless defined $value && length $value;
    $self->get_provider($value);
}


sub find_by_reference {
    my ($self, $reference) = @_;
    $self->find({ reference => $reference })->first;
}

sub get_status {
    my ($self, $value) = @_;
    $self->resultset->result_source->schema->resultset('PaymentStatus')->find_or_create({ name => $value });
}

sub get_provider {
    my ($self, $value) = @_;
    $self->resultset->result_source->schema->resultset('PaymentProvider')->find_or_create({ name => $value });
}










1;
