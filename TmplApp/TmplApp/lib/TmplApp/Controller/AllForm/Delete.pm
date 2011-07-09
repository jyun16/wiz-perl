package TmplApp::Controller::AllForm::Delete;

use Wiz::Noose;
use Wiz::Constant qw(:common);

extends qw(
    Wiz::Web::Framework::Controller::Delete
);

our @AUTOFORM = qw(all_form_register);
our $MODEL = 'AllForm';
our $SESSION_NAME = __PACKAGE__;  
our $SESSION_LABEL = 'default';
our $TEMPLATE_BASE = 'all_form/show';

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
