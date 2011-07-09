package Wiz::Web::Framework::Controller::Login;

=head1 NAME

Wiz::Web::Framework::Controller::Login

=head1 SYNOPSIS

=head1 VERSION

version 1.0

=cut

our $VERSION = '1.0';

=head1 SYNOPSIS

=cut

use Wiz::Noose;
use Wiz::Web qw(uri_escape uri_unescape);
use Wiz::Constant qw(:common);

extends qw(Wiz::Web::Framework::Controller);

# If defined $c->session->{params}{forward} or the value of query parameter name "fw", 
# redirect to it after login,
# and changes string '$userid' in the value to the value in the $c->u->userid.
# The function'll be useful if you want to decide dynamically the redirect destination.
sub _before_login {}
sub _after_login {}
sub login {
    my $self = shift;
    my ($c) = @_;
    $self->_set_forward($c);
    $self->_check_login($c) and $self->_redirect_after_login($c);
    my $af = $c->autoform([$self->ourv('AUTOFORM', '@')]);
    $self->_before_login($c, $af);
    if ($c->req->method eq 'POST') {
        $af->check_params;
        $af->has_error or $self->_normal_login($c);
    }
    elsif ($self->_has_checkid_params($c->req->params)) {
        $self->_checkid_params2session($c);
    }
    $self->_after_login($c, $af);
    $c->stash->{f} = $af;
}

sub logout {
    my $self = shift;
    my ($c) = @_;
    $c->logout($self->ourv('AUTHZ_LABEL'), $self->ourv('SESSION_LABEL') || 'default');
    (my $base = $c->req->base) =~ s/\/$//;
    $c->redirect($base . $self->ourv('LOGOUT_DEST'));
}

sub _check_login {
    my $self = shift;
    my ($c) = @_;
    my $label = $self->ourv('AUTHZ_LABEL');
    my $session_label = $self->ourv('SESSION_LABEL');
    if (ref $label) {
        my $user_label = $c->u($label, $session_label)->label;
        for (@$label) { $_ eq $user_label and return TRUE; }
    }
    else { $c->logined($label, $session_label) and return TRUE; }
    return FALSE;
}

sub _login_session {
    my $self = shift;
    my ($c) = @_;
    $c->session($self->ourv('SESSION_LABEL') || 'default');
}

sub _normal_login {
    my $self = shift;
    my ($c) = @_;
    (my $userid = $c->req->param('userid')) =~ s/\s//g;
    (my $password = $c->req->param('password')) =~ s/\s//g;
    if ($self->ourv('CHANGE_SESSION_ID')) {
        $c->change_session_id;
    }
    if ($c->login(
        $userid, $password,
        $self->ourv('AUTHZ_LABEL'),
        $self->ourv('AUTHZ_DB_LABEL'),
        {
            session_label   => $self->ourv('SESSION_LABEL'),
            session_secure  => $self->ourv('SESSION_SECURE'),
        },
    )) {
        $c->req->params->{keep_login} and
            $self->_login_session($c)->{__ex_session_expires} = 62208000;
        $self->_redirect_after_login($c);
    }
    else {
        my $msgid = $self->ourv('LOGIN_FAILED_MESSAGE_ID') || 'login_failed';
        $c->stash->{$msgid} = $c->error_message($msgid);
    }
}

sub _set_forward {
    my $self = shift;
    my ($c) = @_;
    $c->req->param('fw') and
        $self->_login_session($c)->{params}{forward} = uri_unescape $c->req->param('fw');
}

sub _redirect_after_login {
    my $self = shift;
    my ($c, $uri) = @_;
    my $session = $self->_session($c);
    (my $base = $c->req->base) =~ s/\/$//;
    defined $uri or $uri = $self->_login_success_dest($c);
    if ($session->{params}{forward}) {
        $uri = $session->{params}{forward};
        delete $session->{params}{forward};
    }
    elsif ($self->_has_checkid_params($session)) {
        $uri = $self->_create_checkid_url($c, $session);
        $self->_remove_session($c);
    }
    $c->redirect($self->_complement_dest($c, $uri));
}

sub _has_checkid_params {
    my $self = shift;
    my ($params) = @_;
    if (($params->{trust_root} or $params->{realm}) and $params->{return_to}) { return TRUE; }
    return FALSE;
}

sub _checkid_params2session {
    my $self = shift;
    my ($c) = @_;
    my $session = $c->forward('_session');
    my $params = $c->req->params;
    for (qw(return_to identity assoc_handle trust_root)) {
        $session->{$_} = $params->{$_};
    }
}

sub _create_checkid_url {
    my $self = shift;
    my ($c, $params) = @_;
    return $c->req->base . 'openid/server?' . join('&', (
        'openid.mode=checkid_setup',
        map { "openid.$_=" . uri_escape($params->{$_}, '=&') }
            qw(return_to identity assoc_handle trust_root)
    ));
}

sub _login_success_dest {
    my $self = shift;
    my ($c) = @_;
    (my $base = $c->req->base) =~ s/\/$//;
    return $base . $self->ourv('LOGIN_SUCCESS_DEST');
}

=head1 AUTHOR

Junichiro NAKAMURA, C<< <jyun16@gmail.com> >>

=head1 COPYRIGHT & LICENSE

Copyright 2010 The Wiz Project. All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice,
this list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright
notice, this list of conditions and the following disclaimer in the
documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE WIZ PROJECT ``AS IS'' AND ANY
EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED.  IN NO EVENT SHALL THE WIZ PROJECT OR CONTRIBUTORS BE
LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER
IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OROTHERWISE)
ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
THE POSSIBILITY OF SUCH DAMAGE.

The views and conclusions contained in the software and documentation are
those of the authors and should not be interpreted as representing official
policies, either expressed or implied, of the Wiz Project.

Additionally, the followings are recommended for the developers
to modify/improve/extend Wiz. Please send modified code/patch to mail list,
wiz-perl@googlegroups.com.
The source you sent will be merged into Wiz package.
We welcome anyone who cooperates with us in developing this software.

We'll invite you to this project's member.

=cut

1;

__END__
