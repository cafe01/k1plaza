package K1Plaza::JS::Jobs;

use strict;
use warnings;
use Hash::Util::FieldHash 'fieldhash';
use Mojo::JSON qw/ to_json /;

fieldhash my %c;



sub new {
    my ($class, $mojo_c) = @_;
    my $self = bless \( my $object ), $class;
    $c{$self} = $mojo_c;
    return $self;
}


my $format = sub {
    return map { ref $_ ? to_json($_) : $_ } @_
};


sub push {
    my $self = shift;
    my $task_name = shift or die "[Jobs] missing task name";
    my $c = $c{$self};
    
    my $id = $c->minion->enqueue($task_name => [@_]);
    $c->log->info("Adicionado job '$task_name' (id: $id)", $format->(@_));
    $id;
}





1;
