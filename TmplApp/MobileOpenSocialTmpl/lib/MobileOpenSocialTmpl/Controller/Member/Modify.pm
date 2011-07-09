package MobileOpenSocialTmpl::Controller::Member::Modify;

use Wiz::Noose;
use Wiz::Constant qw(:common);

extends qw(
    Wiz::Web::Framework::Controller::Auth
    Wiz::Web::Framework::Controller::Modify
);

our @AUTOFORM = qw(member modify base);
our $MODEL = 'Member';
our $SESSION_NAME = __PACKAGE__;
our $AUTHZ_LABEL = 'admin';
our $AUTH_FAIL_REDIRECT = 1;
our $AUTH_FAIL_DEST = '/admin/login';
#our $AUTH_FAIL_STATUS_CODE = 403;
our $TEMPLATE_BASE = 'member/register';

our %AUTH_TARGET = (
    '&index'    => {
        member   => sub {
            my $self = shift;
            my ($c, $user) = @_;
            my $data = $c->slave_model(
                $self->ourv('MODEL'))->retrieve(id => $c->req->param('id'));
            if ($user->id != $data->{id}) {
                return FAIL;
            }
            return SUCCESS;
        },
    },
);

sub _before_index {
    my $self = shift;
    my ($c, $af) = @_;
    my $session = $self->_session($c);
    $session->{finish_redirect_dest} = $c->req->referer;
}

sub _index {
    my $self = shift;
    my ($c, $af) = @_;
    my $data = $c->slave_model(
        $self->ourv('MODEL'))->retrieve(id => $c->req->param('id'));
    $data->{confirm_email} = $data->{email};
    $af->params($data);
    $c->stash->{f} = $af;
}

sub _finish_redirect_dest {
    my $self = shift;
    my ($c, $session) = @_;
    return $session->{finish_redirect_dest};
}

=head1 AUTHOR

=head1 COPYRIGHT & LICENSE

=cut

1;

__END__
