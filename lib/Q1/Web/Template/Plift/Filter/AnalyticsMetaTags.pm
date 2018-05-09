package Q1::Web::Template::Plift::Filter::AnalyticsMetaTags;

use utf8;
use Moo;
use namespace::autoclean;
use Data::Dumper;
use JSON::XS qw/encode_json/;

has 'engine' => ( is => 'ro', required => 1, weak_ref => 1 );



sub process {
    my ($self, $doc) = @_;

    my $engine  = $self->engine;
    my $tx = $engine->context->{tx};

    # find <head>
    my $head = $doc->find('head')->first;
    unless ($head->size) {
        $tx->app->log->debug("AnalyticsMetaTags could not find the <head> element.") if $tx && $engine->debug;
        return;
    }

    # find analytics id
    my $id = $tx && $tx->has_app_instance
        ? $tx->app_instance->config->{google_analytics_id}
        : $engine->context->{google_analytics_id};

    return unless $id;

    # skip for non-production
    if ($engine->environment ne 'production') {
        $head->append('<!-- in production, google analytics will be inserted here, using id '.$id.'  -->');
        return;
    }

    # skip for admin
    if ($tx && $tx->user_exists && $tx->user->check_roles('instance_admin')) {
        $head->append('<!-- google analytics disabled for admin -->');
        return;
    }

    # inject script
    my $commands = $engine->context->{google_analytics_commands} || [];

    unshift @$commands, ['create', $id, 'auto']
        unless scalar(@$commands) > 0 && $commands->[0][0] eq 'create';

    push @$commands, ['send', 'pageview']
        unless scalar(@$commands) > 1 && $commands->[-1][0] eq 'send';

    my $commands_string = join "\n", map { "ga($_);" } map {
        my $str = encode_json $_;
        substr $str, 1, length($str) - 2; # remove leading/trailing []
    } @$commands;

    my $script = q!
    <script>
      (function(i,s,o,g,r,a,m){i['GoogleAnalyticsObject']=r;i[r]=i[r]||function(){
      (i[r].q=i[r].q||[]).push(arguments)},i[r].l=1*new Date();a=s.createElement(o),
      m=s.getElementsByTagName(o)[0];a.async=1;a.src=g;m.parentNode.insertBefore(a,m)
      })(window,document,'script','//www.google-analytics.com/analytics.js','ga');
    !;

    $script .= $commands_string . '</script>';

    $head->append($script);
}






1;


__END__
=pod

=head1 NAME

Q1::Web::Template::Plift::Filter::AnalyticsMetaTags

=head1 VERSION

Version 0.1

=head1 DESCRIPTION

=head1 METHODS

=head1 AUTHORS & COPYRIGHT

Carlos Fernando Avila Gratz - cafe _at_ q1software.com

=head1 LICENSE

Copyright Q1Software.

=cut
