package Q1::Web::API::PagSeguro::Subscription;

use Data::Dumper;
use Moo;
use namespace::autoclean;
use DateTime::Format::W3CDTF;

extends 'Q1::Web::API::PagSeguro::Request';


has '+url', default => 'https://ws.pagseguro.uol.com.br/v2/pre-approvals/request';
has '+payment_url', default => 'https://pagseguro.uol.com.br/v2/pre-approvals/request.html';


has 'name', is => 'ro', required => 1;
has 'amount_per_payment', is => 'ro', required => 1;
has 'max_total_amount', is => 'ro', required => 1;
has 'final_date', is => 'ro', required => 1;

has 'details', is => 'ro';
has 'charge', is => 'ro', default => 'auto';
has 'period', is => 'ro', default => 'monthly';


sub _mangle_params {
    my ($self, $params) = @_;
    my $w3c = DateTime::Format::W3CDTF->new;

    foreach my $attr (qw/ name amount_per_payment max_total_amount final_date details charge period /) {
        next unless defined $self->$attr;
        my $param_name = 'preApproval' . join('', map { ucfirst } split('_', $attr));
        my $value = $self->$attr;

        $value = ref $value eq 'DateTime' ? $w3c->format_datetime($value) :
                 $attr =~ /amount/ ? sprintf '%.2f', $value :
                 $value;

        push @$params, $param_name, $value;
    }
}


1;
