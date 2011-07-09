package OpenSocialTmpl::Controller::Root;

use Wiz::Noose;

extends qw(
    Wiz::Web::Framework::Controller::Root
    Wiz::Web::Framework::Controller::Login
);

our @AUTOFORM = qw(login);
our $AUTHZ_LABEL = 'member';
our $SESSION_NAME = __PACKAGE__;
our $LOGIN_SUCCESS_DEST = '/list';
our $LOGOUT_DEST = '/login';
our $AUTH_FAIL_DEST = '/login';

sub index {
    my $self = shift;
    my ($c) = @_;
    $c->logined ?
        $c->redirect($LOGIN_SUCCESS_DEST) :
        $c->redirect($AUTH_FAIL_DEST);
}

sub mixi_gadget {
    my $self = shift;
    my ($c) = @_;
    $c->stash->{conf} = $c->conf;
}

1;
