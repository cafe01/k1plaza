package Q1::Web::Widget::API::GuestBook;

use utf8;
use Moose;
use namespace::autoclean;

extends 'DBIx::Class::API';

with 'Q1::API::Widget::TraitFor::API::BelongsToWidget';

has 'tx', is => 'ro', required => 1;


__PACKAGE__->config(    
    dbic_class         => 'GuestBook',    
    sortable_columns   => [qw/ me.created_at /],
    default_list_order => { -desc => 'me.created_at' },
);



around '_prepare_create_object' => sub {
    my $orig   = shift;
    my $self   = shift;       
    my $object = shift;
        
    # author
    if ($self->tx->user_exists) {
        $object->{author_id} = $self->tx->user->id;        
    }    

    $self->$orig($object);
};



__PACKAGE__->meta->make_immutable();

1;


__END__
=pod

=head1 NAME

Q1::Web::Widget::API::GuestBook

=head1 VERSION

Version 0.1

=head1 DESCRIPTION

=head1 METHODS

=head2 call

=head1 AUTHORS & COPYRIGHT

Carlos Fernando Avila Gratz - cafe _at_ q1software.com

=head1 LICENSE

Copyright Q1Software.

=cut