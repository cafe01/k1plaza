package MooseX::IgnoreInvalidAttribute::Trait::Class;

use Moose::Role;
use namespace::autoclean;



around BUILDARGS => sub {
    my ($orig, $class) = (shift, shift);    
    my $args = $class->$orig(@_);
    
    my $meta = $class->meta;
    
    # init_args
    my %init_args = map { $_->init_arg => $_ } $meta->get_all_attributes;

    # delete args that fail validation
    foreach my $arg_name (keys %$args) {
        my $attr = $init_args{$arg_name};
        next unless $attr && $attr->ignore_if_invalid;
        next unless $attr->type_constraint;
        
        delete $args->{$arg_name} unless $attr->type_constraint->check($args->{$arg_name});        
    }
    
    $args;
};





1;


__END__
=pod

=head1 NAME

MooseX::IgnoreInvalidAttribute::Trait::Class

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