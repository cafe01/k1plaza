package K1Plaza::JS::Jobs;

use strict;
use warnings;
use Hash::Util::FieldHash 'fieldhash';
# use Mojo::JSON qw/ to_json /;
use JSON::XS;

fieldhash my %c;

my $JSON = JSON::XS->new->pretty->allow_blessed;


sub new {
    my ($class, $mojo_c) = @_;
    my $self = bless \( my $object ), $class;
    $c{$self} = $mojo_c;
    return $self;
}


my $format = sub {
    return map { ref $_ ? $JSON->encode($_) : $_ } @_
};


sub push {
    my $self = shift;
    my $task_name = shift or die "[Jobs] missing task name";
    my $c = $c{$self};
    
    my $metadata = {
        app_instance => $c->app_instance->to_json,
        renderer_paths => $c->app->renderer->paths,
        static_paths => $c->app->static->paths,
    };
    
    my $id = $c->minion->enqueue($task_name, [@_], { notes => $metadata });
    $c->log->info("Adicionado job '$task_name' (id: $id)", $format->(@_));
    
    $id;
}





1;
