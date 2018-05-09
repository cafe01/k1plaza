package K1Plaza::Resource::Media;

use Mojo::Base 'Mojolicious::Controller';
use Data::Printer;
use File::Temp qw/ tempfile /;
use Mojo::File 'path';
use Mojo::Asset::File;
use File::stat;
use HTTP::Date;;

sub _api {
    my $c = shift;
    my $api = $c->api('Media', {use_json_boolean => 0} );

    if (my $widget_name = $c->req->param('widget')) {
        $api->widget( $c->widget($widget_name) );
    }

    $api;
}


sub list {
    my $c = shift;
    my $res = $c->_api->list($c->req->query_params->to_hash)->result;
    $c->render(json => $res);
}

sub list_single {
    my $c = shift;
    my $object = $c->_api->find($c->stash->{id})->result->{items}
        or return $c->reply->not_found;

    my $data = $object;
    my $res = $c->param('envelope')
        ? { success => \1, items => $data }
        : $data;

    $c->render(json => $res );
}

sub create {
    my ($c) = @_;

    my $req = $c->req;
    my $data = $req->body_params->to_hash;
    my $max_width = delete $data->{maxWidth};

    # file upload
    if (my $upload = $req->upload('file')) {

        my $asset = $upload->asset;
        $data->{file_name} = $upload->filename;

        if ($asset->is_file) {

            $data->{file} = $asset->path;
        }
        else {
            # my ($ext) = $data->{file_name} =~ /(\.\w+$)/;
            (undef, my $tempfile) = tempfile('k1plaza-upload-XXXXXXX', OPEN => 0, DIR => '/tmp');
            $data->{file} = $tempfile;
            $asset->move_to($data->{file});
            $upload->asset(Mojo::Asset::File->new(path => $tempfile, cleanup => 1 ));
        }

    }

    my $api = $c->_api;
    $api->max_image_width($max_width) if $max_width && $max_width < $api->max_image_width;
    my $res = $api->create($data)->result;

    # error
    if ($res->{success} == 0 || $res->{errors}) {
        $c->res->code(400);
        return $c->render(json => $res);
    }

    # 303 See Other
    my $url = $c->url_for('list_single_media', id => $res->{items}[0]{id});
    $url->query($c->req->url->query);
    $c->res->code(303);
    $c->redirect_to($url);
}

sub update {
    my ($c) = @_;

    my $object = $c->_api->find($c->stash->{id})->first
        or return $c->reply->not_found;

    my $data = $c->req->json || $c->req->body_params->to_hash;
    $data->{id} = $c->stash->{id};

    my $res = $c->_api->update($data)->result;
    $c->render( json => $res );
}

sub remove {
    my ($c) = @_;

    my $object = $c->_api->find({ id => $c->stash->{id} })->first
        or return $c->reply->not_found;

    my $res = $c->_api->delete({ id => $c->stash->{id} })->result;

    $c->render( json => $res );
}

sub reposition {
    my ($c) = @_;

    my $data = $c->req->json || $c->req->body_params->to_hash;
    my $res = $c->_api->reposition($data->{collection}, $data->{src_media}, $data->{dst_media})->result;
    $c->rendered($res->{success} ? 204 : 400);
}

sub download {
    my ($c) = @_;
    my $log = $c->app->log;

    my $file_path = $c->stash->{file_path}
        or return $c->reply->not_found;

    # find media
    my ($uuid) = $file_path =~ /(\w+)\./; # no extension
    my $media = $c->_api->find_by_uuid( $uuid );

    return $c->reply->not_found
        unless $media && $media->has_file;

    # force browser download
    $c->res->headers->content_disposition('attachment; filename='.$media->file_name.';')
        if $c->req->param('download');

    # serve local file
    unless ($media->get_column('s3file')) {

        $c->res->headers->content_type($media->file_mime_type);
        return $c->reply->asset(Mojo::Asset::File->new(path => $media->file));
    }

    # serve S3 file
    my ($bucket, $s3_path) = $media->get_column('s3file') =~ /(.*?)\/(.*)/;
    my $local_file = path("/tmp/amazons3/$bucket/$s3_path");

    my $url = sprintf 'http://%s.s3.amazonaws.com/%s', $bucket, $s3_path;
    my %headers = (
        -f $local_file ? ('If-Modified-Since' => time2str(stat($local_file)->mtime)) : ()
    );

    $log->debug("Downloading S3 file: $bucket/$s3_path");
    $c->stash->{'k1plaza.response_promise'} = $c->ua->get_p($url => \%headers)->then(sub {
        my $tx = shift;
        my $result = $tx->result;

        # not modified
        if ($result->code == 304) {
            $log->debug("S3 file not modified. Using local copy.");
        }
        else {
            $log->debug("Saving S3 file local copy.");

            path($local_file->dirname)->make_path;
            $result->content->asset->move_to($local_file);
            # set mtime to generate correct ETag
            utime(stat($local_file)->atime, str2time($result->headers->last_modified), $local_file);
        }

        $c->res->content->asset(Mojo::Asset::File->new(path => $local_file));
    })->catch(sub {
      my $err = shift;
      $log->error("S3 Connection error: $err");
      $c->reply->exception;
    });

    $c->render_later;
}


1;
