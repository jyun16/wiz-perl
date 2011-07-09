package TmplApp::Controller::Member;

use Wiz::Noose;

extends qw(
    Wiz::Web::Framework::Controller::Auth
);

our @AUTOFORM = qw(login);
our $AUTHZ_LABEL = 'member';
our $LOGIN_SUCCESS_DEST = '/member/list/index';
our $LOGOUT_DEST = '/login';
our $AUTH_FAIL_DEST = '/login';
our $AUTH_FAIL_REDIRECT = 1 ;
our $USE_TOKEN = 0;
our $SESSION_NAME = __PACKAGE__;

our %AUTH_TARGET = (
);

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
