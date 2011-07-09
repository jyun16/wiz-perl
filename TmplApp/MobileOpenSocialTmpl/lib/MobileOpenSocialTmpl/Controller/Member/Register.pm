package MobileOpenSocialTmpl::Controller::Member::Register;

use Wiz::Noose;

extends qw(
    Wiz::Web::Framework::Controller::Register
);

our @AUTOFORM = qw(member register);
our $MODEL = 'Member';
our $USE_TOKEN = 0;
our $SESSION_NAME = __PACKAGE__;

sub _before_index {
    my $self = shift;
    my ($c, $af, $p, $s) = @_;
    my $session = $self->_session($c);
    $session->{finish_redirect_dest} = '/';
}

sub _before_execute_index {
    my $self = shift;
    my ($c, $af, $p, $s) = @_;
    my $member = $c->model('Member');
    if ($member->count({ userid => $c->req->param('userid') })) {
        $af->outer_error_message(userid  => 'user_already_exists');
    }
    elsif ($member->count({ email => $c->req->param('email') })) {
        $af->outer_error_message(email  => 'email_already_exists');
    }
}

sub _append_to_execute {
    my $self = shift;
    my ($c, $af, $p, $s, $m, $data) = @_;
    $c->force_login($data, 'member');
}

=head1 AUTHOR

=head1 COPYRIGHT & LICENSE

=cut

1;

__END__
