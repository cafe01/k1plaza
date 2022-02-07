package K1Plaza::Plugin::Medias;

use Mojo::Base 'Mojolicious::Plugin';
use Data::Printer;
use Mojo::URL;
use Mojo::Util qw/ md5_sum /;
use Mojo::File qw/ path /;

sub register {
    my ($self, $app) = @_;

    $app->helper(uri_for_media => \&_uri_for_media);

    $app->minion->add_task(upload_s3_media => \&_upload_s3_media);

}


sub _uri_for_media {
    my ($c, $media, $options) = @_;
    return '' unless $media; # allow vivify
    my $app = $c->app;

    $options ||= {};
    $media   ||= {};

    $options->{default_format} ||= 'jpg';

    # try to expand a string relative uri into a compatible hash
    if (! ref $media) {
        $c->log->debug("Plain link media.");
        if ($media =~ /^\/.*?([a-z0-9]{32}).*/ || $media =~ /.*\/\.media\/file\/([a-z0-9]{32}).*/) {
            $media = { uuid => $1, file_mime_type => '' };
        } else {
            $c->log->debug("Plain link media is incompatible ($media).");
            return $media;
        }
    }

    # work with a hash
    $media = {$media->get_columns} unless ref $media eq 'HASH'; # assume its a dbic row object if its not a hashref

    $options->{zoom}    ||= $options->{z};
    $options->{bgcolor} ||= $options->{color};

    my %type_ext;
    map { $type_ext{$_} = 'jpg' } qw( image/jpeg );
    map { $type_ext{$_} = 'png' } qw( image/png );
    map { $type_ext{$_} = 'gif' } qw( image/gif );

    my $ext = $options->{format} || ($media->{file_mime_type} ? $app->types->detect($media->{file_mime_type})->[0] : '') || $options->{default_format};

    # <prefix>/<uuid>[_<scale>[-<flags>[<color>]]].<ext>
    my $file_path    = $media->{uuid};

    # filters
    $file_path .= '_'.$options->{scale} if $options->{scale};
    $file_path .= sprintf('_%sx%s', $options->{width} || '', $options->{height} || '')
        if $options->{width} || $options->{height};

    $file_path .= '-crop' if $options->{crop} && ($options->{scale} || $options->{width} || $options->{height});
    $file_path .= '-z'.$options->{zoom} if ($options->{zoom});

    if (exists $options->{fill}) {
        $options->{fill} =~ s/^#// if $options->{fill};
        $file_path .= $options->{fill} ? '-fill0x'.$options->{fill} : '-fill';
    }

    if ($media->{s3file}) {
        my @parts = split '/', $media->{s3file};
        my $bucket = shift @parts;

        if ($media->{uuid} eq $file_path) {
            # without filters, serve directly from S3
            return $app->config->{amazon_s3_use_cname}
                ? Mojo::URL->new(sprintf 'http://%s/%s', $bucket, join('/', @parts))
                : Mojo::URL->new(sprintf 'http://%s.s3.amazonaws.com/%s', $bucket, join('/', @parts));
        }

        # ($ext) = $parts[-1] =~  /\.(\w+)$/;
    }

    $ext = lc $ext;
    $ext = 'jpg' if $ext eq 'jpeg';

    my $prefix = $app->config->{media_file_prefix} || '/.media/file';
    $c->app->config->{cdn_host} ? do {
        my $url = $c->req->url->base->clone;
        $url->host($c->app->config->{cdn_host});
        $url->scheme('http');
        $url->query({});
        $url->path(sprintf "%s%s/%s", $c->app_instance->canonical_alias, $prefix, "$file_path.$ext");
        $url;

    }
    : Mojo::URL->new("$prefix/$file_path.$ext")->to_abs($c->req->url->base);
}


sub _upload_s3_media {
    my ($job, $media_id) = @_;
    my $app = $job->app;
    my $log = $app->log;

    my $media = $app->schema->resultset('Media')->find($media_id)
        or return $job->fail("Couldn't find media via id '$media_id'");

    return $job->finish("Media was already on S3.")
        if $media->get_column('s3file');

    # upload
    my $aws = $app->api('AWS');
    my $file = path($media->file);

    my $uuid = $media->uuid;
    my ($ext) = $media->file_name =~ /\.(\w+)$/;
    my $key = sprintf ".media/%s/%s", substr($uuid, 0, 3), $uuid;
    my $bucket = $app->config->{amazon_s3_bucket}
        or return $job->fail("Can't upload media to AmazonS3. Missing 'amazon_s3_bucket' app config.");


    $log->debug(sprintf "[Media:%d] uploading file '%s' to S3...", $media_id, $file);

    $aws->upload_s3_file($file, {
        key => $key,
        bucket => $bucket,
        acl => 'public-read',
        filename => $media->file_name,
        content_type => $media->file_mime_type,
    })
    ->then(sub {
        my $tx = shift;

        # awd error?
        unless ($tx->result->is_success) {
            return $job->fail("AWS error:\n".$tx->res->body);
        }

        my $file_md5 = md5_sum($file->slurp);
        unless ($tx->res->headers->etag =~ /$file_md5/) {
            return $job->fail(sprintf "Returned ETAG %s != %s", $tx->res->headers->etag, $file_md5);
            die;
        }

        # update row
        # $log->debug("S3 upload ok. Updating local media.");
        $media->update({
            s3file => "$bucket/$key",
            file    => undef
        }) or die "Media record update failed.";

        # delete local file
        unlink "$file";
        $job->finish("Uploaded to http://$bucket/$key and deleted local file '$file'");
    })
    ->catch(sub {
        my $error = shift;
        $log->error("S3 upload exception: $error");
        $job->fail($error);
    })
    ->wait;
}


1;
