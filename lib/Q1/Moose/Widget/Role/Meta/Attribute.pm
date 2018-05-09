package Q1::Moose::Widget::Role::Meta::Attribute;

use Moose::Role;
use namespace::autoclean;

has [qw/ is_config is_argument is_parameter /] => (
    is        => 'rw',
    isa       => 'Bool',
    default   => 0
);


1;


__END__

=pod

=head1 NAME

Q1::Moose::Widget::Role::Meta::Attribute

=head1 DESCRIPTION

=head1 METHODS

=head2 call

=head1 AUTHORS & COPYRIGHT

Carlos Fernando Avila Gratz - cafe _at_ q1software.com

=head1 LICENSE

Copyright Q1Software.

=cut
