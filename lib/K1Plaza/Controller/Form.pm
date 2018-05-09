package K1Plaza::Controller::Form;
use Mojo::Base 'Mojolicious::Controller';
use Class::Load ();
use Data::Printer;
use Ref::Util qw/ is_blessed_ref /;

sub process {
    my ($c) = @_;
    my $log = $c->app->log;
    my $req = $c->req;

    # get form
    my $form_name = $c->stash->{form_name};
    my $form = $c->form( $form_name );
    return $c->reply->not_found unless $form;

    # process form
    $log->debug("processing form '$form_name'");

    # post data
    my $data = $req->json || $req->body_params->to_hash;
    $data->{$_->name} = $_ for @{$req->uploads};

    # bad csrf token
    unless ($data->{_csrf} && $data->{_csrf} eq $c->csrf_token) {
        $log->error("form '$form_name' has invalid csrf token");

        $c->res->code(403);
        return $c->render(json => { success => \0 });
    }

    $form->process( params => $data );

    # save form params in cache for redirects
    unless ($req->is_xhr) {
        my $fif = $form->fif;
        # p $fif;
        for (keys %$fif) {
            delete $fif->{$_} if is_blessed_ref $fif->{$_};
        };
        $c->flash( "form_${form_name}" => $fif );
        # my $cache_key = join(':', $c->app_instance->id, 'form', $form_name, $c->csrf_token);
        # my %form_data = %{$form->fif};
        # $c->app->cache->set($cache_key, \%form_data, '1m');
    }

    # reCaptcha
    if (my $field = $form->field('g-recaptcha-response')) {
        my $response = $field->value;
        my $secret = $form->{config}{recaptcha}{secret} or die "Missing 'recaptcha.secret' config on form '$form_name'.";
        my $res = $c->app->ua->post('https://www.google.com/recaptcha/api/siteverify' => form => { secret => $secret, response => $response })
                             ->result;

        # captcha failed?
        unless ($res->is_success && $res->json->{success}) {
            return $c->respond_to(
                json => { json => { success => \0 }},
                any => sub { $c->redirect_to($req->headers->referrer || '/') }
            );
        }
    }


    # invalid form
    unless ( $form->validated ) {

        $log->debug("form '$form_name' errors: ", $form->errors);

        return $c->respond_to(
            json => { json => {
                success => \0,
                errors  => [$form->errors],
                error_fields => { map { $_->name => ($_->errors)[0] } $form->error_fields }
            }},
            any => sub {
                $c->redirect_to($req->headers->referrer || '/')
            }
        );
    }

    # form is valid, do actions
    $c->do_form_actions($form);

    # success
    $c->respond_to(
        json => { json => { success => \1 }},
        any => sub {
            $c->redirect_to($req->headers->referrer || '/')
        }
    );
}

sub do_form_actions {
    my ($c, $form) = @_;
    my $log = $c->app->log;

    my $form_config = $c->get_form_config($form->name);

    # execute actions
    my $ctx = {
        app   => $c->app,
        tx    => $c,
        form  => $form,
        form_config => $form_config
    };

    # actions
    my @actions;

    $form->on_before_actions($ctx)
        if $form->can('on_before_actions');

    # convert legacy form into new actions hashref
    if (defined $form_config->{action} && ref $form_config->{action} eq 'HASH') {


        foreach my $action_name (keys %{$form_config->{action}}) {

            my $action_config = $form_config->{action}->{$action_name} || {};
            $action_config->{class} = $action_name;

            push @actions, $action_config;
        }
    }

    if (defined $form_config->{actions} && ref $form_config->{actions} eq 'ARRAY') {
        push @actions, @{$form_config->{actions}};
    }

    $log->warn(sprintf "Form '%s' has no actions!", $form->name)
        unless @actions;


    # run actions
    foreach my $action_args (@actions) {

        my $action_name = delete $action_args->{class};
        my $action_class = $c->_resolve_action_class($action_name);

        # instantiate and run
        $action_class->new($action_args)->process($ctx);
    }
}

sub _resolve_action_class {
    my ($c, $action_name) = @_;

    my $app_instance = $c->app_instance;
    my $app_class = ref $c->app;

    my @action_classes = map { $_ . '::' . $action_name } (
        $app_instance->is_managed ? () : sprintf('%s::AppInstance::%s::Form::Action', $app_class, $app_instance->name),
        $app_class."::Form::Action",
        'Q1::Web::Form::Action'
    );

    Class::Load::load_first_existing_class(@action_classes);
}





1;
