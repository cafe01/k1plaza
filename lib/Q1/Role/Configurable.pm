package Q1::Role::Configurable;

use Moose::Role;
use namespace::autoclean;
use Data::Dumper;

=head1 NAME

Q1::Role::Configurable - Catalyst-like config() for your class.

=head1 SYNOPSIS



    package MyApp;

    use Moose;
    with 'Q1::Role::Configurable';

    __PACKAGE__->mk_classdata('_config');

    __PACKAGE__->config( foo => 'bar', ...);


    # the later ...
    my $app = MyApp->new( foo => 'something', baz => 'lol' ); # new() will get called with { foo => 'something', baz => 'lol' }


=head1 DESCRIPTION

Enables a class to be configured in the same way as a L<Catalyst::Component>.


=head1 METHODS

=head2 config(%class_config || \%class_config)

Uses the %class_config hash as default values for new(). Any values passed to new() are merged on top of the %class_config hash.

Returns: $class

=cut




sub config {
    my $class = shift;

    if (@_) {
        my $class_config = { %{@_ > 1 ? {@_} : $_[0]} };

		$class->meta->add_around_method_modifier('BUILDARGS', sub {
		    my $orig  = shift;
		    my $class = shift;

		    if (@_) {
		        my $newconfig = { %{@_ > 1 ? {@_} : $_[0]} };
		        return $class->$orig( %$class_config, %$newconfig );
		    }

		    return $class->$orig($class_config);
		});
    }

    return $class;
}





1;
