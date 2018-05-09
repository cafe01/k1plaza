package K1Plaza::Plugin::Forms;

use Mojo::Base 'Mojolicious::Plugin';
use Class::Load ();
use Data::Printer;
use Data::Dumper;

sub register {
    my ($self, $app) = @_;

    # routes
    $app->routes->post( '/.form/:form_name')->to("form#process");

    # helpers
    $app->helper(form => \&_get_form);
    $app->helper(get_form_config => \&_get_form_config);
    $app->helper(inject_form => \&_inject_form);
}

sub _get_form {
    my ($c, $name, $form_args) = @_;
    my $app = $c->app;
    my $log = $app->log;

    # sanity
    die "can't get_form() without an app instance!" unless $c->has_app_instance;

    $form_args ||= {};
    my $app_class = ref $app;
    my $app_instance = $c->app_instance;

    my $form_config = _get_form_config($c, $name);
    return unless $form_config;
    my $form;

    if ($form_config->{is_dynamic}) {

        # mangle fields
        my @fields;
        foreach my $field (@{ $form_config->{fields} }) {
            unless (defined $field->{name}) {
                die sprintf "[Form] form '%s':  missing 'name' config for a field.\nfield:%s\nform config: %s", $name, Dumper($field), Dumper($form_config);
            }
            $field->{type} //= 'Text';
            $field->{type} = ucfirst $field->{type};
            push @fields, $field->{name}, $field;
        }

        # _csrf field
        push @fields, '_csrf', { type => 'Hidden'};

        # instantiate
        Class::Load::load_class('HTML::FormHandler');
        $form = HTML::FormHandler->new(
            name       => $name,
            field_list => \@fields,
            messages   => $form_config->{messages}
        );
    }
    else {

        my @form_classes = map { $_ . '::' . $form_config->{class} } (
            $app_instance->is_managed ? () : sprintf('%s::AppInstance::%s::Form', $app_class, $c->app_instance->name),
            $app_class."::Form",
            'Q1::Web::Form'
        );

        # try to load the form class (dies if not found)
        my $form_class = Class::Load::load_first_existing_class(@form_classes);

        # instantiate
        $form = $form_class->new( %$form_args, name => $name );
        $log->debug("New '$name' form (class: $form_class)");
    }

    # csrf token
    die "Esse form nao possui o campo '_csrf'." unless $form->field('_csrf');
    $form->field('_csrf')->value($c->csrf_token);

    # set form action
    $form->action('/.form/'.$name);

    # process redirected posted forms
    if (my $data = $c->flash("form_${name}")) {
        $log->debug("[Form] ($name) found previously posted form.");
        $form->process( params => $data, posted => 1 );
    }

    # save config
    $form->{config} = $form_config;

    $form;
}


sub _get_form_config {
    my ($c, $name) = @_;
    my $app = $c->app;
    my $cache = $app->cache;

    return unless $name;

    # from store
    return $cache->get($c->app_instance->id.':form:'.$name)
       if $cache->is_valid($c->app_instance->id.':form:'.$name);

    # from config
    my $config = $c->app_instance->config->{form}->{$name};

    unless ($config) {
        $app->log->error("Can't find config for form '$name'.");
        return;
    }

    # no class and no fields to create a dynamic form
    die "Invalid config for form '$name': missing 'class' option!"
       if !$config->{class} && !$config->{fields};

    # dynamic form flag
    if (not exists $config->{class}) {

        die "Dynamic forms 'fields' config must be and ARRAY!"
            unless ref $config->{fields} eq 'ARRAY';

        $config->{is_dynamic} = 1;

        # default error messages
        $config->{messages} //= {
            required     => 'Campo obrigatório.',
            email_format => 'Digite o e-mail no formato nome@exemplo.com.br'
        };

        # recaptcha
        if ($config->{recaptcha}) {
            push @{$config->{fields}}, {
                widget => 'NoRender',
                required => 1,
                name => 'g-recaptcha-response'
            };
        }
    }

    $config;
}


sub _inject_form {
    my ($c, $form_name, $form_config, $duration) = @_;
    $duration ||= '2d';
    $c->app->cache->set($c->app_instance->id.':form:'.$form_name, $form_config, $duration);
}


1;
