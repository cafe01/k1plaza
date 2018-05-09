package K1Plaza::Command::eavload;
use Mojo::Base 'Mojolicious::Commands';
use Data::Printer;
use Mojo::File 'path';
use Mojo::JSON qw(decode_json);

$|++;

has description => 'Load EAV entities';
has usage       => 'k1plaza eavload <website hostname> <json file> [unique key]';

sub run {
    my ($self, $hostname, $data_file, $unique_key) = @_;
    die "\nUsage: ".$self->usage."\n\n" unless ($hostname && $data_file);

    my $log = $self->app->log;
    my $c = $self->app->build_controller;
    return unless $c->detect_app_instance($hostname);

    # load data
    return $log->error("File '$data_file' doesn't exist, yo!")
        unless -e $data_file;


    my $data = decode_json path($data_file)->slurp;

    my $eav = $c->api('EAV');
    foreach my $type (keys %$data) {


        my $rs = $eav->resultset($type);
        my $items = $data->{$type};
        $log->info(sprintf "Loading %d %s records:", scalar(@$items), $type);
        foreach (@$items) {
            # $log->debug($_->{nome});
            if ($unique_key && $rs->count({ $unique_key => $_->{$unique_key} })) {
                print ".";
                next;
            }

            $rs->insert($_);
            print '+';
        }
        print "\n";
    }
}


1;
