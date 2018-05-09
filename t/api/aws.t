
use Test::K1Plaza;
use FindBin;
use Mojo::Util qw/ md5_sum /;
use Mojo::File qw/ path /;

my $app = app();

my $api = $app->api('AWS');

subtest '_sign_request' => sub {

    no warnings 'redefine';
    local *DateTime::_core_time = sub { 1369353600 };

    local $api->{s3_access_id} = 'AKIAIOSFODNN7EXAMPLE';
    local $api->{s3_secret_key} = 'wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY';

    my $tx = app->ua->build_tx( PUT
        => 'http://examplebucket.s3.amazonaws.com/test$file.text'
        => { 'x-amz-storage-class', 'REDUCED_REDUNDANCY' }
        => "Welcome to Amazon S3.");

    my $req = $tx->req;
    $api->_sign_request($req);

    is $req->headers->date, 'Fri, 24 May 2013 00:00:00 GMT', 'Date header';
    is $req->headers->host, 'examplebucket.s3.amazonaws.com', 'Host header';
    is $req->headers->header('x-amz-date'), '20130524T000000Z', 'x-amz-date header';
    is $req->headers->header('x-amz-content-sha256'), '44ce7dd67c959e0d3524ffac1771dfbba87d2b6b4b4e99e42034a8b803f8b072', 'x-amz-content-sha256 header';
    is $req->headers->authorization, 'AWS4-HMAC-SHA256 Credential=AKIAIOSFODNN7EXAMPLE/20130524/us-east-1/s3/aws4_request,SignedHeaders=date;host;x-amz-content-sha256;x-amz-date;x-amz-storage-class,Signature=98ad721746da40c64f1a55b78f14c238d841ea1380cd77a1b5971af0ece108bd', 'Authorization header';

    # diag $req->to_string;
};


subtest 'upload_s3_file' => sub {
    skip_all 'set S3_ACCESS_ID and S3_SECRET_KEY' unless $ENV{S3_ACCESS_ID} && $ENV{S3_SECRET_KEY};

    local $api->{s3_access_id} = $ENV{S3_ACCESS_ID};
    local $api->{s3_secret_key} = $ENV{S3_SECRET_KEY};

    my $file = "$FindBin::Bin/photo.jpg";


    $api->upload_s3_file($file, {
        key => 'test/k1plaza_aws_api_jpg',
        bucket => 'q1plaza-dev',
        acl => 'public-read',
        content_type => 'image/jpeg',
    })->then(sub {
        my $tx = shift;
        is $tx->res->code, 200, 'response code';
        my $etag = md5_sum(path($file)->slurp);
        is $tx->res->headers->etag, qq/"$etag"/, 'response etag';
    })->wait;
};



done_testing();
