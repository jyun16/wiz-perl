package TmplApp::Controller::AllForm::MultiDelete;

use Wiz::Noose;
use Wiz::Constant qw(:common);

extends qw(
    Wiz::Web::Framework::Controller::MultiDelete
);

no warnings 'uninitialized';

use Wiz::Constant qw(:common);

our @AUTOFORM = qw(all_form_register);
our $MODEL = 'AllForm';
our $SESSION_NAME = __PACKAGE__;
our $SESSION_LABEL = 'default';
our $IDS_FIELD_NAME = 'ids';

sub _before_index {
    my $self = shift;
    my ($c, $af, $p, $s) = @_;
    $s->{finish_redirect_dest} = $c->req->referer;
}

=head1 AUTHOR

=head1 COPYRIGHT & LICENSE

=cut

1;
