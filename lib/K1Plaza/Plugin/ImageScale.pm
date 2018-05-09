package K1Plaza::Plugin::ImageScale;

use Mojo::Base 'Mojolicious::Plugin';
use Mojo::Util qw(md5_sum);
use Data::Printer;
use File::Temp qw/ tempfile /;
use File::stat;
use Imager;


sub register {
    my ($self, $app, $config) = @_;
    $config ||= {};

    $app->hook(around_dispatch => sub {
        my ($next, $c) = @_;

        my $req = $c->req;
        my $url = $req->url;

        # do nothing unless is a image file request
        # 8180b48cd5cb11e7b86d99bf0a7f6e79_50x50-crop.jpg
        return $next->() unless $req->method eq 'GET';

        # scale params
        my %params;
        if ($url->path->parts->[-1] && (@params{qw/ width height crop format/} = $url->path->parts->[-1] =~ /_(\d*)x(\d*)(-crop|)\.(png|jpg|jpeg)$/)) {

            $params{process} = 1;

            # rewrite path
            # my $path = $url->path;
            $url->path->parts->[-1] =~ s/_\d*x\d*(?:-crop|)(\.\w+)$/$1/;
            # $url->path($path);
        }

        # fetch file
        my $response = $next->();

        # process
        if (my $promise = $c->stash->{'k1plaza.response_promise'}) {

            $promise->then(sub {
                # $c->log->debug(sprintf "Response promise fullfiled. %s", $c->res->content->asset->mtime);
                my $mtime = $c->res->content->asset->mtime;
                return $c->rendered(304) if $c->is_fresh(last_modified => $mtime, etag => md5_sum($mtime));

                $params{process} ? $self->_process_response($c, \%params, $config)
                                 : $c->reply->asset($c->res->content->asset);
            });
        }
        elsif (($c->res->code||'') == 200 && $params{process}) {
            # $c->log->debug("Response asset: ", $c->req->url->path, $c->res->content->asset, $c->res->content->asset->mtime);
            $self->_process_response($c, \%params, $config);
        }

        # done
        $response;
    });
}


sub _process_response {
    my ($self, $c, $params, $config) = @_;
    my $log = $c->app->log;

    # our params
    return unless $params && ($params->{width} || $params->{height});
    $log->debug(sprintf "Scaling image to %dx%d", $params->{width}, $params->{height});
    $params->{format} = 'jpeg' if $params->{format} eq 'jpg';
    # p $params;

    # resize image
    my $res = $c->res;

    my $image = Imager->new;
    my $input_format = $c->app->types->detect($res->headers->content_type)->[0];
    my $original_mtime = $res->content->asset->mtime;
    $image->read(data => $res->content->asset->slurp, type => $input_format) or die $image->errstr;

    my $orientation_index = $image->tags(name => 'exif_orientation');

    # scale
    $config->{max_width} ||= 2560;
    $config->{max_height} ||= 3000;
    $params->{width} = $config->{max_width}
        if $params->{width} && $params->{width} > $config->{max_width};

    $params->{height} = $config->{max_height}
        if $params->{height} && $params->{height} > $config->{max_height};

    my $scaled = $image->scale(
        xpixels => $params->{width},
        ypixels => $params->{height},
        type => 'max',
        qtype => 'mixing');

    # fix orientation
    if ($orientation_index) {

        my @operations = (
            [0, undef],
            [0, 'h'],
            [180, undef],
            [0, 'v'],
            [90, 'h'],
            [90, undef],
            [-90, 'h'],
            [-90, undef]
        );

        my ($degrees, $flip) = @{$operations[$orientation_index-1]};
        $scaled = $scaled->rotate(degrees => $degrees) if $degrees;

        if ($flip) {
            $scaled->flip(dir => $flip) or die "Error flipping image: ".$scaled->errstr;
        }
    }

    # crop
    if ($params->{crop} && $params->{width} && $params->{height}) {
        $scaled = $scaled->crop(width => $params->{width}, height => $params->{height});
    }

    # save sacled
    (undef, my $scaled_file) = tempfile('image-scale-XXXXXXX', SUFFIX => '.'.$params->{format}, OPEN => 0, DIR => "/tmp/");

    # replace body
    my $data;
    # $log->debug("Scaled file: $scaled_file");
    $scaled->write(file => $scaled_file, type => $params->{format}) or die $scaled->errstr;
    utime(stat($scaled_file)->atime, $original_mtime, $scaled_file); # keep original mtime for correct content negotiation
    $c->reply->asset(Mojo::Asset::File->new(path => $scaled_file, cleanup => 1 ));

}




1;
