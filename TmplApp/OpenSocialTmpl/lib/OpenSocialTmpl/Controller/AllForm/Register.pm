package OpenSocialTmpl::Controller::AllForm::Register;

use Wiz::Noose;

extends qw(
    Wiz::Web::Framework::Controller::Register
);

our @AUTOFORM = qw(all_form register);
our $MODEL = 'AllForm';
our $USE_TOKEN = 0;
our $SESSION_NAME = __PACKAGE__;

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
