package K1Plaza::API::AWS;

use Mojo::Base -base;
use Mojo::Util qw/ url_escape trim /;
use DateTime;
use Digest::SHA qw/ sha256_hex hmac_sha256_hex hmac_sha256 /;
use Mojo::File 'path';
use Data::Printer;

has 'app' => sub { die 'required' };

has 's3_access_id'  => sub { shift->app->config->{aws}{s3_access_id}  || die 'Missing "aws.s3_access_id" app config.' };
has 's3_secret_key' => sub { shift->app->config->{aws}{s3_secret_key} || die 'Missing "aws.s3_secret_key" app config.' };

has 'service' => sub { 's3' };
has 'region' => sub { 'us-east-1' };


sub upload_s3_file {
    my ($self, $file, $params) = @_;
    my $ua = $self->app->ua;
    $file = path($file);

    die "File '$file' doesn't exist." unless -f $file;

    $params->{filename} //= $file->basename;

    my $disposition_type = $params->{attachment} ? 'attachment' : '';
    my %headers = (
        $params->{content_type} ? ('Content-Type' => $params->{content_type}) : (),
        'Content-Disposition' => qq/$disposition_type; filename="$params->{filename}"/,
        'x-amz-acl' => $params->{acl} || 'private',
    );
    my $tx = $ua->build_tx(PUT => "http://$params->{bucket}.s3.amazonaws.com/$params->{key}" => \%headers => $file->slurp);
    $self->_sign_request($tx->req);

    # warn $tx->req->headers->to_string;
    $ua->start_p($tx);
}


sub _sign_request {
    my ($self, $req) = @_;
    my $log = $self->app->log;
    my $headers = $req->headers;

    # Host header
    $headers->host($req->url->host) unless $headers->host;

    # add date header
    my $now = DateTime->now;
    $headers->date($now->format_cldr("E, dd LLL YYYY HH:mm:ss 'GMT'"));
    $headers->header('x-amz-date' => $now->format_cldr("YYYYMMdd'T'HHmmss'Z'"));

    # x-amz-content-sha256
    my $body_sha256 = sha256_hex($req->body);
    unless ($req->headers->header('x-amz-content-sha256')) {
        $req->headers->header('x-amz-content-sha256', $body_sha256);
    }

    # https://docs.aws.amazon.com/AmazonS3/latest/API/sig-v4-header-based-auth.html
    # 1.a CanonicalRequest
    my @signed_headers = sort grep { /Host|Date|Content-Type|x-amz/ } @{$headers->names};
    my $canonical_request = join "\n",
        $req->method,
        '/'.join('/', map { url_escape $_ } @{$req->url->path}),
        $req->url->query->to_string,
        join("\n", map { lc($_).':'.trim($headers->header($_)) } @signed_headers)."\n",
        join(';', map { lc } @signed_headers),
        $body_sha256;

    # $log->debug("[AWS] CanonicalRequest:", $canonical_request);

    # 1.b StringToSign
    my $string_to_sign = join "\n",
        "AWS4-HMAC-SHA256",
        $headers->header('x-amz-date'),
        join('/', $now->format_cldr("YYYYMMdd"), $self->region, $self->service, 'aws4_request'),
        sha256_hex("$canonical_request");

    # $log->debug("[AWS] StringToSign:", $string_to_sign);

    # 2. SigningKey
    my $signing_key =
        hmac_sha256("aws4_request",
            hmac_sha256($self->service,
                hmac_sha256($self->region,
                    hmac_sha256($now->format_cldr("YYYYMMdd"), "AWS4".$self->s3_secret_key))));


    # 3. Signature
    my $signature = hmac_sha256_hex($string_to_sign, $signing_key);
    # $log->debug("[AWS] Signature: $signature");

    # 4. Authorization header
    my $authorization_header = 'AWS4-HMAC-SHA256 '.join ",",
        'Credential='.join('/', $self->s3_access_id, $now->format_cldr("YYYYMMdd"), $self->region, $self->service, 'aws4_request'),
        'SignedHeaders='.join(';', map { lc } @signed_headers),
        "Signature=$signature";

    $headers->authorization($authorization_header);
}





1;
