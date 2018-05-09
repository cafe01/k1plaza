package K1Plaza::API::Agenda;

use Moose;
use namespace::autoclean;

extends 'Q1::Web::Widget::API::Agenda';
with 'Q1::API::AppInstance::TraitFor::API::BelongsToAppInstance';


has '+use_json_boolean', default => 1;

1;

