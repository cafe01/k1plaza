use Test::K1Plaza;
use Mojo::JSON qw/encode_json/;

# prepare app instance
my $c = app->build_controller;
($c->stash->{__app_instance}) = app->api('AppInstance')->register_app('foobarsite');
my $res = $c->api('Media')->create({ file => app->home->child('share/image.png')->to_string })->result;

my $media = $res->{items}[0];

like $media->{uuid}, qr/\w{32}/, 'media uuid';
is $media->{url}, "/.media/file/$media->{uuid}.png", 'media url';


is $c->uri_for_media($media), "/.media/file/$media->{uuid}.png", 'uri_for_media';
is $c->uri_for_media($media, { width => 400, height => 200, crop => 1 }), "/.media/file/$media->{uuid}_400x200-crop.png", 'uri_for_media - crop';

# cdn host
app->config->{cdn_host} = 'supercdn';
is $c->uri_for_media($media), "http://supercdn/foobarsite/.media/file/$media->{uuid}.png", 'uri_for_media cdn host';


done_testing;
