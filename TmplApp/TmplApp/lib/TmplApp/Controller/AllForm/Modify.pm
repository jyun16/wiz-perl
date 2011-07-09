package TmplApp::Controller::AllForm::Modify;

use Wiz::Noose;
use Wiz::Constant qw(:common);

extends qw(
    Wiz::Web::Framework::Controller::Modify
    TmplApp::Controller::AllForm::Common
);

our @AUTOFORM = qw(all_form_register);
our $MODEL = 'AllForm';
our $SESSION_NAME = __PACKAGE__;
our $SESSION_LABEL = 'default';
our $TEMPLATE_BASE = 'all_form/register';

=head1 AUTHOR

=head1 COPYRIGHT & LICENSE

=cut

1;

__END__
