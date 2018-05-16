package Q1::API::Media;

use Carp;
use Moose;
use namespace::autoclean;
use File::stat;
use Mojo::File 'path';
use MIME::Types;
use Image::Size qw/imgsize/;
use Data::Dumper;
use Data::UUID;
use Imager;
use File::Temp qw/ tempfile /;

extends 'DBIx::Class::API';

with 'DBIx::Class::API::Feature::DynaCols', 'DBIx::Class::API::Feature::Sencha';

BEGIN { MIME::Types->new() } # see http://search.cpan.org/~markov/MIME-Types-1.34/lib/MIME/Types.pod#MIME::Types_and_daemons_(fork)
my $MT = MIME::Types->new;

__PACKAGE__->config(
    dbic_class  => 'Media',
    flush_object_after_insert => 1,
    sortable_columns => ['mediacollection_medias.position', 'me.created_at', 'me.file_size', 'me.file_name']
);

has '+dynamic_column_name' => ( default => 'metadata' );

has '_storage_type' => ( is => 'ro', isa => 'Str', lazy => 1, default => 'fs' );
has 'fs_storage_path', is => 'ro', lazy => 1, default => sub {
    my $self = shift;
    $self->app->home->child($self->app->config->{media_storage_path} || 'file_storage/medias');
};

has 'tx', 'is' => 'ro', isa => 'Object';

# TODO: check leak on 'widget' attribute
has 'widget', is => 'rw', predicate => 'has_widget', clearer => '_clear_widget';

has 'max_image_width', is => 'rw', default => 2560;
has 'max_image_height', is => 'rw', default => 1440;



before 'list' => sub {
    my ($self, $params) = @_;
    return unless $params;
    my $tx = $self->tx;

    # widget
    if ($self->has_widget) {
        my $widget = $self->widget;

        # widget specific metadata
        $self->dynamic_columns($widget->media_metadata)
            if $widget->can('has_media_metadata') && $widget->has_media_metadata;

        # collection
        $params->{collection_id} ||= $widget->db_object->mediacollection_id;
    }

    # collection
    if ($params->{collection_id}) {
        $self->add_list_filter( 'mediacollection_medias.mediacollection_id' => $params->{collection_id} )
             ->order_by('mediacollection_medias.position');
    }

    # page
    $self->page($params->{page}, $params->{limit});
};


# add media url
before 'result' => sub {
    my $self = shift;
    my $tx = $self->tx;
    return unless $tx;

    $self->push_object_formatter(sub {
        my ($self, $media, $formatted) = @_;
        $formatted->{url} = $tx->uri_for_media($media).'';
        $formatted->{local_url} = $tx->uri_for_media($media, { local_url => 1 }).'';
    });
};


around '_prepare_create_object' => sub {
    my ($orig, $self, $object) = (shift, shift, shift);
    my $tx = $self->tx;

    # wrong usage
    die "To create a media, give me a 'file' or 'url'!"
        unless ($object->{file} || $object->{url});

    die "To create a media, give me a 'file' or 'url', not both!"
        if ($object->{file} && $object->{url});


    # from file
    $self->_prepare_create_from_file($object)
        if $object->{file};

    # from url
    $self->_prepare_create_from_url($object)
        if $object->{url};

    $self->_prepare_widget($object);
    $self->_prepare_collection($object);

    $self->$orig($object);
};


after 'create' => sub {
    my $self = shift;

    my $storage = $self->app->config->{media_storage_type} || $self->_storage_type;
    return if $self->has_errors || $storage ne 'amazons3';

    my $log = $self->app->log;

    # send to amazons3
    foreach my $media (map { $_->{object} } $self->all_objects) {
        next unless $media->file;
        my $id = $self->app->minion->enqueue(upload_s3_media => [$media->id]);
        $log->debug("Enqued upload_s3_media task $id");
    }

};


around '_prepare_update_object' => sub {
    my ($orig, $self, $object) = (shift, shift, shift);

    $self->_prepare_widget($object);

    $self->$orig($object);
};

sub mime_type_of {
    my ($self, $filename) = @_;
    $MT->mimeTypeOf($filename);
}



sub _prepare_widget {
    my ($self, $object) = @_;
    my $tx = $self->tx;

    if ($self->has_widget) {
        my $widget = $self->widget;

        # widget specific metadata
        $self->dynamic_columns($widget->media_metadata)
            if $widget->can('has_media_metadata') && $widget->has_media_metadata;

        # collection
        $object->{collection_id} ||= $widget->db_object->mediacollection_id;
    }
}

sub _prepare_collection {
    my ($self, $object) = @_;

    # inflate collection
    if (my $cid = delete $object->{collection_id}) {
        my $collection = $self->tx->api('MediaCollection')->find($cid)->first;

        $object->{mediacollections} = [$collection]
            if $collection;
    }
}

sub _prepare_create_from_url {
    my ($self, $object) = @_;
    my $url = delete $object->{url};
    my $info = $self->_web_media_info->from_url($url);

    die sprintf "Cant fetch info from online media using url '%s': %s", $url, $info->{error}
        unless $info->{success};

    $object->{is_external} = 1;
    $object->{external_id} = $info->{id};
    $object->{external_provider} = $info->{provider};

    map { $object->{$_} = $info->{$_} if exists $info->{$_}; } qw/ is_video is_audio thumbnail_small thumbnail_large waveform_url duration /;
}

sub _prepare_create_from_file {
	my ($self, $object) = @_;
    my $app = $self->app;

	#warn Dumper($object);
	$object->{file} = ref $object->{file} ? $object->{file} : path($object->{file});

	# find mime type
	my $mime_type = $object->{file_mime_type} || $self->mime_type_of($object->{file_name} || $object->{file}->basename)
        or die "Can't find mime type of file $object->{file}: $!";

	# TODO: approve mime type/subtype

    if ($mime_type =~ /image/) {
        my ($image_type) = $mime_type =~ /image\/(.*)/;

        $object->{is_image} = 1;
        @$object{qw/ width height /} = imgsize("$object->{file}");

        my $img = Imager->new;
        my $file_path = "$object->{file}";
        $img->read( file => $file_path, type => $image_type, png_ignore_benign_errors => 1)
            or die sprintf "Cannot load image file %s: %s", $file_path, $img->errstr;

        # fix orientation
        $img = _fix_image_orientation($img);

        # apply max image size
        if ($object->{width} > $self->max_image_width || $object->{height} > $self->max_image_height) {

            my $scaled = $img->scale( xpixels => $self->max_image_width, ypixels => $self->max_image_height, type => 'min' );

            (undef, my $tempfile) = tempfile('q1-autoscale-XXXXXXXX', OPEN => 0, DIR => '/tmp');
            
            $scaled->write( file => $tempfile, type => $image_type )
                or die sprintf "Cannot save scaled image file %s: %s", $tempfile, $scaled->errstr;

            unlink $object->{file};
            $object->{file} = path($tempfile);
            $object->{width} = $scaled->getwidth;
            $object->{height} = $scaled->getheight;
            # die Dumper $object;
        }
    }

    # fill columns
	my $st = stat($object->{file}) or confess "Error on stat() file: $!";

    $object->{has_file}       = 1;
    $object->{file_name}    ||= $object->{file}->basename;
    $object->{file_size}      = $st->size;
    $object->{file_mime_type} = $mime_type;

    if ($mime_type =~ /audio/) {
        $object->{is_audio} = 1;
        die "Audio information extraction not implemented!";
    }

    if ($mime_type =~ /video/) {
        $object->{is_video} = 1;
        die "Video information extraction not implemented!";
    }
}


sub _fix_image_orientation {
    my ($img) = @_;

    my $orientation_index = $img->tags(name => 'exif_orientation');
    return $img unless $orientation_index;

    my @operations = (
        [0, undef],
        [0, 'h'],
        [180, undef],
        [0, 'v'],
        [90, 'h'],
        [90, undef],
        [-90, 'h'],
        [-90, undef]
    );

    my ($degrees, $flip) = @{$operations[$orientation_index-1]};

    if ($degrees) {
        $img = $img->rotate(degrees => $degrees)
            or die "Error rotating image: ".$img->errstr;;
    }

    if ($flip) {
        $img->flip(dir => $flip) or die "Error flipping image: ".$img->errstr;
    }

    $img;
}


sub find_by_uuid {
    my ($self, $uuid) = @_;

    # validate uuid
    return unless ($uuid && $uuid =~ /^[a-f0-9]{32}$/);

    $self->find({ uuid => $uuid }, { key => 'medias_uuid' })->first;
}


sub reposition {
    my ($self, @args) = @_;

    $self->resultset->result_source->schema->txn_do(
        sub{ $self->_reposition(@args) }
    );

    $self;
}

sub _reposition {
    my ($self, $collection, $src_media, $dst_media) = @_;

    my $clone_api      = $self->clone->reset;
    my $collection_api = $self->tx->api('MediaCollection');

    unless ($collection && $src_media && $dst_media) {
        $self->push_error('Missing arguments!');
        return $self;
    }

    $collection    = $collection_api->find($collection)->first   unless ref $collection;
    $src_media = $clone_api->find($src_media)->first unless ref $src_media;
    $dst_media = $clone_api->find($dst_media)->first unless ref $dst_media;

    unless ($collection && $src_media && $dst_media) {
        $self->push_error('Invalid arguments!');
        return $self;
    }

    my $src_link     = $src_media->find_related('mediacollection_medias', { mediacollection => $collection });
    my $dst_link     = $dst_media->find_related('mediacollection_medias', { mediacollection => $collection });
    my $link_rs      = $src_link->result_source->resultset;

    my $src_position = $src_link->position;
    my $dst_position = $dst_link->position;
    my $moving_up    = $src_position > $dst_position ? 1 : 0;

    if ($moving_up) {

        $link_rs->search({ 'me.position' => { '>=' => $dst_position, '<' => $src_position }, 'me.mediacollection_id' => $collection->id })
                ->update({ position => \'position + 1' });

        $src_link->update({ position => $dst_position });

    } else {

        $link_rs->search({ 'me.position' => { '<=' => $dst_position, '>' => $src_position }, 'me.mediacollection_id' => $collection->id })
                ->update({ position => \'position - 1' });

        $src_link->update({ position => $dst_position });

    }
}



# bump widget version
after [qw/ create update delete reposition /] => sub {
    my $self = shift;

    $self->widget->db_object->bump_version
        if $self->has_widget && !$self->has_errors;
};

1;


__END__

=pod

=head1 NAME

Q1::API::Media

=head1 DESCRIPTION

=cut
