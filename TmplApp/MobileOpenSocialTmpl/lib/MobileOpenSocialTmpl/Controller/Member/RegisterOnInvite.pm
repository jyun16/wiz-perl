package MobileOpenSocialTmpl::Controller::Member::RegisterOnInvite;

use Wiz::Noose;

extends qw(
    Wiz::Web::Framework::Controller::Register
);

our @AUTOFORM = qw(member register);
our $MODEL = 'Member';
our $USE_TOKEN = 0;
our $SESSION_NAME = __PACKAGE__;

sub index {
    my $self = shift;
    my ($c) = @_;
    my $p = $c->req->params;
    my $token = $c->model('Token');
    my $member = $token->model('Member');
    my $token_data = $token->get_token($p->{token});
    $token_data or $c->goto_error(msgid => 'bad_token');
    my $data = $token_data->{data};
    if ($member->numerate(email => $data->{email})) {
        $c->goto_error(msgid => 'user_already_exists');
    }
    else {
        $member->set($data);
        my $member_data = $member->create;
        $token->remove_token($p->{token});
        $c->force_login($member_data, 'member');
        $token->commit;
        $c->redirect('/');
    }
}

=head1 AUTHOR

=head1 COPYRIGHT & LICENSE

=cut

1;

__END__
