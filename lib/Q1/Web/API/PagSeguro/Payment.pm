package Q1::Web::API::PagSeguro::Payment;

use Data::Dumper;
use Moo;
use namespace::autoclean;
use Q1::Web::API::PagSeguro::PaymentItem;

use feature qw(signatures);
no warnings qw(experimental::signatures);

extends 'Q1::Web::API::PagSeguro::Request';

has '+url', default => 'https://ws.pagseguro.uol.com.br/v2/checkout/';
has '+payment_url', default => 'https://pagseguro.uol.com.br/v2/checkout/payment.html';

sub add_item($self, %item) {

    my $item = Q1::Web::API::PagSeguro::PaymentItem->new(%item);
    push @{$self->{items}}, $item;

    $item;
}


sub total ($self) {
    my $total = 0;
    foreach my $item (@{$self->{items}}) {
        $total += $item->subtotal
    }
    $total;
}

sub _mangle_params {
    my ($self, $params) = @_;

    for (my $i = 0; $i < scalar @{$self->{items}}; $i++) {
        my $item = $self->{items}[$i];
        my $item_index = $i + 1;

        foreach my $prop (qw/ id description quantity weight /) {
            push @$params, 'item'.ucfirst($prop).$item_index, $item->$prop
                if defined $item->$prop;
        }

        push @$params, 'itemAmount'.$item_index, sprintf '%.2f', $item->amount;
        push @$params, 'itemShippingCost'.$item_index, sprintf '%.2f', $item->shipping_cost
            if defined $item->shipping_cost;
    }
}

1;
