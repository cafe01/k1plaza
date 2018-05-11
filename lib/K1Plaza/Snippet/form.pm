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

    # native
    $self->_process_native($element, $engine);
}

sub _process_js {
    my ($self, $element, $engine) = @_;

    my $js = $engine->javascript_context;
    my $tx = $engine->context->{tx};
    my $token = $tx->csrf_token;

    my $saved = $tx->flash("form-${\ $self->name }");

    local $js->modules->{element} = $element;

    $js->eval(qq(
        var formLoader = require('k1/form/loader'),
            element = require('element'),
            flash = require('k1/flash'),
            token = require('k1/csrf_token'),
            params = flash.get("form-${\ $self->name }") || {},
            form = formLoader.load("${\ $self->name }");

        if (!form) {
            console.error("<x-form> aborting.")
            return
        }

        // process params
        params["_csrf"] = token
        form.process(params)

        // render
        element.get(0).setNodeName('form')
        form.render(element)
        1;
    ));
}


sub _process_native {
    my ($self, $element, $engine) = @_;
    # confess 'okay';
    my $tx = $engine->context->{tx};
    my $document = $element->document;
    my $form = $tx->form($self->name);

    # invalid form
    unless ($form) {
        $element->html('Form desconhecido: '.$self->name);
        return;
    }

    my $is_static_form = $element->children->size > 0;

    if ($is_static_form) {
        $element->append($form->field('_csrf')->render);
    }
    else {
        foreach my $field ($form->fields) {
            next unless $field->is_active;
            my $html = $field->render or next;
            $element->append($html);
        }
    }

    # reCaptcha widget
    if ($form->field('g-recaptcha-response')) {
        my $recaptcha_el = $element->find('.g-recaptcha');
        $recaptcha_el = $element->new('<div class="g-recaptcha" />')->append_to($element) unless $recaptcha_el->size;
        $recaptcha_el->attr('data-sitekey', $form->{config}{recaptcha}{key} || 'missing-key');
    }

    $element->attr(method => 'post');
    $element->attr(action => $form->action);

    # enctype
    if ($form->enctype) {
        $element->attr( enctype => $form->enctype);
    }
    else {
        # detect file upload
        foreach my $field ($form->fields) {
            next unless $field->is_active;
            if ($field->type eq 'Upload') {
                $element->attr( enctype => 'multipart/form-data');
                last;
            }
        }
    }

    # x-tag
    $element->get(0)->setNodeName('form')
        if $element->tagname =~ /^x-/;

    # messages
    # TODO show developer warning if no success element found
    my $parent = $element->parent;
    my $success_el = $parent->find('.form-'.$self->name.'-success');
    my $error_tpl = $parent->find('.form-'.$self->name.'-error');

#    # replace name by id
#    my $replace_id_func = sub {
#        my $class = $_->attr('class');
#        $class =~ s/form-$form_name/form-$form_id/g;
#        $_->attr('class', $class);
#    };
#
#    $_->each($replace_id_func)
#        for ($success_el, $error_tpl);

    # success
    # TODO use ran_validation() method to check if the form was even processed
    if ($form->is_valid) {

        # TODO make this removal optional
        $element->remove;

        # hide error msg
        $error_tpl->attr('style', ($error_tpl->attr('style') || '') . ';display:none;' );

    }
    else {
        # hide success msg
        $success_el->attr('style', ($success_el->attr('style') || '') . ';display:none;' );

        # render errors
        $self->_render_error_list($error_tpl, $form);
        $self->_render_field_errors($element, $form)
            if $is_static_form;

        # fif
        $self->_render_field_values($element, $form)
            if $is_static_form;
    }
}



sub _render_error_list {
    my ($self, $error_tpl, $form) = @_;
    return unless $error_tpl->size;

    foreach my $error ($form->errors) {
        my $item = $error_tpl->clone;
        $item->text($error);
        $item->insert_before($error_tpl);
    }

    $error_tpl->remove;
}


sub _render_field_errors {
    my ($self, $form_el, $form) = @_;

    foreach my $field ($form->error_fields) {

        my $field_el = $form_el->find("[name=".$field->name."]");
        next unless $field_el->size;

        $field_el->after('<span class="error_message">'.$_.'</span>')
            for $field->all_errors;

        $field_el->attr( autofocus => 1 );
        $field_el->add_class('error');

        my $parent = $field_el->parent;
        $parent->add_class('error')
            unless $parent->tagname eq 'form';
    }
}


sub _render_field_values {
    my ($self, $form_el, $form) = @_;
    my $fif = $form->fif;

    foreach my $field (keys %$fif) {

        my $field_el = $form_el->find("[name=".$field."]");
        next unless $field_el->size;

        if ( $field_el->tagname() eq 'textarea' ) {
            $field_el->text($fif->{$field})
        }
        else {
            $field_el->attr( value => $fif->{$field})
        }
    }
}



1;


__END__
