package TmplApp::Controller::AllForm;

use Wiz::Noose;

extends qw(
Wiz::Web::Framework::Controller
);

our @AUTOFORM = qw(login);
our $AUTHZ_LABEL = 'member';
our $LOGIN_SUCCESS_DEST = '/all_form/list/index';
our $LOGOUT_DEST = '/login';
our $AUTH_FAIL_DEST = '/login';
our $AUTH_FAIL_REDIRECT = 1 ;
our $USE_TOKEN = 0;
our $SESSION_NAME = __PACKAGE__;

sub index {
    my $self = shift;
    my ($c) = @_;
    $c->logined ?
        $c->redirect($LOGIN_SUCCESS_DEST) :
        $c->redirect($AUTH_FAIL_DEST);
}

=head1 AUTHOR

=head1 COPYRIGHT & LICENSE

=cut

1;
