package OpenSocialTmpl::Controller::AllForm::Modify;

use Wiz::Noose;

extends qw(
    Wiz::Web::Framework::Controller::Modify
);

our @AUTOFORM = qw(all_form register);
our $MODEL = 'AllForm';
our $USE_TOKEN = 1;
our $SESSION_NAME = __PACKAGE__;
our $TEMPLATE_BASE = 'all_form/register';

sub _before_index {
    my $self = shift;
    my ($c, $af, $p, $s) = @_;
    $s->{finish_redirect_dest} = $c->req->referer;
}

=head1 AUTHOR

=head1 COPYRIGHT & LICENSE

=cut

1;

__END__
