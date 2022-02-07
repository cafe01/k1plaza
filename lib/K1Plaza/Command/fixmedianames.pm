package K1Plaza::Command::fixmedianames;
use Mojo::Base 'Mojolicious::Commands';
use Mojo::File 'path';
use Mojo::Util 'decode', 'encode';
# use utf8;

has description => 'Fix overriden media names';
has usage       => 'k1plaza fixmedianames export';

sub run {
    my ($self, $input) = @_;
    my $app = $self->app;
    my $log = $app->log;
    my $api = $app->api('Media');

    if ($input) {

        my $file = path($input);

        die "Invalid file $file" unless -f $file;

        my $content = $file->slurp;
        my @lines = split "\n", $content;
        
        for (@lines) {
            my ($id, $file_name) = split ',';
            print "$id:$file_name\n";
            $api->resultset->search({ id => $id })->update({ file_name => $file_name });
        }


        return;    




    }

    # dump id,file_name
    my @medias = $api->resultset->search({ has_file => 1});
    my $count = 0;

    $log->info(sprintf "Found %d medias.", scalar @medias);

    foreach my $media (@medias) {
        printf STDOUT "%s,%s\n", $media->id, encode('UTF-8', $media->file_name);
    }

}



1;
