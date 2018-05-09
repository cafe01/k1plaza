package MooseX::IgnoreInvalidAttribute;

use utf8;
use Moose;
use Moose::Exporter;
use Moose::Util::MetaRole;


Moose::Exporter->setup_import_methods( 
    class_metaroles => {
        attribute        => ['MooseX::IgnoreInvalidAttribute::Trait::Attribute'],    
    },
    base_class_roles => ['MooseX::IgnoreInvalidAttribute::Trait::Class'],    
);


1;


__END__
=pod

=head1 NAME

lib::MooseX::IgnoreInvalidAttribute

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