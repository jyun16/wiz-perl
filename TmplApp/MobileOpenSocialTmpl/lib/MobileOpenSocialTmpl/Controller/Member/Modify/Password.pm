package MobileOpenSocialTmpl::Controller::Member::Modify::Password;

use Wiz::Noose;

use base qw(
    Wiz::Web::Framework::Controller::SimpleMail
);

our @AUTOFORM = qw(member modify password_send);
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
        if (!$af->has_error) {
            my $member = $c->slave_model('Member');
            my $member_data = $member->getone(
                email   => $p->{email},
            );
            if ($member_data) {
                my $token = $c->model('Token');
                my $token_data = $token->create_token({ member_id => $member_data->{id} });
                my $param = {
                    email   => $p->{email},
                    url     => $c->uri_for('/member/modify/password/index', { token => $token_data->{token} }),
                };
                my $mail_address = $c->appconf('mail_address');
                $param->{from} = $mail_address->{modify_password}{from};
                $self->_send_mail($c, $param, 'mail/member/modify/password.tt');
                $token->commit;
            }
            $self->_remove_session($c);
            $c->redirect('send_finish');
        }
    }
    $c->stash->{f} = $af;
}

sub send_finish {
    my $self = shift;
    my ($c) = @_;
}

sub index {
    my $self = shift;
    my ($c) = @_;
    my $p = $c->req->params;
    my $af = $c->autoform([qw(member modify password)], $p, { language => $c->language });
    if ($c->req->method eq 'POST') {
        $af->params($p);
        $af->check_params;
        if ($af->has_error) {
            $af->clear_password_value;
        }
        else {
            my $token = $c->model('Token');
            my $token_data = $token->get_token($p->{token});
            $token_data or $c->goto_error(msgid => 'bad_token');
            my $member = $c->model('Member', $token);
            my $member_data = $member->getone(
                id  => $token_data->{member_id},
            );
            if ($member_data) {
                $member->set(password => $p->{password});
                $member->modify(
                    id  => $member_data->{id},
                );
                $token->remove_token($p->{token});
                $token->commit;
            }
            $self->_remove_session($c);
            $c->redirect('finish');
        }
    }
    $c->stash->{f} = $af;
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
