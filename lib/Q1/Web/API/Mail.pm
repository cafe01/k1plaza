package Q1::Web::API::Mail;

use Data::Printer;
use Moo;
use namespace::autoclean;
use Template;
use MIME::Entity;
use MIME::Types;
use Email::Sender::Simple qw(sendmail);
use Email::Sender::Transport::SMTP;
use Try::Tiny;
use Carp qw/ confess /;
use Mojo::File qw/ path /;
use Encode qw/ encode /;

has 'tx', is => 'ro', required => 1;

my $mime_types = MIME::Types->new;

sub new_mail {
	my ($self, $params) = @_;

    my %top_entity_args = map { defined $params->{$_} ? ($_ => $params->{$_}) : () }
		qw/ from to cc bcc subject reply-to /;

	confess "Can't send message without the 'to' parameter!!!" unless $top_entity_args{to};

    my @parts;

    # txt message
    if ( $params->{body} || $params->{template} ) {
        my $content = $params->{body} || $self->_process_template($params->{template}, $params);
        push @parts, MIME::Entity->build(
            Charset => 'UTF-8',
            Data    => $content,
            Top     => 0
        );
    };

    # html message
    if ( $params->{html_body} || $params->{html_template} ) {
        my $content = $params->{html_body} || $self->_process_template($params->{html_template}, $params);
        push @parts, MIME::Entity->build(
            Type    => 'text/html',
            Charset => 'UTF-8',
            Data    => $content,
            Top     => 0
        );
    };

    # main entity
    my $mail = MIME::Entity->build(
        Charset => 'UTF-8',
        Type => 'multipart/alternative',
        %top_entity_args,
    );

    $mail->add_part($_) foreach @parts;

    # attachments
    if ($params->{attachments}) {
    	$params->{attachments} = [$params->{attachments}] unless ref $params->{attachments} eq 'ARRAY';
    	foreach my $file (@{$params->{attachments}}) {
			my ($path, $filename, $opts) = ref $file ? @$file : ($file, path($file)->basename);
		    $mail->attach(
		        # Path     => $path,
				Data => path($path)->slurp,
				Filename => $filename,
		        Type     => $mime_types->mimeTypeOf($filename),
		        Encoding => "base64",
		        Disposition => "attachment",
            );

			unlink $path if $opts && $opts->{cleanup};
    	}
    }

    $mail;
}


sub _process_template {
	my ($self, $template, $params) = @_;

	my $tt = Template->new({
		INCLUDE_PATH => $params->{include_path} || $self->tx->app->renderer->paths,
	    ERROR        => 'error.tt',
	    ENCODING     => 'UTF-8',
	});

    # process
    my $output;
    unless ($tt->process($template, $params->{template_data} || {}, \$output)) {
        my $error = $tt->error;
        print STDERR "_process_template() template error:\nerror type: ", $error->type, "\n";
        print STDERR "error info: ", $error->info, "\n";
        confess $error;
    }

	encode 'UTF-8', $output;
}


sub send {
    my ($self, $msg) = @_;

	$msg->print(\*STDERR) if $ENV{DEBUG_EMAIL};

	my $config = $self->tx->app->config->{smtp} or die "missing 'smtp.*' app config";
	for (qw/ host port username password /) {
		die "missing 'smtp.$_' app config" unless $config->{$_}
	}

    my $transport = Email::Sender::Transport::SMTP->new({
		timeout => 10,
        host => $config->{host},
        port => $config->{port},
		helo => $config->{host},
		ssl  => $config->{ssl} || 0,
		sasl_username => $config->{username},
		sasl_password => $config->{password},
    });

    my $return_value = 1;

    try {
        sendmail( $msg, { transport => $transport } );
    } catch {
        $self->tx->log->error("[Mail] sendmail() failed: $_");
        $return_value = 0;
    };

    $return_value;
}

sub send_mail {
	my $self = shift;
	$self->send($self->new_mail(@_));
}


sub send_system_alert_mail {
	my ($self, $description, $exception) = @_;
	$description ||= 'system alert';

	my $app = $self->tx->app;
	my $log = $self->tx->app->log;
	my $mail_to = $app->config->{system_alert_email_recipient}
		or return $log->error("Can't send_system_alert_mail(): 'system_alert_email_recipient' app config is empty.");

	my $c = $self->tx;
	my $req = $c->req;

    my $data = {
        appinstance => $c && $c->has_app_instance ? $c->app_instance->name : '-',
        uri         => $req->can('uri') ? $req->uri : $req->url->to_abs,
        method      => $req->method,
        timestamp   => DateTime->now
    };

    # send email
	my $subject = sprintf('[%s] %s: %s %s', $data->{appinstance}, $description, $data->{method}, $data->{uri});
    my $success = $self->send_mail({
        from    => '"Q1Plaza" <donotreply@q1software.com>',
        to      => $mail_to,
        subject => $subject,
        body    => sprintf "App: %s\nRequest: %s %s\nIP: %s\nUser-Agent: %s\nTimestamp: %s\n\n%s",
            $data->{appinstance},
            $data->{method},
            $data->{uri},
            $c->tx->remote_address,
            $req->headers->user_agent,
            $data->{timestamp},
            $exception
		});

    $log->error("Error senting 'exception alert' email! ($subject)")
        unless $success;
}








1;
