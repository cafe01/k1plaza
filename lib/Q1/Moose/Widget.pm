package Q1::Moose::Widget;

use Moose ();
use Moose::Exporter;
use Q1::Moose::Widget::Role::Meta::Class;
use Q1::Moose::Widget::Role::Meta::Attribute;
use MooseX::IgnoreInvalidAttribute;
use namespace::autoclean;

Moose::Exporter->setup_import_methods(
    with_meta => [qw/ has_config has_param has_argument /],
    also      => [qw/ Moose MooseX::IgnoreInvalidAttribute /],
    class_metaroles => {
        class     => [ 'Q1::Moose::Widget::Role::Meta::Class' ],
        attribute => [ 'Q1::Moose::Widget::Role::Meta::Attribute' ],
    },
    role_metaroles => {
        attribute => [ 'Q1::Moose::Widget::Role::Meta::Attribute' ],
    }
);


# a config is an attribute that is persisted,
# can be set by the developer, but not by the user,
sub has_config {
    my ( $meta, $name, %options ) = @_;

    # create attribute
   # warn "Creating attr $name in $meta\n";
    $meta->add_attribute(
        $name,
        is        => $options{is_parameter} ? 'rw' : 'ro',
        predicate => "has_$name",
        %options,
        is_config => 1,
    );
}


# a param is an attribute that is NOT persisted,
# and can be set by the both, developer and user
sub has_param {
    my ( $meta, $name, %options ) = @_;

    die "The 'administrable' option is valid only for 'has_config' attributes"
        if exists $options{administrable};

    # create attribute
    $meta->add_attribute(
        $name,
        predicate => "has_$name",
        %options,
        is => 'rw',
        is_parameter => 1,
        ignore_if_invalid => 1,
    );
}



# an argument is an attribute that is NOT persisted,
# and can be set by the both, developer and user
# and is usualy extracted from the URL
sub has_argument {
    my ( $meta, $name, %options ) = @_;

    die "The 'administrable' option is valid only for 'has_config' attributes"
        if exists $options{administrable};

    # create attribute
    $meta->add_attribute(
        $name,
        predicate => "has_$name",
        %options,
        is => 'rw',
        is_argument => 1,
    );
}








1;








__END__
=pod

=head1 NAME

Q1::Moose::Widget

=head1 VERSION

Version 0.1

=head1 DESCRIPTION

=head1 METHODS

=head1 AUTHORS & COPYRIGHT

Carlos Fernando Avila Gratz - cafe _at_ q1software.com

=head1 LICENSE

Copyright Q1Software.

=cut
