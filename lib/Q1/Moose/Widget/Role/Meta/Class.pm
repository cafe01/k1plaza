package Q1::Moose::Widget::Role::Meta::Class;

use Moose::Role;
use namespace::autoclean;

has 'config_list' => (
    is => 'ro',
    init_arg => undef,
    lazy => 1,
    default => sub {
        [
            map { $_->name } grep { $_->can('is_config') && $_->is_config } shift->get_all_attributes
        ]
    }
);

has 'argument_list' => (
    is => 'ro',
    init_arg => undef,
    lazy => 1,
    default => sub {
        [
            map { $_->name } grep { $_->can('is_argument') && $_->is_argument } shift->get_all_attributes
        ]
    }
);

has 'parameter_list' => (
    is => 'ro',
    init_arg => undef,
    lazy => 1,
    default => sub {
        [
            map { $_->name } grep { $_->can('is_parameter') && $_->is_parameter } shift->get_all_attributes
        ]
    }
);



1;


__END__

=pod

=head1 NAME

Q1::Moose::Widget::Role::Meta::Class

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head2 config_list

=head2 argument_list

=head2 parameter_list

=head1 AUTHOR

Carlos Fernando Avila Gratz - cafe _at_ q1software.com

=cut
