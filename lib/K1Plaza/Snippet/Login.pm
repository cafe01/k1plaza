package K1Plaza::Snippet::Login;

use utf8;
use Moo;
use namespace::autoclean;
use Data::Printer;


sub process {
	my ($self, $element, $engine) = @_;
	my $tx = $engine->context->{tx};
	my $app_config = $tx->has_app_instance ? $tx->app_instance->config : {};
	my $req = $tx->req;

	# prepare links
	# K1Plaza
	my %href;
	if ($req->can('url')) {
		my $url = $req->url->clone;
		$href{google} = $url->query([ provider => 'google' ])->to_string;
		$href{facebook} = $url->query([ provider => 'facebook' ])->to_string;
	}
	# K1Plaza
	else {
		my $url = $req->uri->clone;
		$url->query_form({ $url->query_form, provider => 'google' });
		$href{google} = $url->as_string;
		$url->query_form({ $url->query_form, provider => 'facebook' });
		$href{facebook} = $url->as_string;
	}

    # google login link
    $element->find('a.login-google-link')->attr( href => "$href{google}" );

    # remove fb button unless facebook application is configured
	my $fb_config = $tx->is_auth_host ? $tx->config->{facebook} : $app_config->{facebook} || $tx->config->{facebook};
    $element->find('a.login-facebook-link')->remove()
        unless $fb_config && $fb_config->{app_id} && $fb_config->{app_secret};

    # facebook login link
    $element->find('a.login-facebook-link')->attr( href => "$href{facebook}" );
}


1;


__END__
