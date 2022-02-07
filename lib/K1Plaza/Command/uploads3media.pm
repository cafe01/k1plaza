package K1Plaza::Command::uploads3media;
use Mojo::Base 'Mojolicious::Commands';

has description => 'Upload local media to s3.';
has usage       => 'k1plaza uploads3media [uuid]';

sub run {
    my ($self, $uuid) = @_;
    my $app = $self->app;
    my $log = $app->log;
    my $api = $app->api('Media');

    my @medias = $api->resultset->search({
        s3file => undef,
        $uuid ? (uuid => $uuid) : (),
    });

    my $count = 0;

    $log->info(sprintf "Found %d medias.", scalar @medias);

    foreach my $media (@medias) {
        if (!$media->file) {
            $log->info(sprintf "Skipping media '%s' (%s) (no file)", $media->uuid, $media->file_name);
            next;
        }

        my $id = $self->app->minion->enqueue(upload_s3_media => [$media->id]);
        $log->info(sprintf "[%d] Enqued upload_s3_media '%s' (job %d)", ++$count, $media->uuid, $id);
    }


}


1;
