package Q1::API::Data;

use Moose;
use namespace::autoclean;
use utf8;
use Carp qw/ carp /;
use JSON::XS qw/ encode_json decode_json /;
use Scalar::Util qw/ blessed /;
use DateTime::Format::W3CDTF;

use feature qw(signatures);
no warnings qw(experimental::signatures);

extends 'DBIx::Class::API';
with 'Q1::API::AppInstance::TraitFor::API::BelongsToAppInstance';


has '+dbic_class', default => 'Data';
has 'tx', is => 'ro';


my $w3c = DateTime::Format::W3CDTF->new;


# auto reset
after [qw/ set get get_namespace delete delete_namespace /] => sub {
    shift->reset;
};

sub set($self, $key, $value) {
    my $is_serialized = 0;

    die sprintf "[%s] can't set an empty key, smartass!"
        unless defined $key && length $key;

    # normalize key
    $key = substr $key, 0, length($key) - 1
        if $key =~ /\.$/;

    if (ref $value) {

        my $envelope = {
            data => $value
        };

        # datetime
        if (blessed $value && $value->isa('DateTime')) {
            $envelope->{is_datetime} = 1;
            $envelope->{data} = $w3c->format_datetime($value);
        }

        # serialize
        $value = encode_json $envelope;
        $is_serialized = 1;
    }

    $self->create_or_update({
        name => $key,
        value => $value,
        is_serialized => $is_serialized
    })->result->{success};
}


sub _inflate_object {
    my $object = shift;

    return $object->value unless $object->is_serialized;

    # unserialize
    my $envelope = JSON::XS->new->utf8(0)->decode($object->value);

    # datetime
    return $w3c->parse_datetime($envelope->{data})
        if $envelope->{is_datetime};

    $envelope->{data};
}


sub get($self, $key) {
    my $object = $self->find({ name => $key })->first;
    return unless $object;
    _inflate_object($object);
}


sub get_namespace($self, $namespace) {

    # normalize namespace
    $namespace //= '.';
    $namespace = $namespace . '.' unless $namespace =~ /\.$/;

    $self->where( name => { like => $namespace.'%' })
        unless $namespace eq '.';

    my @objects = map {
        +{
            name  => $namespace eq '.' ? $_->name : substr($_->name, length($namespace)),
            value => _inflate_object($_)
        }
    } $self->list->all_objects;

    # expand data structure
    my $data = {};
    foreach my $obj (@objects) {

        my @namespace = split /\./, $obj->{name};
        my $key = pop @namespace;
        my $target = $data;

        # dive into data structure
        foreach my $name (@namespace) {
            $target->{$name} //= {};
            $target = $target->{$name};
        }

        $target->{$key} = $obj->{value};
    }

    $data;
}

around 'delete' => sub {
    my ($orig, $self, $objects) = @_;
    $self->$orig(ref $objects ? $objects : { name => $objects });
};


sub delete_namespace($self, $namespace) {

    $namespace //= '.';
    $namespace = $namespace . '.' unless $namespace =~ /\.$/;

    die "You can't delete the '.' namespace. Use delete_all if you really what it."
        if $namespace eq '.';

    $self->restrict_by_app_instance
         ->modify_resultset({ name => { like => $namespace.'%' }})
         ->resultset
         ->delete;
}


sub update($self, $data) {
    $self->set($data->{name}, $data->{value});
}





1;
