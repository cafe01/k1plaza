package Q1::Utils::ConfigLoader;

use Moo;
use namespace::autoclean;
use Hash::Merge qw( merge );
use YAML::Any ();

sub loadConfigFile {
	my ($self, $file) = @_;

	if ($file =~ /\.yml$/) {
	    return YAML::Any::LoadFile($file);
	}

	die "Only YAML files supported. Not '$file'";
}




sub load_merged_config_files {
	my ($self, @files) = @_;

	my $result = {};

	foreach (reverse @files) {
	    my $config = $self->loadConfigFile($_);
	    $result = merge($config, $result);
	}

	$result;
}



1;
