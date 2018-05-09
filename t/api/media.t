#!perl
use Test::K1Plaza;
use FindBin;
use Data::Printer;
use Mojo::File qw/path/;


# api
my $c = app->build_controller;
($c->stash->{__app_instance}) = app->api('AppInstance')->register_app('foobarsite');
my $api = $c->api('Media');

# create image (file => Path::Class::File)
my $res = $api->create({ file => path("$FindBin::Bin/photo.jpg") })->result;
# p $res;

test_media($res->{items}->[0], {
    app_instance_id => 1,
    is_audio => 0,
    is_video => 0,
    is_image => 1,
    has_file => 1,
    is_external => 0,
    external_id => undef,
    external_provider => undef,
    thumbnail_small => undef,
    thumbnail_large => undef,
    waveform_url => undef,
    s3file => undef,
    file_size => 2313,
    file_name => 'photo.jpg',
    file_mime_type => 'image/jpeg',
    width => 64,
    height => 64,
    duration => undef,
    #metadata => undef,
}, 1, 'create image (file object)');


# create image (file => String)
$res = $api->create({ file => "$FindBin::Bin/photo.jpg" })->result;

test_media($res->{items}->[0], {
    app_instance_id => 1,
    is_audio => 0,
    is_video => 0,
    is_image => 1,
    has_file => 1,
    is_external => 0,
    external_id => undef,
    external_provider => undef,
    thumbnail_small => undef,
    thumbnail_large => undef,
    waveform_url => undef,
    s3file => undef,
    file_size => 2313,
    file_name => 'photo.jpg',
    file_mime_type => 'image/jpeg',
    width => 64,
    height => 64,
    duration => undef,
    #metadata => undef,
}, 1, 'create image (file path)');


# create video (online)
# $res = $api->create({ url => 'http://www.youtube.com/watch?v=AKrtwuX3Tdk' })->result;
#diag Dumper($res);

# test_media($res->{items}->[0], {
#     app_instance_id => 1,
#     is_audio => 0,
#     is_video => 1,
#     is_image => 0,
#     has_file => 0,
#     is_external => 1,
#     external_id => 'AKrtwuX3Tdk',
#     external_provider => 'youtube',
#     thumbnail_small => qr!default.jpg!,
#     thumbnail_large => qr!hqdefault.jpg!,
#     waveform_url => undef,
#     s3file => undef,
#     file => undef,
#     file_size => undef,
#     file_name => undef,
#     file_mime_type => undef,
#     width => undef,
#     height => undef,
#     duration => 236,
#     #metadata => undef,
# }, 0, 'create video (online)');

# # create audio (online)
# $res = $api->create({ url => 'http://soundcloud.com/mr-vj/mr-vj-kill-kill' })->result;
#
# test_media($res->{items}->[0], {
#     app_instance_id => 1,
#     is_audio => 1,
#     is_video => 0,
#     is_image => 0,
#     has_file => 0,
#     is_external => 1,
#     external_id => '36781630',
#     external_provider => 'soundcloud',
#     thumbnail_small => qr!^https://i1.sndcdn.com/artworks-000018444913-lhvm85-large.jpg!,
#     thumbnail_large => undef,
#     waveform_url => 'https://w1.sndcdn.com/I9hfoQ5rbes1_m.png',
#     s3file => undef,
#     file => undef,
#     file_size => undef,
#     file_name => undef,
#     file_mime_type => undef,
#     width => undef,
#     height => undef,
#     duration => 179816,
#     #metadata => undef,
# }, 0, 'create audio (online)');

# create file using AmazonS3 storage
subtest 's3file' => sub {

    skip_all "To test AmazonS3 media storage, set the 'S3_ACCESS_ID' and 'S3_SECRET_KEY' env vars."
        unless $ENV{S3_ACCESS_ID} && $ENV{S3_SECRET_KEY};

    local app->config->{media_storage_type} = 'amazons3';
    local app->config->{amazon_s3_bucket} = 'q1plaza-dev.q1cdn.net';

    my $minion = app->minion;
    $minion->backend->reset;

    $res = $api->create({ file => "$FindBin::Bin/photo.jpg" })->result;
    my $media = $res->{items}[0];
    like $media->{file}, qr/\w-/, 'media file stored locally';

    $minion->perform_jobs;

    my $updated_media = app->schema->resultset('Media')->find($media->{id});
    like $updated_media->get_column('s3file'), qr/q1plaza-dev.q1cdn.net/, "s3file col";
    is $updated_media->get_column('file'), undef, "file col";
};



# find_media_by_uuid
# my $test_uuid = ResultSet('Media')->search({ has_file => 1 })->first;
# my $media = $api->find_by_uuid($test_uuid->uuid);
# is $media->id, $test_uuid->id, 'find_media_by_uuid()';
#
# # TODO: wrong usage
#
# # list result has media url
# $res = $api->list->result;
# is $res->{items}->[0]->{url}, 'http://app01.com/.media/file/some_fake_uuid.jpg', 'list result has media url';
# #diag Dumper $res->{items}->[0];
#
#
#
# # delete all created files
# $api->resultset->delete_all;


done_testing;




sub test_media {
	my ($got, $expected, $has_file, $testname) = @_;

    like $got, {
        id      => qr/^\d+$/,
        file    => $has_file ? qr/^[a-f0-9]{2}\/[a-f0-9-]{36}$/i : undef,
        uuid        => qr/^\w{32}$/,
        url         => qr!/.media/file/\w{32}\.\w{3}!,
        created_at  => qr/\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}/,
        updated_at  => qr/\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}/,
        %$expected
    }, $testname;
}
