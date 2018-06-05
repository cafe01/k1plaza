on 'test' => sub {
    requires 'Test2::Suite';
};

# Mojolicious Basic
requires 'EV' => 4.22;
requires 'IO::Socket::Socks' => 0.74;
requires 'IO::Socket::SSL' => 2.056;
requires 'Net::DNS::Native' => 0.18;
requires 'Mojolicious' => '== 7.82';

# Mojolicous Plugins
requires 'Mojolicious::Plugin::CHI';
requires 'Minion' => 8.11;
requires 'Minion::Backend::mysql' => 0.13;
requires 'Mojolicious::Plugin::Facets' => 0.07;

# Other
requires 'Module::Runtime' => 0.016;
requires 'Ref::Util';
requires 'DBIx::EAV' => 0.11;

requires 'Moo' => '1.003000';
requires 'Moose';

requires 'MooseX::Clone' => 0.05;
requires 'MooseX::Types';
requires 'MooseX::Types::Common';
requires 'List::Compare' => 0.37;

requires 'Unicode::Normalize' => 1.14;

requires 'Class::Load' => 0.12;

requires 'DBIx::Class::Candy' => 0.002001;
requires 'DBIx::Class::Helpers';
requires 'DBIx::Class::TimeStamp' => 0.14;
requires 'DBIx::Class::UUIDColumns' => 0.02006;
requires 'DBIx::Class::InflateColumn::Serializer' => 0.03;
requires 'DBIx::Class::InflateColumn::FS' => 0.01007;
requires 'DBIx::Class::IntrospectableM2M' => 0.001001;

requires 'Hash::Merge' => '<=0.200';

requires 'Gravatar::URL' => 1.06;
requires 'Image::Size' => 3.230;

requires 'Template::Plugin::Date' => 2.78;

requires 'XML::Feed' => 0.49;

requires 'Email::Sender' => 0.120001;

requires 'HTTP::BrowserDetect' => 2.01;

# datetime
requires 'DateTime::Format::Strptime' => 1.51;
requires 'DateTime::Format::W3CDTF' => 0.06;
requires 'DateTime::Format::ISO8601';

#
requires 'HTML::Strip' => 2.09;

# CHI
requires 'CHI' => 0.58;
requires 'CHI::Driver::Memcached' => 0.15;
requires 'Cache::Memcached::Fast' => 0.19;
#requires 'Cache::FastMmap';

# db drivers
requires 'DBD::mysql';


# misc
requires 'HTML::Selector::XPath' => 0.18;
requires 'MIME::Entity';
requires 'MIME::Types';
requires 'MIME::Base64';
requires 'Authen::SASL';
requires 'Git::Raw' => "== 0.79";
requires 'Data::Printer' => 0.35;
requires 'Digest::MurmurHash' => 0.11;
requires 'Digest::SHA' => 6.01;
requires 'Try::Tiny' => 0.016;
requires 'Type::Tiny' => 0.014;
requires 'Unicode::UTF8' => 0.59;
requires 'JavaScript::V8::CommonJS' => 0.07;
requires 'YAML::Any' => 0.84;
requires 'YAML::XS' => 0.41;
requires 'CSS::Sass' => '3.4.5';
requires 'CSS::Minifier::XS' => 0.08;
requires 'Number::Format' => 1.73;
requires 'JSON::XS' => 3.01;

requires 'Imager';
requires 'Imager::File::PNG';
requires 'Imager::File::JPEG';

requires 'Text::Markdown::Discount';