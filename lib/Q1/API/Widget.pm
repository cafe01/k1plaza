package Q1::API::Widget;

use strict;
use Moose;
use namespace::autoclean;
use Try::Tiny;

extends 'DBIx::Class::API';
with 'Q1::API::AppInstance::TraitFor::API::BelongsToAppInstance';


has '+dbic_class', default => 'Widget';
has 'tx', is => 'ro', required => 1;


sub list_active {
    my $self = shift;
    my $tx = $self->tx;

    $self->push_object_formatter(sub {
        my ($self, $object, $out) = @_;
        my $widget = try { $tx->widget($object->name) };
        unless ($widget) {
            $out->{is_stale} = 1;
            return;
        }

        $out->{config} = $widget->config;
    });

    my $data = $self->list->result;

    # filter out stale widgets
    @{$data->{items}} = grep { not $_->{is_stale}  } @{$data->{items}};
    $data->{total} = @{$data->{items}};
    $data;
}



1;


__END__

=pod

=head1 NAME

Q1::API::Widget::API

=head1 DESCRIPTION

=cut
