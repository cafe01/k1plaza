package Q1::Web::API::PagSeguro::Request;

use Data::Dumper;
use Moo;
use namespace::autoclean;
use URI;
use LWP::UserAgent;
use HTTP::Request::Common qw/ POST /;
use DateTime::Format::W3CDTF;
use Q1::jQuery;

use feature qw(signatures);
no warnings qw(experimental::signatures);

has 'use_sandbox', is => 'rw', default => 0;

has 'email', is => 'ro', required => 1;
has 'token', is => 'ro', required => 1;

has 'reference', is => 'ro';
has 'currency', is => 'ro', default => 'BRL';
has 'redirect_url', is => 'ro';
has 'url', is => 'ro', default => '';
has 'payment_url', is => 'ro', default => '';

has 'sender_name', is => 'ro';
has 'sender_email', is => 'ro';
has 'sender_phone', is => 'ro';
has 'sender_area_code', is => 'ro';
has 'sender_cpf', is => 'ro';
has 'sender_born_date', is => 'ro';

our $XML;


sub send_request($self) {

    # send request
    my $ua  = LWP::UserAgent->new( timeout => 15 );
    my $req = $self->_build_request;
    printf STDERR warn $req->as_string if $ENV{DEBUG_PAYMENT};
    my $res = $ua->request($req);
    printf STDERR warn $res->as_string if $ENV{DEBUG_PAYMENT};

    unless ($res->header('Content-Type') =~ /application\/xml/) {
        return { errors => ['Uknown response: '.$res->status_line."\n".$res->content] };
    }

    my $xml = _parse_xml($res->decoded_content);

    return { errors => [ map { $_->data } $xml->findnodes('//error/message/text()') ] }
        if $xml->findnodes('//error')->size > 0;

    # success
    return { errors => ['bad response: missing code'] }
        unless $xml->findnodes('//code')->size > 0;

    my $code = $xml->findnodes('//code/text()')->shift->data;

    my $w3c = DateTime::Format::W3CDTF->new;
    my $date = $w3c->parse_datetime( $xml->findnodes('//date/text()')->shift->data );

    my $checkout_url = $self->payment_url.'?code='.$code;
    $checkout_url =~ s/pagseguro/sandbox.pagseguro/ if $self->use_sandbox;

    +{
        code => $code,
        date => $date,
        checkout_url => $checkout_url,
        reference => $self->reference
    };
}

sub _build_request {
    my $self = shift;

    my @params = map  {
                    $_ eq 'redirectUrl' ? 'redirectURL':
                    $_ eq 'senderCpf'   ? 'senderCPF':
                    $_
                 }
                 map  { _camelize($_) => $self->$_ }
                 grep { defined $self->$_ }
                 qw/ email        token      reference    currency         sender_name
                     sender_email sender_cpf sender_phone sender_area_code sender_born_date
                     redirect_url /;

    my $url = $self->url;
    $url =~ s/pagseguro/sandbox.pagseguro/ if $self->use_sandbox;

    $self->_mangle_params(\@params);

    POST $url, \@params;
}

sub _mangle_params {}

sub _camelize {
    lcfirst join '', map { ucfirst } split('_', shift);
}

sub _parse_xml {

    if (!$XML) {
        $XML = XML::LibXML->new;
        $XML->recover(1);
        $XML->recover_silently(1);
        $XML->keep_blanks(0);
        $XML->expand_entities(1);
        $XML->no_network(1);
    }

    $XML->load_xml( string => \$_[0] );
}


1;
