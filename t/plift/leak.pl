#!/usr/bin/env perl
#
use utf8;
use strict;
use warnings;
use Data::Dumper;
use FindBin;
use lib 'lib';
use lib 't/lib';
use Q1::Web::Template::Plift;
use Devel::Cycle;
use Path::Tiny;
use JavaScript::V8;
use Devel::Size qw(size total_size);
use Proc::ProcessTable;

system 'clear';

my $context = JavaScript::V8::Context->new( time_limit => 5 );

my $plift = Q1::Web::Template::Plift->new(
    include_path => [$FindBin::Bin ."/templates/javascript/"],
    javascript_include_path => [path($FindBin::Bin ."/templates/javascript/")],
    enable_profiler => 0, 
    debug => 1,
    javascript_context => $context
);

$context->name_global('q1');

#$context->bind( print => sub { print total_size(shift), "\n" });


while(1) {
    my $html = $plift->process('page');
    my $rv = $context->idle_notification;
    warn "IN: $rv\n";
}
   
#print find_cycle($plift);
#
#
#print "done\n";
#
#
#sub memory_usage {
#    my $t = new Proc::ProcessTable;
#    foreach my $got (@{$t->table}) {
#        next
#            unless $got->pid eq $$;
#        return $got->size / 1024 / 1024 / 10;
#    }
#}