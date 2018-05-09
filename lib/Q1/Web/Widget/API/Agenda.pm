package Q1::Web::Widget::API::Agenda;

use utf8;
use Moose;
use namespace::autoclean;
use Q1::Utils::HTML::Excerpt;

extends 'DBIx::Class::API';

with 'DBIx::Class::API::Feature::Permalink',
     'Q1::API::Widget::TraitFor::API::BelongsToWidget';



__PACKAGE__->config(
    dbic_class          => 'AgendaRecord',
    sortable_columns    => [qw/ me.date /],
    default_list_order  => { -asc => 'me.date' },
    #return_inflated_columns => [qw/ date /]
);


has '_html_excerpt' => (
    is  => 'ro',
    isa => 'Q1::Utils::HTML::Excerpt',
    default => sub{ Q1::Utils::HTML::Excerpt->new },
    handles => {
        _create_excerpt => 'excerpt'
    }
);


before 'list' => sub {
    my ($self, $args) = (@_);
    $args //= {};

    $self->modify_resultset( \[ 'YEAR(me.date) = ?', $args->{year} ] )
        if $args->{year};

    $self->modify_resultset( \[ 'MONTH(me.date) = ?', $args->{month} ] )
        if $args->{month};

    $self->where( permalink => $args->{permalink} )
        if defined $args->{permalink};

    # period & order
    my $order_direction = '-desc';

    if ($args->{period} eq 'future') {
        $self->where( date => { '>=' => \'CURDATE()' } );
        $order_direction = '-asc';
    }

    $self->where( date => { '<' => \'CURDATE()' } )
        if $args->{period} eq 'past';

    $self->order_by({ $order_direction => 'me.date' });
};

around '_prepare_create_object' => sub {
    my $orig   = shift;
    my $self   = shift;
    my $object = shift;

    # excerpt
    $object->{excerpt} = $self->_create_excerpt($object->{content});

#    # thumbnail_url
#    $object->{has_manual_thumbnail} = 1 if $object->{thumbnail_url};
#
#    if (not $object->{has_manual_thumbnail} and $object->{content} && $object->{content} =~ /<img.*?src="(.*?)".*?>/s) {
#        $object->{thumbnail_url} = $1;
#    }

    $self->$orig($object);
};


around '_update_object' => sub {
    my $orig = shift;
    my $self = shift;
    my ($item) = @_;
    my $object  = $item->{object};

    if ($object->is_column_changed('content')) {

        # update excerpt
        $object->excerpt($self->_create_excerpt($object->content));

#        # update thumbnail_url
#        if (not $object->has_manual_thumbnail and $object->content =~ /<img.*?src="(.*?)".*?>/s) {
#            $object->thumbnail_url($1);
#        }
    }

    $self->$orig(@_);
};
















__PACKAGE__->meta->make_immutable();

1;


__END__

=pod

=head1 NAME

Q1::Web::Widget::API::Agenda

=head1 DESCRIPTION

=head1 METHODS

=head2 call

=head1 AUTHORS & COPYRIGHT

Carlos Fernando Avila Gratz - cafe _at_ q1software.com

=head1 LICENSE

Copyright Q1Software.

=cut
