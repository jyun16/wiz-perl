package TmplApp::Controller::AllForm::Show;

use Wiz::Noose;
use Wiz::Constant qw(:common);

extends qw(
    Wiz::Web::Framework::Controller::Show
);

our @AUTOFORM = qw(all_form_register);
our $MODEL = 'AllForm';
our $SESSION_NAME = __PACKAGE__;  
our $SESSION_LABEL = 'default';

=head1 AUTHOR

=head1 COPYRIGHT & LICENSE

=cut

1;

__END__
