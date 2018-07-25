package Q1::Web::Widget::Expo;

use utf8;
use Q1::Moose::Widget;
use namespace::autoclean;
use Data::Dumper;
use Carp qw/ confess /;
use Q1::Utils::ConfigLoader;
use Q1::Util qw/ shuffle /;
use List::Util qw/ min max /;
use DateTime;
use DateTime::Format::Strptime;
use Data::Printer;

extends 'Q1::Web::Widget';

# parent
has '+template', default => 'widget/expo.html';
has '+backend_view', default => 'expoEditor';


# config
has_config 'media_metadata', isa => 'HashRef', builder => '_build_media_metadata';
has_config 'order_by',       isa => 'Str', default => 'position-asc';
has_config 'page_path',      isa => 'Str', default => '';

has_config 'flatten', isa => 'Bool', default => 0, is_parameter => 1;
has_config 'shuffle', isa => 'Bool', default => 0, is_parameter => 1;
has_config 'media_order_by', isa => 'Str', default => 'position', is_parameter => 1;
has_config 'shuffle_medias', isa => 'Bool', default => 0, is_parameter => 1;

has_config 'enable_tags', isa => 'Bool', default => 0;

has_config 'noarguments', lazy => 1, default => sub {
    my $self = shift;
    ($self->tx->stash->{widget_args} || '') ne $self->name;
};

# args
has_argument 'permalink', lazy => 1, default => sub {
    my $self = shift;
    $self->noarguments ? undef : $self->tx->stash->{permalink};
};

has_argument 'tag', lazy => 1, default => sub {
    my $self = shift;
    $self->noarguments ? undef : $self->tx->stash->{tag};
};

# params
has_param 'locale', lazy => 1, default => sub {
    my $self = shift;
    my $tx = $self->tx;
    return unless $tx->app_instance->config->{locales};
    $tx->req->is_xhr
        ? $tx->param('locale') || $tx->locale
        : $tx->locale;

};

for my $attr (qw/ start limit media_start media_limit columns include_unpublished /) {
    has_param $attr, lazy => 1, default => sub {
        my $self = shift;
        $self->noarguments ? undef : $self->tx->param($attr);
    };
}




sub _build_media_metadata {
    my ($self) = @_;

    return {
        title => {
            data_type => 'string',
            renderer  => { fieldLabel => 'Título' },
        },
        description => {
            data_type => 'text',
            renderer  => { fieldLabel => 'Descrição' },
        }
    };
}

sub routes {
    [
        ['/:permalink', [permalink => qr/[a-z0-9_-]+/]]
    ]
}

sub load_fixtures {
    my ($self) = @_;
    my $app = $self->app;
    my $tx = $self->tx;
    my $api = $self->tx->api('Expo');
    my $loader = Q1::Utils::ConfigLoader->new;

    # fixtures
    my $fixture_file;

    foreach my $file ($tx->app_instance->path_to('fixtures', 'widget', $self->name, 'fixture.yml'), $app->path_to('share/fixtures/widget/expo/fixture.yml') ) {
        if (-e $file) {
            $fixture_file = $file;
            last;
        }
    }

    unless ($fixture_file && -f $fixture_file) {
        $app->log->debug("no fixture found for expo widget.");
        return;
    }

    # load fixtures
    $app->log->debug("Creating fixtures for expo: ${\ $self->name }");
    my $items = $loader->loadConfigFile("$fixture_file") || [];

    # create
    my $locale = $tx->app_instance->config->{default_locale};
    foreach my $item (@$items) {
        $item->{is_published} //= 1;
        $item->{locale} = $locale;
    }
    $api->widget($self)->create($items);

    die "Error while creating Expo fixtures: ".( join ', ', @{$api->all_errors})
        if $api->has_errors;

    # add expo media fixtures
    my $media_api = $tx->api('Media');

    foreach my $item ($api->all_objects) {
        my $expo = $item->{object};
        my $fixture_dir = $fixture_file->sibling($expo->permalink);
        next unless -d $fixture_dir;

        $self->media_metadata; # force build
        my $metadata_file = $fixture_dir->child('metadata.conf');
        my $metadata      = -f $metadata_file ? $loader->loadConfigFile($metadata_file) : {};


        $app->log->debug("Creating album ${\ $expo->title }:");
        my @medias;

        foreach my $file ($fixture_dir->list->each) {
            next if $file->basename eq 'metadata.conf';
            $app->log->debug(" - ".$file->basename);
            my $media_cols = $metadata->{$file->basename} || $metadata->{'default'} || {};
            push @medias, $media_api->create({ %$media_cols, file => $file })->first->{object};
        }

        $expo->mediacollection->set_medias(@medias)
            if @medias;
    }
}


sub get_data {
    my ($self, $tx)   = @_;

    # list
    my %params = map { $_ => $self->$_ } qw/ start limit permalink tag include_unpublished locale /;
    my $data = $tx->api('Expo', { widget => $self })->list(\%params)->result;
    die "missing 'is_permalink_result' on expo" if $self->permalink && !$data->{is_permalink_result};

    # flatten
    if ($self->flatten) {

        my @medias;
        foreach my $expo (@{$data->{items}}) {
            foreach my $media (@{ delete $expo->{medias}}) {   # TODO should we really delete medias?
                $media->{album} = $expo;
                push @medias, $media;
            }
        }

        # shuffle
        shuffle(\@medias) if $self->shuffle_medias;

        # media order
        if ($self->media_order_by eq 'latest') {
            my $parser = DateTime::Format::Strptime->new( pattern   => '%F %T', time_zone => 'UTC' );

            @medias =  reverse sort {
                DateTime->compare_ignore_floating($parser->parse_datetime($a->{created_at}), $parser->parse_datetime($b->{created_at}))
            } @medias;

        }

        $data->{medias} = \@medias;
    }

    # shuffle albumns
    shuffle($data->{items}) if $self->shuffle;

    $data;
}

sub before_render_page {
    my ($self, $tx) = @_;
    my $data = $self->data;

    # not found
    if ($data->{is_permalink_result} && $data->{total} == 0) {
        $tx->reply->not_found;
        return;
    }

    if ($data->{is_permalink_result}) {

        # add breadcrumb
        push @{$tx->stash->{breadcrumbs}}, { title => $tx->stash->{title}, url => $tx->uri_for_page };

        # change page title
        my $expo = $data->{items}[0];
        $tx->stash->{title} = $expo->{title};

        # opengraph
        my $og = ($tx->stash->{opengraph} //= {});

        $og->{url}   = $expo->{url};
        $og->{image} = $tx->uri_for_media($expo->{cover}, { scale => '250x250', crop => 1 }).''
            if $expo->{cover};

        $og->{description} = defined $expo->{description} ? $expo->{description} : '';

        # single post template
        $tx->stash->{template} .= '.single'
            if $tx->find_template_file($tx->stash->{template}.'.single');
    }
}

sub render_snippet {
    my ($self, $element, $data, $plift) = @_;
    confess "missing plift ref" unless $plift;
    $plift->run_snippet('expo', $element, { widget => $self });
}








1;





__END__

=pod

=head1 NAME

Q1Plaza::Widget::Expo

=head1 DESCRIPTION

The Expo widget.

=head1 METHODS

=head2 initialize

=head2 process

=head2 add_to_medias($expo, @medias)

=cut
