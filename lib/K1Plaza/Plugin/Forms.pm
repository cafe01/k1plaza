package K1Plaza::Plugin::Forms;

use Mojo::Base 'Mojolicious::Plugin';
use Data::Printer;
use Data::Dumper;

sub register {
    my ($self, $app) = @_;

    # routes
    $app->routes->post( '/.form/:form_name')->to("form#process");

    # helpers
    $app->helper(get_form_config => \&_get_form_config);
}


sub _get_form_config {
    my ($c, $name) = @_;
    return unless $c->has_app_instance;

    my $config = $c->app_instance->config->{form}->{$name}
        or return;

    my %form;
    
    # fields
    push @{$form{fields}}, map {

        my %field = %$_;
        $field{type} = lc $field{type};
        $field{type} = "file" if $field{type} eq 'upload';

        \%field;

    } @{$config->{fields}||[]};

    # recaptcha
    if ($config->{recaptcha}) {
        push @{$form{fields}}, { 
            type => "recaptcha", 
            key => $config->{recaptcha}->{key},
            secret => $config->{recaptcha}->{secret}
        }
    }

    # legacy SendEmail action
    if (my $action = $config->{action}{SendEmail}) {
        $form{action} = sub {
            my ($fields) = @_;
            my @attachments = grep { ref } values %$fields;

            # expand subject template
            while (my ($k, $v) = each %$fields) {
                $k = quotemeta($k);
                $action->{subject} =~ s/{\s*$k\s*}/$v/g;
            }

            $c->send_email({
                from       => $action->{from},
                to         => $action->{to},
                cc         => $action->{cc},
                bcc        => $action->{bcc},
                subject    => $action->{subject},
                $action->{email_template}      ? (template      => $action->{email_template})      : (),
                $action->{email_html_template} ? (html_template => $action->{email_html_template}) : (),
                template_data => {
                    form => { value => $fields },
                },
                attachments => \@attachments,
                $fields->{email} ? ('reply-to' => $fields->{email}) : ()
            });
        }
    }


    # return js form config
    return \%form
}



1;
