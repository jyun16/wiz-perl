package TmplApp::Controller::Member::Invite;

use Wiz::Noose;

extends qw(
    Wiz::Web::Framework::Controller::Register
    Wiz::Web::Framework::Controller::SimpleMail
);

our @AUTOFORM = qw(member_register);
our $MODEL = 'Member';
our $USE_TOKEN = 0;
our $SESSION_NAME = __PACKAGE__;

sub _after_execute_index {
    my $self = shift;
    my ($c, $af, $p, $s) = @_;
    my $member = $c->slave_model('Member');
    if ($member->duplicated_userid($p->{userid})) {
        $af->outer_error_label(userid => 'user_already_exists');
    }
    elsif ($member->numerate(email => $p->{email})) {
        $af->outer_error_label(email => 'email_already_exists');
    }
    if (!$af->has_error) {
        my $token = $c->model('Token');
        my $data = {};
        for (qw(userid password email)) {
            $data->{$_} = $p->{$_};
        }
        my $token_data = $token->create_token({ data => $data });
        my $mail_address = $c->appconf('mail_address');
        my $url = $c->uri_for('/member/register_on_invite/index', { token => $token_data->{token} });
        $url =~ s/:443//;
        my $param = {
            email   => $p->{email},
            url     => $url,
            from    => $mail_address->{register_member}{from},
        };
        $self->_send_mail($c, $param, 'mail/member/invite.tt');
        $token->commit;
        $self->_remove_session($c);
        $c->redirect('/member/invite/finish');
    }
}

=head1 AUTHOR

=head1 COPYRIGHT & LICENSE

=cut

1;

__END__
