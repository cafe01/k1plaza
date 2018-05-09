package Q1::Web::Form::Action::SendEmail;

use Moose;
use namespace::autoclean;
use Carp;
use Mojo::File qw/ tempfile /;
use Data::Printer;

has 'from'    => ( is => 'ro', isa => 'Str', default => '"Seu website!" <donotreply@q1software.com>' );
has 'to'      => ( is => 'ro', isa => 'Str', required => 1 );
has 'cc'      => ( is => 'ro', isa => 'Str' );
has 'bcc'     => ( is => 'ro', isa => 'Str' );
has 'to_field' => ( is => 'ro', isa => 'Str' );
has 'subject' => ( is => 'ro', isa => 'Str', default => "Mensagem do seu website! De: {name}" );

# TODO: possibly get email_template from the form itself
has 'email_template' => ( is => 'ro', isa => 'Str', default => 'formaction/sendemail.tt' );
has 'email_html_template' => ( is => 'ro', isa => 'Str' );


sub process  {
    my ($self, $ctx) = @_;
    my $app  = $ctx->{app};
    my $tx   = $ctx->{tx};
    my $form = $ctx->{form};

    # form and data
    my $fields = $form->value;

    # expand subject template
    my $subject = $self->subject;

    while (my ($k, $v) = each %$fields) {
    	$k = quotemeta($k);
        $subject =~ s/{$k}/$v/g;
    }

    # attachments
    my $tempdir = $app->home->child('file_storage/tmp/');
    $tempdir->make_path;

    my @attachments = map {
          my $upload = $_->value;
          my $asset = $upload->asset;
          my $tempfile = $tempdir->child('upload_'.int(rand 99999));
          $asset->move_to($tempfile);
          [$tempfile, $upload->filename, { cleanup => 1 }];
      } grep { $_->isa('HTML::FormHandler::Field::Upload') && exists $fields->{$_->name} } $form->fields;

    # recipient
    my $to = $self->to;

    if ($self->to_field && $fields->{$self->to_field}) {
        my $method = "options_".$self->to_field;
        $to = {$form->$method}->{$fields->{$self->to_field}};
    }

    # enqueue email
    my $form_data = $form->value;
    delete $form_data->{_csrf};
    $tx->send_email({
    	from       => $self->from,
        to         => $to,
        cc         => $self->cc,
        bcc        => $self->bcc,
        subject    => $subject,
        $self->email_template      ? (template      => $self->email_template)      : (),
        $self->email_html_template ? (html_template => $self->email_html_template) : (),
        template_include_path => $tx->template_include_path,
        template_data => {
        	form => { value => $form_data },
        },
        attachments => \@attachments,
        $fields->{email} ? ('reply-to' => $fields->{email}) : ()
    });
}


__PACKAGE__->meta->make_immutable();

1;

__END__
=pod

=head1 NAME

Q1::Web::Form::Action::SendEmail

=head1 VERSION

Version 0.1

=head1 DESCRIPTION

=head1 CONFIG ATTRIBUTES

=head2 to

The email destination.

=head1 METHODS

=head2 process

=head1 AUTHORS & COPYRIGHT

Carlos Fernando Avila Gratz - cafe _at_ q1software.com

=head1 LICENSE

Copyright Q1Software.

=cut
