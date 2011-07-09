package MobileOpenSocialTmpl::Controller::Member::Modify::Email;

use Wiz::Noose;

extends qw(
    Wiz::Web::Framework::Controller::SimpleMail
);

our @AUTOFORM = qw(member modify email);
our $MODEL = 'Member';
our $SESSION_NAME = __PACKAGE__;

sub send {
    my $self = shift;
    my ($c) = @_;
    my $p = $c->req->params;
    my $af = $c->autoform([@AUTOFORM], $p, { language => $c->language });
    if ($c->req->method eq 'POST') {
        $af->params($p);
        $af->check_params;
        my $member = $c->slave_model('Member');
        my $member_data = $member->getone(
            email   => $p->{old_email},
        );
        if (!$c->login($member_data->{userid}, $p->{password}, 'member')) {
            $af->outer_error_label(password => 'confirm_account_failed');
        }
        elsif ($member->numerate(email => $p->{email})) {
            $af->outer_error_label(email => 'email_already_exists');
        }
        elsif (!$af->has_error) {
            if ($member_data) {
                my $token = $c->model('Token');
                my $token_data = $token->create_token({
                    member_id => $member_data->{id},
                    data => {
                        email   => $p->{email},
                    },
                });
                my $mail_address = $c->appconf('mail_address');
                my $param = {
                    email   => $p->{email},
                    url     => $c->uri_for('/member/modify/email/index', { token => $token_data->{token} }),
                    from    => $mail_address->{modify_email}{from},
                };
                $self->_send_mail($c, $param, 'mail/member/modify/email.tt');
                $token->commit;
            }
            $self->_remove_session($c);
            $c->redirect('send_finish');
        }
    }
    $c->stash->{f} = $af;
}

sub send_finish  {
    my $self = shift;
    my ($c) = @_;
}

sub index {
    my $self = shift;
    my ($c) = @_;
    my $p = $c->req->params;
    my $token = $c->model('Token');
    my $token_data = $token->get_token($p->{token});
    $token_data or $c->goto_error(msgid => 'bad_token');
    my $data = $token_data->{data};
    my $member = $c->model('Member', $token);
    if ($c->_auth->conf('member')->{use_email_auth}) {
        $member->set(userid => $data->{email});
    }
    $member->set(email => $data->{email});
    $member->modify(id => $token_data->{member_id});
    $token->remove_token($p->{token});
    $token->commit;
    if ($c->logined) {
        $c->reflesh_login_user('member');
    }
    else {
        my $member_data = $member->getone(
            email   => $data->{email},
        );
        $c->force_login($member_data, 'member');
    }
    $c->redirect('finish');
}

sub finish {
    my $self = shift;
    my ($c) = @_;
}

=head1 AUTHOR

=head1 COPYRIGHT & LICENSE

=cut

1;

__END__
