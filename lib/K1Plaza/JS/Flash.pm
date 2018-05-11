package K1Plaza::JS::Flash;

use strict;
use warnings;
use Hash::Util::FieldHash 'fieldhash';
use Data::Printer;

fieldhash my %c;

sub new {
    my ($class, $mojo_c) = @_;
    my $self = bless \( my $object ), $class;
    $c{$self} = $mojo_c;
    return $self;
}


sub get {
    my $self = shift;
    my $key = shift or return;
    $c{$self}->flash("$key");
}

sub set {
    my $self = shift;
    my $key = shift or return;
    die "Flash keys starting with __ are reserved for internal use."
        if $key =~ /^__/;

    $c{$self}->flash("$key", shift);
}


1;
