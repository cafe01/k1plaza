package Q1::Web::API::Payment;

use Data::Dumper;
use Moo;
use namespace::autoclean;
use Data::UUID;
use Q1::Web::API::PagSeguro::Payment;
use Q1::Web::API::PagSeguro::Subscription;
use Q1::Web::API::PagSeguro::Notification;
use Q1::Web::API::PagSeguro::PreApprovalNotification;
use Q1::Web::API::Payment::DB;

use feature qw(signatures);
no warnings qw(experimental::signatures);


has 'tx', is => 'ro', required => 1;

has 'use_sandbox', is => 'rw', lazy => 1, default => sub {
    return 1 if $ENV{USE_PAYMENT_SANDBOX};
    my $tx = shift->tx;
    return 1 if $tx->app_instance->config->{use_payment_sandbox};
    0;
};

has 'db',
    is => 'ro',
    init_arg => undef,
    lazy => 1,
    default => sub {
        my $self = shift;
        Q1::Web::API::Payment::DB->new(
            app_instance_id => $self->tx->app_instance->id,
            resultset => $self->tx->app->schema->resultset('Payment')
        )
    };



sub new_payment($self, $data = {}) {

    return { errors => ['invalid_provider'] }
        unless $data->{provider} && $data->{provider} eq 'pagseguro';


    my $cfg = $self->tx->app_instance->config->{pagseguro};
    return { errors => ['invalid_provider_config'] }
        unless $cfg->{email} && $cfg->{token};

    # create on provider
    my $uuid = lc Data::UUID->new->create_str;
    $uuid =~ tr/-//d;

    $data->{use_sandbox} = $self->use_sandbox;
    $data->{email} = $cfg->{email};
    $data->{token} = $cfg->{token};
    $data->{reference} = $uuid;

    my $items = delete $data->{items};
    return { errors => ['invalid_item_list'] }
        unless $items && ref $items eq 'ARRAY' && scalar @$items > 0;

    # create payment on provider
    my $payment = Q1::Web::API::PagSeguro::Payment->new(%$data);
    $payment->add_item(%$_) for @$items;

    my $payment_res = $payment->send_request;
    return $payment_res if $payment_res->{errors};

    # create payment on db
    my $db_res = $self->db->create({
        provider => 'pagseguro',
        status => 'new',
        account => $payment->email,
        reference => $uuid,
        sender_name => $payment->sender_name,
        sender_email => $payment->sender_email,
        currency => $payment->currency,
        amount => $payment->total,
        created_at => $payment_res->{date},
        metadata => $data->{metadata}
    })->result;

    return { errors => $db_res->{errors} }
        unless $db_res->{success};

    # success
    delete $payment_res->{code};
    $payment_res;
}

sub new_subscription($self, $data = {}) {

    return { errors => ['invalid_provider'] }
        unless $data->{provider} && $data->{provider} eq 'pagseguro';


    my $cfg = $self->tx->app_instance->config->{pagseguro};
    return { errors => ['invalid_provider_config'] }
        unless $cfg->{email} && $cfg->{token};

    # create on provider
    my $uuid = lc Data::UUID->new->create_str;
    $uuid =~ tr/-//d;

    $data->{use_sandbox} = $self->use_sandbox;
    $data->{email} = $cfg->{email};
    $data->{token} = $cfg->{token};
    $data->{reference} = $uuid;

    # create payment on provider
    my $payment = Q1::Web::API::PagSeguro::Subscription->new(%$data);
    my $payment_res = $payment->send_request;
    return $payment_res if $payment_res->{errors};

    # create payment on db
    my $db_res = $self->db->create({
        provider => 'pagseguro',
        status => 'new',
        account => $payment->email,
        reference => $uuid,
        sender_name => $payment->sender_name,
        sender_email => $payment->sender_email,
        currency => $payment->currency,
        amount => $payment->amount_per_payment,
        created_at => $payment_res->{date},
        metadata => $data->{metadata}
    })->result;

    return { errors => $db_res->{errors} }
        unless $db_res->{success};

    # success
    delete $payment_res->{code};
    $payment_res;
}



# TODO move this method to a PagSeguro-related module
sub fetch_pagseguro_notification($self, $code, $type) {

    my $cfg = $self->tx->app_instance->config->{pagseguro};
    return { error => 'invalid_provider_config' }
        unless $cfg->{email} && $cfg->{token};


    my $type_path = $type eq 'preApproval' ? 'pre-approvals' : 'transactions';
    my $url = sprintf "https://ws.%s.uol.com.br/v2/%s/notifications/%s?email=%s&token=%s",
        $self->use_sandbox ? 'sandbox.pagseguro' : 'pagseguro',
        $type_path,
        $code,
        $cfg->{email},
        $cfg->{token};

    my $res = $self->tx->ua->get($url);
    # warn "# $url";
    return { error => 'HTTP error: '.$res->status_line }
        unless $res->is_success;

    # parse
    my $notification_class = 'Q1::Web::API::PagSeguro::Notification';
    $notification_class = 'Q1::Web::API::PagSeguro::PreApprovalNotification'
        if $type eq 'preApproval';

    $notification_class->new( xml_source => $res->content );
}


sub process_notification($self, $notif) {

    my $db = $self->db;
    my $tx = $self->tx;

    # find payment
    $tx->log->debug("[Payment] find payment by reference: ".$notif->reference);
    my $payment = $db->find_by_reference($notif->reference);
    return { error => 'invalid_reference' }
        unless $payment;

    # change payment status
    my $status = $db->get_status($notif->status);

    $payment->update_from_related('status', $status)
        if $payment->status->name ne $notif->status;

    # save notification
    $payment->add_to_notifications({
        status => $status,
        raw    => $notif->xml_source,
        date   => $notif->date,
    });

    # app instance hook
    my $app_instance = $tx->app_instance;
    $app_instance->process_payment_notification($tx, $notif, $payment)
        if $app_instance->can('process_payment_notification');

    +{ success => 1 };
}


1;
