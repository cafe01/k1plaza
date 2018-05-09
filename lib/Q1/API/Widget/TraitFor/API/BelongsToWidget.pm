package Q1::API::Widget::TraitFor::API::BelongsToWidget;

use Moose::Role;
use namespace::autoclean;
use Carp;

# TODO analyse if weak_ref is correct! Created issue in DBIC Resource filling this attribute.
has 'widget' => ( is => 'rw', isa => 'Object', clearer => 'clear_widget', predicate => 'has_widget' );

# return $self
around 'widget' => sub {
    my $orig = shift;
    my $self = shift;
    my $rv = $self->$orig(@_);
    return @_ ? $self : $rv;
};


before [qw/ list create update delete find find_or_create create_or_update /] => sub {
    my $self = shift;

    confess "You must set the widget attribute to use this API!"
        unless $self->widget;
};

around '_prepare_create_object' => sub {
    my $orig  = shift;
    my $self  = shift;
    my $object  = shift;

    $object->{widget_id} = $self->widget->db_object->id;

    $self->$orig($object);
};

around '_prepare_read' => sub {
    my $orig  = shift;
    my $self  = shift;

    $self->modify_resultset({ 'me.widget_id' => $self->widget->db_object->id });

    $self->$orig(@_);
};


# bump version
after [qw/ create update delete /] => sub {
    my $self = shift;
    $self->widget->db_object->bump_version
        unless $self->has_errors;
};



1;


__END__

=pod

=head1 NAME

Q1::API::Widget::TraitFor::API::BelongsToWidget

=head1 SYNOPSIS

    package MyApp::API::Stuff;

    use Moose;
    use namespace::autoclean;

    extends 'DBIx::Class::API';
    with 'Q1::API::Widget::TraitFor::API::BelongsToWidget';

    ...


=head1 DESCRIPTION

To be consumed by APIs whose resultset belongs to a Widget.

=head1 METHODS

=head2 around _prepare_create_object

Automatically populates the widget_id column of each item being created.
Dies badly if the widget attribute is undefined.

=cut
