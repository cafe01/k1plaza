package K1Plaza::Task::Email;

use Mojo::Base 'Mojolicious::Plugin';
use DateTime;

sub register {
    my ($self, $app) = @_;

    $app->helper($_ => $self->can("_helper_$_"))
        for qw/ send_email send_system_alert_email /;

    $app->minion->add_task($_ => $self->can("_task_$_"))
        for qw/ send_email send_system_alert_email /;
}



sub _helper_send_email {
    my ($c, $params) = @_;
    $params->{include_path} = $c->app->renderer->paths;
    $c->minion->enqueue('send_email', [$params]);
}

sub _helper_send_system_alert_email  {
    my ($c, $subject, $body) = @_;
    $subject ||= 'system alert';


    $c->minion->enqueue('send_system_alert_email', [{
        subject     => $subject,
        body        => $body,
        appinstance => $c->has_app_instance ? $c->app_instance->name : '-',
        uri         => $c->req->url->to_abs,
        method      => $c->req->method,
        timestamp   => DateTime->now,
        user_agent  => $c->req->headers->user_agent,
        remote_address => $c->tx->remote_address,
    }]);
}


sub _task_send_email {
    my ($job, $params) = @_;
    $params->{include_path} ||= $job->info->{notes}->{renderer_paths};
    $job->app->api('Mail')->send_mail($params);
}


sub _task_send_system_alert_email {
    my ($job, $data) = @_;

    my $app = $job->app;
    my $log = $app->log;
    my $mail_to = $app->config->{system_alert_email_recipient};

    unless ($mail_to) {
        $log->error("[send_system_alert_email] missing 'system_alert_email_recipient' app config");
        return $job->fail("missing 'system_alert_email_recipient' app config");
    }

    my $success = $job->app->api('Mail')->send_mail({
        from    => '"K1Plaza" <donotreply@q1software.com>',
        to      => $mail_to,
        subject => sprintf('[%s] %s: %s %s', $data->{appinstance}, $data->{subject}, $data->{method}, $data->{uri}),
        body    => sprintf "App: %s\nRequest: %s %s\nIP: %s\nUser-Agent: %s\nTimestamp: %s\n\n%s",
            $data->{appinstance},
            $data->{method},
            $data->{uri},
            $data->{remote_address},
            $data->{user_agent},
            $data->{timestamp},
            $data->{body}
        });

    return $job->fail("send_mail() returned false") unless $success;
}




1;
