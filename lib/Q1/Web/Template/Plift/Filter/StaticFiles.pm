package Q1::Web::Template::Plift::Filter::StaticFiles;

use utf8;
use Moo;
use namespace::autoclean;
use CSS::Sass;
use Digest::MD5 qw(md5_hex);
use Encode qw(encode_utf8);
use CSS::Minifier::XS qw/ minify /;
use Mojo::File qw/path/;
use Data::Printer;

has 'engine' => ( is => 'ro', required => 1, weak_ref => 1 );
has 'path_re' => ( is => 'rw', default => sub{  qr![./]*?/static/?! } );


sub process {
    my ($self, $doc) = @_;
    my $engine = $self->engine;
    my $tx = $engine->context->{tx};

    my $re = $self->path_re;

    my $cache_buster;
    if    ($tx && $tx->app->mode eq 'development') { $cache_buster = int rand 9999 }
    elsif ($tx && $tx->has_app_instance && $tx->app_instance->is_managed) {
        $cache_buster = $tx->app_instance->deployment_version;
    }

    $doc->find('link[href], a[href], img[src], script[src]')->each(sub {
        my $attr_name = defined $_->attr('href') ? 'href' : 'src';
        my $path = $_->attr($attr_name);

        # ignore full urls and anchors
        return if $path =~ m(^#|:?//);

        # remove legacy ".static" thing
        $path = $1 if $path =~ /^$re(.*)/;

        # portable link only
        if ($_->tagname eq 'a') {
            my $url = $tx ? $tx->url_for($path)->to_abs : "/$path";
            $_->attr(href => "$url");
            return;
        }

        # sass
        if ($attr_name eq 'href' && $path =~ /\.scss$/) {

            # find file
            my ($sass_file, $static_path) = $self->_find_static_file($path);

            if ($sass_file) {
                my ($css_file, $css_version) = $self->_compile_sass($sass_file);
                $path = $css_file->to_rel($static_path)->to_string .'?v='.$css_version;
            }
        }

        my $no_cdn = defined $_->attr('data-no-cdn');
        $_->remove_attr('data-no-cdn');
        my $url = $tx ? $tx->uri_for_static($path, { use_cdn_host => $no_cdn ? 0 : 1}) : "/$path";

        # add cache buster
        if ($cache_buster && !$url->query->to_string) {
            $url->query->append( __dc =>  $cache_buster );
        }

        $_->attr($attr_name, "$url");

    });

  # replace commented-out paths (eg. IE-only css files)
  my $head = $doc->find('head');
  if ($head->size) {
      my $head_text = $head->html;

        while ($head_text =~ /href="$re(.*?)"/) {
            my $uri = $tx ? $tx->uri_for_static($1) : "/$1";
            $head_text =~ s/href="$re.*?"/href="$uri"/;
        }
        while ($head_text =~ /src="$re(.*?)"/) {
            my $uri = $tx ? $tx->uri_for_static($1) : "/$1";
            $head_text =~ s/src="$re.*?"/src="$uri"/;
        }

      $head->html($head_text);
  }

  $doc;
}


sub _find_static_file {
    my ($self, $rel_path) = @_;
    $rel_path =~ s!\.{2,}/!!g;

    foreach my $path (@{ $self->engine->static_path }) {
        $path = path($path) unless ref $path;
        my $file = $path->child($rel_path);
        return ($file, $path) if -f $file;
    }

    my $tx = $self->engine->context->{tx};
    $tx->log->error('[StaticFiles] Could not find SASS file: '.$rel_path);

    return undef;
}


sub _compile_sass {
    my ($self, $sass_file) = @_;
    my $engine = $self->engine;

    # files
    my ($name) = split /\./, $sass_file->basename;
    my $css_dir = $sass_file->dirname->sibling('css');
    my $css_file = $css_dir->child($name.'.css');
    my $prod_css_file = $css_dir->child($name.'-production.css');
    my $id_file = $css_dir->child($name.'.css.version');

    # no compile
    if ($engine->environment ne 'development' || $engine->context->{_sass_no_compile} ) {
        # should always exist, unless wrongly deleted
        die "[Plift] can't find css id file '$id_file'" unless -f $id_file;
        my $content_id = $id_file->slurp;
        return ($prod_css_file, $content_id);
    }


    # compile
    my $map_file = $css_dir->child($name.'.css.map');
    my $sass =  CSS::Sass->new(
        dont_die        => 1,
        include_paths   => [$sass_file->dirname, @{$engine->sass_include_path||[]}],
        source_map_file => $map_file,
        output_style    => SASS_STYLE_NESTED,
        output_path     => $css_file

    );

    my ($content, $src_map) = $sass->compile_file($sass_file);

    # TODO replace absolute fs path from error msg by relative path to static dir
    die sprintf("[Plift] sass error: %s\n", $sass->last_error)
        unless defined $content;

    # make path
    $css_dir->make_path;

    # fingerprint
    # my $content_id = sprintf('%x', murmur_hash($content));
    $content = encode_utf8 $content;
    my $content_id = md5_hex($content);

    # if changed, save to disk
    if (!-f $id_file || $id_file->slurp ne $content_id) {

        # save original
        $css_file->dirname->make_path;
        $css_file->spurt($content);

        $prod_css_file->spurt(minify($content));

        $id_file->spurt($content_id);

        $map_file->spurt($src_map->{source_map_string});
    }

    return ($css_file, $content_id);
}

1;


__END__
=pod

=head1 NAME

Q1::Web::Template::Plift::Filter::StaticFiles

=head1 VERSION

Version 0.1

=head1 DESCRIPTION

=head1 METHODS

=head1 AUTHORS & COPYRIGHT

Carlos Fernando Avila Gratz - cafe _at_ q1software.com

=head1 LICENSE

Copyright Q1Software.

=cut
