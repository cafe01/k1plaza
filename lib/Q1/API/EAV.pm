package Q1::API::EAV;

use Moo;
use namespace::autoclean;
use DBIx::EAV;
use Data::Printer;

has 'tx', is => 'ro', required => 1;
has 'app_instance_id', is => 'ro';

has 'eav', is => 'ro',
           init_arg => undef,
           lazy => 1,
           handles => [qw/ schema declare_entities type resultset /],
           default =>
sub {
    my $self = shift;
    my $eav_config = $self->tx->config->{eav} || {};
    DBIx::EAV->new(
        %$eav_config,
        dbh => $self->tx->app->schema->storage->dbh,
        tenant_id => $self->app_instance_id,
        enable_multi_tenancy => 1
    );
};


sub BUILD {
    my $self = shift;
    return unless $self->tx->has_app_instance;
    my $entities = $self->tx->app_instance->config->{entities} || {};
    # p $entities;
    $self->declare_entities($entities);
}










1;
