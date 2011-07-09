package OpenSocialTmpl::Controller::AllForm::Delete;

use Wiz::Noose;

extends qw(
    Wiz::Web::Framework::Controller::Delete
);

our @AUTOFORM = qw(all_form register);
our $MODEL = 'AllForm';
our $SESSION_NAME = __PACKAGE__;  
our $TEMPLATE_BASE = 'all_form/show';
our $AUTHZ_LABEL = 'member';
our $AUTH_FAIL_REDIRECT = 1;
our $AUTH_FAIL_STATUS_CODE = 403;

our %AUTH_TARGET = (
    '&index'    => {
        member  => 1,
    },
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
