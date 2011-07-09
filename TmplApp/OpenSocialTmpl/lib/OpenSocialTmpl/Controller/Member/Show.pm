package OpenSocialTmpl::Controller::Member::Show;

use Wiz::Noose;

extends qw(
    Wiz::Web::Framework::Controller::Auth
    Wiz::Web::Framework::Controller::Show
);

our @AUTOFORM = qw(member register);
our $MODEL = 'Member';
our $SESSION_NAME = __PACKAGE__;  
our $AUTHZ_LABEL = 'admin';
our $AUTH_FAIL_REDIRECT = 1;
our $AUTH_FAIL_DEST = '/admin/login';

#our %AUTH_TARGET = (
#    '&index'   => {
#        admin   => 1,
#    }
#);

=head1 AUTHOR

=head1 COPYRIGHT & LICENSE

=cut

1;

__END__
