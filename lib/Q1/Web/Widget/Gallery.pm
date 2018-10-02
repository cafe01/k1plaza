package Q1::Web::Widget::Gallery;

use Moose;
use namespace::autoclean;
use Scalar::Util qw(blessed);
use Data::Dumper;
use Carp;
use utf8;
use Q1::Utils::ConfigLoader;
use Q1::Moose::Widget;
use Q1::Web::Template::Plift::Util qw/ render_content /;
use Mojo::File qw/ tempfile /;
use Try::Tiny;

extends 'Q1::Web::Widget';
#with 'Q1::Role::Widget::RenderSnippet';

# parent attributes
has '+template'     => ( default => 'widget/gallery' );
has '+backend_view' => ( default => 'mediaGallery' );
has '+view'         => ( default => 'nivoSlider' );


# config
has_config 'width',          isa => 'Int';
has_config 'height',         isa => 'Int';

has_config 'media_metadata',
    isa => 'HashRef',
    default => sub {
    +{
        title => {
            data_type => 'string',
            renderer  => { fieldLabel => 'Título' },
        },
        'link' => {
            data_type => 'string',
            renderer  => { fieldLabel => 'Link (url)' },
        },
        description => {
            data_type => 'text',
            renderer  => { fieldLabel => 'Descrição' },
        }
    };
};

has_config 'fixtures', isa => 'Str';

has_param 'start', isa => 'Int', default => 0;
has_param 'limit', isa => 'Int';
has_param 'columns', isa => 'Int', default => 0;



sub initialize {
    my ($self) = @_;
    my $db_obj = $self->db_object;

    # create media collection
    $db_obj->mediacollection( $db_obj->create_related('mediacollection', { app_instance_id => $db_obj->app_instance_id }) );

    $self->db_object->update({ is_initialized => 1 });
}


use Data::Printer;
sub load_fixtures {
    my ($self, $tx) = @_;
    my $log = $tx->log;
    $log->info(sprintf "Adding '%s' to gallery '%s'...", $self->fixtures, $self->name);

    my ($limit, $query) = $self->fixtures =~ /^\s*(\d*)\s*(.*)/;
    $limit //= 5;

    my $data = $tx->api('Unsplash')->get('search/photos', { per_page => $limit, query => $query });

    if ($data->{total} == 0)  {
        return $log->warn("Unsplash query for '${\ $self->fixtures }' found 0 photos.");
    }

    my $medias = $tx->api("Media");
    $medias->dynamic_columns($self->media_metadata)
        if $self->has_media_metadata;

    my $ua = $tx->app->ua;
    foreach my $item (@{$data->{results}}) {

        my $url = $item->{urls}{regular};
        $log->info("Downloading photo $item->{id}");

        $ua->get_p($url)->then(sub {
            my $res = shift->result;

            $res->is_success or return $log->error("Error downloading '$url'");
            $log->info("$item->{id} download completed.");

            # save file
            try {
                my $file = tempfile(DIR => '/tmp');
                $file->spurt($res->body);
                my $media = $medias->create({
                    file => $file,
                    file_mime_type => $res->headers->content_type,
                    description => $item->{description} || ''
                })->first->{object};
                $self->db_object->mediacollection->add_to_medias($media);
            }
            catch {
                $log->error("Error creating gallery fixture.", @_);
            };
        });
    }
}



sub get_data {
    my ($self, $tx) = @_;
    my $collection = $self->db_object->mediacollection;

    my $rs = $tx->api('Media')->where('mediacollection_medias.mediacollection_id' => $collection->id)
                              ->order_by('mediacollection_medias.position');

    my $result = $rs->list->result;

    # fixtures
    if ($result->{total} == 0 && $self->fixtures && $self->app->mode eq 'development') {
        $self->load_fixtures($tx);
    }

    return {
        success => \1,
        medias => $result->{items}
    };
}


sub render_snippet {
    my ($self, $element, $data, $plift) = @_;

    $plift->run_snippet('gallery', $element, {
        widget => $self,
        map { $_ => $self->$_ } qw/ name template start limit /
    });
}


sub add_media {
    my ($self, $media) = @_;
    my $api = $self->tx->api('Media');

    my $db_media;

    # metadata
    $api->dynamic_columns($self->media_metadata)
        if $self->has_media_metadata;

    if (ref $media eq 'HASH') {
        $api->create($media);
        return if $api->has_errors;
        $db_media = $api->first->{object};
    }
    elsif (blessed $media && $media->isa('Q1::API::Media::Schema::Result::Media')) {
        $db_media = $media;
    }
    else {
        die sprintf "Cant add media to gallery: I can only handle Hashref or a Q1::API::Media::Schema::Result::Media instance. You gave me '%s'", ref $media;
    }

    #warn "New media: ".Dumper($db_media);
    # add to collection
    $self->db_object->mediacollection->add_to_medias($db_media);

    return $db_media;
}





1;

__END__

=pod

=head1 NAME

Q1Plaza::Widget::Gallery

=head1 DESCRIPTION

The Gallery widget.

=head1 METHODS

=head2 initialize

=head2 process

=head2 add_media

=cut
