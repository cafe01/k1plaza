package K1Plaza::Controller::Form;
use Mojo::Base 'Mojolicious::Controller';
use Data::Printer;
use Ref::Util qw/ is_blessed_ref /;

sub process {
    my ($c) = @_;
    my $log = $c->app->log;
    my $req = $c->req;

    # get form
    my $form_name = $c->stash->{form_name};
    $log->debug("form name: $form_name");

    # js form
    my $js = $c->js;
    if ($js->_resolveModule("form/$form_name")) {
        return $c->_process_js($form_name);
    }

    # config-based legacy forms
    if (my $form = $c->get_form_config($form_name)) {
        local $js->modules->{"form/$form_name"} = $form;
        return $c->_process_js($form_name);
    }

    # form not found
    $c->log->warn("Form '$form_name' not found.");
    return $c->reply->not_found;
}

sub _process_js {
    my ($c, $form_name) = @_;
    my $log = $c->log;
    my $temp_dir = $c->app->home->child('file_storage/temp/');
    $temp_dir->make_path;

    # prepare params and uploads
    my $params = $c->req->json || $c->req->params->to_hash;
    for my $upload (@{$c->req->uploads}) {
        
        next unless $upload->size && $upload->filename;
        
        my $asset = $upload->asset->to_file->move_to($temp_dir->child("upload.".time.rand(999)));

        $params->{$upload->name} = {
            type => $upload->headers->content_type,
            size => $upload->size,
            filename => $upload->filename,
            path => $asset->path
        }
    }

    $log->info("Processando form '$form_name'. Parametros recebidos:");
    for my $key (keys %$params) {
        next if $key eq '_csrf';
        $log->info(sprintf "🡺 %s: %s", $key, $params->{$key} || '""');
    }

    # validate csrf token
    unless ($params->{_csrf} && $params->{_csrf} eq $c->csrf_token) {
        $c->res->code(403);        
        return $c->render(json => { success => \0, 'Invalid csrf token.' });
    }

    # run on javascript
    my $js = $c->js;
    local $js->modules->{params} = $params;

    my $result = $js->eval(qq(

        var params = require('params'),
            form = require('k1/form/loader').default.load("$form_name"),
            result;

        result = form.process(params)

        if (!result.success) {

            delete params['_csrf']
            require('k1/flash').set('form-$form_name', params)
        }
        else {
            
            delete result.fields["_csrf"]
            result.data = form.action(result.fields)
        }

        result;
    ));

    my $respond = sub {

        unless ($result->{success}) {

            $log->error("Form '$form_name' falhou:");
            for my $e (@{ $result->{errors} || []}) {
                $log->error("$e->{field}: '$e->{message}'");
            }
        }

        $c->respond_to(
            json => { json => $result->{success}
                ? { success => \1, data => $result->{data} }
                : { success => \0, errors => $result->{errors} }
            },
            any => sub {
                $c->flash("form-$form_name-success", $result->{success});
                $c->redirect_to($c->req->headers->referrer || '/')
            }
        );
    };

    # delayed (promise) response
    if (is_blessed_ref $result->{data} && $result->{data}->can('then')) {
        my $promise = delete $result->{data};
        $promise->then(sub {
            $result->{data} = shift;
            p $result;
            $respond->();
        })->catch($respond);

        $c->render_later;

    }
    else {
        $respond->();
    }

}


1;
