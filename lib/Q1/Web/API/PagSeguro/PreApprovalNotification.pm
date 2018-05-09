package Q1::Web::API::PagSeguro::PreApprovalNotification;

use Data::Dumper;
use Moo;
use namespace::autoclean;
use XML::LibXML;
use DateTime::Format::W3CDTF;


my $XML;
sub field($;%);

has 'xml_source', is => 'ro';

has 'xml',
    is => 'ro',
    lazy => 1,
    default => sub {
        my $self = shift;
        return unless $self->xml_source;

        if (!$XML) {
            $XML = XML::LibXML->new;
            $XML->recover(1);
            $XML->recover_silently(1);
            $XML->keep_blanks(0);
            $XML->expand_entities(1);
            $XML->no_network(1);
        }

        $XML->load_xml( string => $self->xml_source );
    };

has 'type', is => 'ro', default => 'preapproval';

field 'name';
field 'code';
field 'date', type => 'date';
field 'tracker';
field 'status';
field 'reference';
field 'lastEventDate', type => 'date';
field 'charge';

my %constants = (

);

sub field($;%) {
    my ($name, %params) = @_;
    my $w3c = DateTime::Format::W3CDTF->new;

    $params{type} //= 'string';

    # decamelize
    my $attr = lc join "_", grep { length } split /(\p{upper}\w+?)(?=\p{upper}|$)/, $name;

    # constnum
    if ($params{type} eq 'constnum') {
        my $code_attr = $attr.'_code';
        has $attr,
            is => 'ro',
            lazy => 1,
            default => sub {
                my $self = shift;
                $constants{$name}->{$self->$code_attr};
            };

        $attr = $code_attr;
    }

    has $attr,
        is => 'ro',
        lazy => 1,
        default => sub {
            my $self = shift;
            my $xml = $self->xml;
            my $rootnode = $xml->findnodes('/preApproval')->shift;

            return $params{code}->($rootnode) if ref $params{code} eq 'CODE';
            my $value = $rootnode->findnodes('./'.$name.'/text()')->shift->data;

            $value = $w3c->parse_datetime($value)
                if $params{type} eq 'date';

            $value += 0 if $params{type} eq 'num';

            $value;
        };
}


1;
