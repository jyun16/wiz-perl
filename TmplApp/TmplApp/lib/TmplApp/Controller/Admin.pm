package TmplApp::Controller::Admin;

use Wiz::Noose;

extends qw(
Wiz::Web::Framework::Controller::Login
);

our @AUTOFORM = qw(login);
our $AUTHZ_LABEL = 'admin';
our $SESSION_NAME = __PACKAGE__;  
our $LOGIN_SUCCESS_DEST = '/member/list/index';
our $LOGOUT_DEST = '/admin/login';
our $AUTH_FAIL_DEST = '/admin/login';
our $SESSION_LABEL = 'admin';

sub index {
    my $self = shift;
    my ($c) = @_;
    $c->logined($AUTHZ_LABEL) ?
        $c->redirect($LOGIN_SUCCESS_DEST) : 
        $c->redirect($AUTH_FAIL_DEST);
}

=head1 AUTHOR

=head1 COPYRIGHT & LICENSE

=cut

1;
