package K1Plaza::Snippet::form;

use Moo;
use namespace::autoclean;
use Data::Dumper;
use Carp qw/confess/;
use Data::Printer;

has 'name', is => 'ro', required => 1;


sub profiler_action {
    'form: '.shift->name
}


sub process {
    my ($self, $element, $engine) = @_;


    # find js form
    my $js = $engine->javascript_context;
    if ($js && $js->_resolveModule('form/'.$self->name)) {
        return $self->_process_js($element, $engine);
    }

    # find config-based forms (legacy)
    my $c = $engine->context->{tx};
    if (my $form = $c->get_form_config($self->name)) {
        
        local $js->modules->{'form/'.$self->name} = $form;
        return $self->_process_js($element, $engine);
    }

    # native
    die "Form '$form_name' não existe.";
}

sub _process_js {
    my ($self, $element, $engine) = @_;

    my $js = $engine->javascript_context;
    my $c = $engine->context->{tx};
    my $token = $c->csrf_token;

    local $js->modules->{element} = $element;

    my $result = $js->eval(qq(
        var formLoader = require('k1/form/loader').default,
            element = require('element'),
            flash = require('k1/flash'),
            token = require('k1/csrf_token'),
            params = flash.get("form-${\ $self->name }"),
            form = formLoader.load("${\ $self->name }");

        if (!form) {
            console.error("<x-form> aborting.")
            0;
        }
        else {

            // set values
            if (params) {
                params["_csrf"] = token
                form.process(params)
            }
            else {
                form.getField("_csrf").setValue(token)
            }

            // render
            element.get(0).setNodeName('form')
            form.render(element)

            1;
        }

    ), 'x-form-eval');

    # exception
    return unless $result;

    # messages
    my $form_success = $c->flash("form-${\ $self->name }-success");
    
    my $parent = $element->parent;
    my $success_el = $parent->find('.form-'.$self->name.'-success');
    my $error_tpl = $parent->find('.form-'.$self->name.'-error');

    if (! defined $form_success) {
        $error_tpl->attr('style', ($error_tpl->attr('style') || '') . ';display:none;' );
        $success_el->attr('style', ($error_tpl->attr('style') || '') . ';display:none;' );
    }
    elsif ($form_success) {
        $element->remove if $success_el->size;
        $error_tpl->attr('style', ($error_tpl->attr('style') || '') . ';display:none;' );
    } else {
        $success_el->attr('style', ($error_tpl->attr('style') || '') . ';display:none;' );
    }
}


1;


__END__
