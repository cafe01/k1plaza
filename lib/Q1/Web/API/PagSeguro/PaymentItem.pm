package Q1::Web::API::PagSeguro::PaymentItem;

use Data::Dumper;
use Moo;
use namespace::autoclean;


has 'id', is => 'ro', required => 1;
has 'description', is => 'ro', required => 1;
has 'amount', is => 'ro', required => 1;

has 'quantity', is => 'ro', default => 1;

has 'shipping_cost', is => 'ro';
has 'weight', is => 'ro';



sub subtotal {
    my $self = shift;
    $self->amount * $self->quantity;
}


1;
