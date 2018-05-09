package Q1::Web::Template::Plift::jQuery;

use strict;
use warnings;
use parent qw/ Q1::jQuery Exporter/;

use DateTime::Format::Strptime;
use Scalar::Util qw/ blessed /;

our @EXPORT = qw/ j /;



sub j {
    __PACKAGE__->new(@_);
}



sub datetime {
    my ($self, $value, $pattern, %options) = @_;
    return unless $value;

    my $formatter = DateTime::Format::Strptime->new(
        locale    => 'pt_BR',
        pattern   => '%F %T', # 2012-07-24 14:40:09
        time_zone => 'UTC',
    );

    $value = $formatter->parse_datetime($value)
        unless blessed $value;

    $self->each(sub{
        $formatter->pattern($pattern || $_->attr('data-format-date') || '%d/%m/%Y %H:%M:%S');
        $_->text($formatter->format_datetime($value));
    });

    return $self;
}

=head2 render_data(\%schema, \%data, [\%opts])

Renders data based on given schema using the current set of elements as template.

Schema is a hashref where each item represents one item in the data hashref, and how to render it.

The key is the name of the data item, and the value is the item schema.

The item schema is a hashref with the following keys:

    - selector: css selector to bind the data to
    - xpath: bind using xpath
    - data_key: (Defaults to entity name) the key in the data hash to get the data
    - at: (default: text) string representing where in the element the data should go: text, html or @attr. separate with comma or spaces
    - format_number: a number format
    - format_date: a date format
    - default: a default value


Example:

    {
        title: '.title',
        description: { selector: '.description', data_key: 'description', at: 'text @title' },
        url: { selector: '.link', at: '@href'},
        created_at: { selector: '.date', format_date: '%F %T' }
    }

=cut

use Data::Dumper;

sub render_data {
    my ($self, $schema, $data, $opts) = @_;

    # array
    if (ref $data eq 'ARRAY') {

        foreach my $subdata (@$data) {
            my $tpl = $self->clone;
            $tpl->render_data($schema, $subdata);
            $tpl->insert_before($self);
        }

        $self->remove;
        return $self;
    }

    my $reftype = ref $data;
    die "render_data(): can't render this type of data: $reftype" unless $reftype eq 'HASH';

    foreach my $item_name (keys %$schema) {

        # item schema
        my $item;
        if (ref $schema->{$item_name} eq 'HASH') {

            $item = $schema->{$item_name};

            # selector => at
            if (scalar(keys %$item) == 1) {
                my ($selector, $at) = %$item;
                $item = { selector => $selector, at => $at };
            }
        }
        else {
            $item = { selector => $schema->{$item_name} };
        }

        $item->{name} = $item_name;
        $item->{data_key} //= $item_name;
        $item->{at} //= 'text';

        # no data
        next unless exists $data->{$item->{data_key}};

#        warn Dumper $item;
        # 'current node' selector
        $item->{xpath} = delete $item->{selector}
            if $item->{selector} && $item->{selector} eq '.';

        # no selector
        die "missing 'selector' or 'xpath' on item $item_name" unless defined $item->{selector} || defined $item->{xpath};

        # render
        my $target = $item->{selector} ? $self->find($item->{selector}) : $self->xfind($item->{xpath});
        next unless $target->size; # TODO seems optimal, but needs benchmark without this line

        # value
        $item->{default} //= '';
        my $value = defined $data->{$item->{data_key}} ? $data->{$item->{data_key}} : $item->{default};
        # had to create $value instead of $data->{$item->{data_key}} //= $item->{default};
        # see bug: https://rt.cpan.org/Public/Bug/Display.html?id=86731

        # TODO skip if $value is undefined? or set it to '' ?
        if ($target->size > 1) {
            $target->each(sub{
                _render_item($item, $_, $value, $data);
            });
            next;
        }

        _render_item($item, $target, $value, $data);
    }

    $self;
}

sub _render_item {
    my ($schema, $target, $value, $data) = @_;

    # callback from at
    $schema->{callback} = $schema->{at}
        if !exists $schema->{callback} && ref $schema->{at} eq 'CODE';

    # ref
    # TODO move this to render_data() ?
    my $reftype = ref $value;
    if (($reftype eq 'HASH' || $reftype eq 'ARRAY') && !blessed($value) && !$schema->{callback}) {

        die sprintf("missing schema/callback for item $schema->{name}:\nitem: %s\n\ndata:\n%s", Dumper($schema), Dumper($value) )
            unless $schema->{schema};

        return $target->render_data($schema->{schema}, $value);
    }

    # callback
    if ($schema->{callback}) {
        die sprintf "callback must be a CODE ref! (not %s)", ref $schema->{callback}
            unless ref $schema->{callback} eq 'CODE';

        $schema->{callback}->($target, $value, $data);
        return;
    }

    # data-plift-render-at
    if (my $at = $target->attr('data-plift-render-at')) {

        $schema->{at} = $at;
        $target->remove_attr('data-plift-render-at');
    }

    # data-format-date
    if (my $format = $target->attr('data-format-date')) {
        $schema->{format_date} = $format;
        $target->remove_attr('data-format-date');
    }

    # format_date
    if ($schema->{format_date} && blessed $value && $value->can('strftime')) {
        # TODO get locale from plift engine somehow
        $value->set_locale('pt_BR');
        $value = $value->strftime($schema->{format_date});
    }

    # value
    foreach my $at (split /(?:,\s*| +)/, $schema->{at}) {
        if ($at eq 'text') { $target->text($value) }
        elsif ($at eq 'html') { $target->html($value) }
        elsif ($at =~ /^\@/) { $target->attr(substr($at, 1), $value) }
    }
}
























1;
