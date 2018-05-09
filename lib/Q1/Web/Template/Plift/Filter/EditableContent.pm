package Q1::Web::Template::Plift::Filter::EditableContent;

use Moo;
use namespace::autoclean;


sub process {
    my ($self, $doc, $engine) = @_;

    my $tx = $engine->context->{tx};
    my $body = $doc->find('body')->first;
    my $editable_elements = $doc->find('*[data-editable]');

    # inject ContentTools for admin session
    if ($editable_elements->size && $body->size && $tx->user_exists && $tx->user->check_roles('instance_admin')) {

        $engine->parse_html($_)->append_to($body) for (
            '<link href="/static/js/k1plaza-editor/content-tools/content-tools.min.css" rel="stylesheet"/>',
            '<script src="/static/js/k1plaza-editor/content-tools/content-tools.min.js"/>',
            '<script src="/static/js/k1plaza-editor/content-editor.js"/>'
        );

        # add unique data-region for each element
        my $rand = int rand 2**32;
        $editable_elements->each(sub {
            my ($i, $el) = @_;

            # skip
            if (defined $el->attr('data-plift-truncate')) {
                $el->remove_attr('data-editable');
            }
            else {
                $el->attr('data-region', $rand + $i);
            }
            1;
        });
    }
    else {
        $editable_elements->remove_attr('data-editable');
        $editable_elements->remove_attr('data-fixture');
        $editable_elements->remove_attr('data-ce-tag');
        return;
    }

}



1;
