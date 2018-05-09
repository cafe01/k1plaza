package Q1::AppInstance;

use Moo;
use namespace::autoclean;
use Carp;
use Types::Standard qw/ Object HashRef Str /;


has 'id', is => 'ro', required => 1;
has 'uuid', is => 'ro', required => 1;
has 'name', is => 'ro', required => 1;
has 'base_dir', is => 'ro', isa => Object, required => 1;
has 'config', is => 'ro', isa => HashRef, required => 1;

has 'is_managed', is => 'ro', default => 0;

has 'canonical_alias', is => 'ro', required => 1;
has 'current_alias', is => 'ro', lazy => 1, default => sub { shift->canonical_alias };
has 'environment', is => 'ro', required => 1;

has 'deployment_version', is => 'ro';



# TODO: avaliate those for deprecation: sitemap, skin
# has 'sitemap' => (  is => 'rw', isa => Object, predicate => 'has_sitemap' );
has 'skin' => ( is => 'rw', isa => HashRef, predicate => 'has_skin' );


# setup hook
sub setup {}



sub path_to {
    my ($self, @path) = @_;
    my $basedir = $self->base_dir;
    my $path = $basedir->child(@path);

    # raise security alert if $path is outside of base_dir
    if ($path =~ /\.\./) {
        $path = $path->realpath;

        my $check = "^$path";
        $check = qr/$check/;

        unless ($path =~ $check) {
            die "[security] blocked attempt to create path '$path' outside of app instance base dir '$basedir'";
            # TODO emit security alert
        }
    }

    $path;
}


# TODO generate app instance secret
#sub secret {
#	my ($self) = @_;
#}



1;

__END__

=pod

=head1 NAME

Q1::AppInstance

=head1 VERSION

Version 0.1

=head1 DESCRIPTION

Part of Q1::API::AppInstance, this class represents a application instance (app-instance), allowing custom logic to be developed per app-instance.

=head1 METHODS

=head2 setup

Noop by default. Usefull on subclasses.

=head1 AUTHORS & COPYRIGHT

Carlos Fernando Avila Gratz - cafe _at_ q1software.com

=head1 LICENSE

Copyright Q1Software.

=cut
