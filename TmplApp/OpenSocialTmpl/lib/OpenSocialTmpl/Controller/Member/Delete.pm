package OpenSocialTmpl::Controller::Member::Delete;

use Wiz::Noose;

extends qw(
    Wiz::Web::Framework::Controller::Auth
    Wiz::Web::Framework::Controller::Delete
);

our @AUTOFORM = qw(member register);
our $MODEL = 'AllForm';
our $SESSION_NAME = __PACKAGE__;  
our $AUTHZ_LABEL = 'admin';
our $AUTH_FAIL_REDIRECT = 1;
our $AUTH_FAIL_DEST = '/admin/login';
our $TEMPLATE_BASE = 'member/show';

our %AUTH_TARGET = (
    '&index'   => {
        admin   => 1,
    }
);

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
