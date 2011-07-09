package OpenSocialTmpl::Controller::AllForm::Show;

use Wiz::Noose;

extends qw(
    Wiz::Web::Framework::Controller::Show
);

our @AUTOFORM = qw(all_form register);
our $MODEL = 'AllForm';
our $SESSION_NAME = __PACKAGE__;  
our $AUTHZ_LABEL = 'member';
our $AUTH_FAIL_REDIRECT = 1;
our $AUTH_FAIL_STATUS_CODE = 403;

our %AUTH_TARGET = (
    '&index'    => {
        member  => 1,
    },
);

=head1 AUTHOR

=head1 COPYRIGHT & LICENSE

=cut

1;

__END__
