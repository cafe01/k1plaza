package Q1::Web::Widget::API::Links;

use utf8;
use Moose;
use namespace::autoclean;

extends 'DBIx::Class::API';

with 'Q1::API::Widget::TraitFor::API::BelongsToWidget';


__PACKAGE__->config(    
    dbic_class         => 'Links', 
);


__PACKAGE__->meta->make_immutable();

1;


__END__
=pod

=head1 NAME

Q1::Web::Widget::API::Links

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