package Wiz::Web::Framework::Controller::Login::OAuth;

=head1 NAME

Wiz::Web::Framework::Controller::Login::OAuth

=head1 VERSION

version 1.0

=cut

our $VERSION = '1.0';

=head1 SYNOPSIS

=cut

use Clone qw(clone);
use OAuth::Lite::Consumer;

use Wiz::Noose;
use Wiz::Constant qw(:common);
use Wiz::Net::OAuth::Token;

extends qw(Wiz::Web::Framework::Controller::Login);

sub oauth_login {
    my $self = shift;
    my ($c) = @_;

    my $s = $self->_session($c);
    my $label = $self->ourv('OAUTH_AUTHZ_LABEL') || $self->ourv('AUTHZ_LABEL') || 'default';
    my $config = $c->app_conf('oauth');
    unless (grep { $label eq $_ } keys %$config) {
        $self->_oauth_login_failed(
            $c, $self->ourv('OAUTH_FAIL_DEST'), $self->ourv('LOGIN_FAILED_MESSAGE_ID'));
    }

    my $conf = $self->_oauth_conf($c, (clone $config), $label);
    my $consumer = OAuth::Lite::Consumer->new(%$conf);
    my $callback_url = $self->_create_callback_url($c, $conf);
    if (my $request_token = $consumer->get_request_token(callback_url => $callback_url)) {
        $self->_oauth_prepare_login($c, $s);
        delete $s->{_oauth}{$label};
        $s->{_oauth}{label} = $label;
        $s->{_oauth}{token} = $request_token;
        my $url = $consumer->url_to_authorize(token => $request_token);  
        $c->redirect($url);
        return 0;
    }

    $self->_oauth_login_failed(
        $c, $self->ourv('OAUTH_FAIL_DEST'), $self->ourv('LOGIN_FAILED_MESSAGE_ID'));
}

sub oauth_callback {
    my $self = shift;
    my ($c) = @_;

    my $s = $self->_session($c);
    my $label = $s->{_oauth}{label};
    my $conf = $self->_oauth_conf($c, (clone $c->app_conf('oauth')), $label);
    my $consumer = OAuth::Lite::Consumer->new(%$conf);
    my $verifier = $c->request->param('oauth_verifier');
    my $request_token = $s->{_oauth}{token};
    delete $s->{_oauth};

    $verifier 
        or $self->_oauth_login_failed($c, $self->ourv('OAUTH_NOT_VERIFIED_DEST'));
    $request_token 
        or $self->_oauth_login_failed($c, $self->ourv('OAUTH_NOT_REQUEST_TOKEN_DEST'));

    my $access_token = Wiz::Net::OAuth::Token->new(
        $consumer->get_access_token(
            token    => $request_token,
            verifier => $verifier,
        )
    );

    defined $access_token 
        or $self->_oauth_login_failed($c, $self->ourv('OAUTH_FAIL_DEST'));

    my $user = $self->_oauth_before_login($c, $label, $access_token); 
    $user ||= { label => $label, token => $access_token };
    unless ($self->ourv('OAUTH_NOLOGIN')) {
        $self->_login($c, $user);
        $self->_oauth_after_login($c, $label, $access_token);
    }

    $self->_oauth_finish_redirect($c, $s);
}

sub _oauth_conf {
    my $self = shift;
    my ($c, $config, $label) = @_;
    $config->{$label};
}

sub _oauth_prepare_login {}
sub _oauth_before_login {}
sub _oauth_after_login {}
sub _oauth_finish_redirect {
    my $self = shift;
    my ($c, $s) = @_;
    my $redirect_url = $s->{redirect_url} 
        || $self->ourv('OAUTH_LOGIN_SUCCESS_DEST')
        || $self->ourv('LOGIN_SUCCESS_DEST') 
        || '/';
    $c->redirect($redirect_url);
}

sub _login {
    my $self = shift;
    my ($c, $user) = @_;
    $c->force_login($user);
}

sub _logout {
    my $self = shift;
    my ($c) = @_;
    $c->logout($self->ourv('AUTHZ_LABEL'), $self->ourv('SESSION_LABEL'));
}

sub _oauth_login_failed {
    my $self = shift;
    my ($c, $url, $msgid) = @_;

    $url ||= 'oauth_failed';
    $msgid ||= 'oauth_failed';
    my $key = $self->ourv('OAUTH_ERROR_KEY') || 'oauth_error_message';
    $c->redirect(
        $self->_complement_dest($c, $url), 
        { $key => $c->error_message($msgid) }
    );  
}

sub _create_callback_url {
    my $self = shift;
    my ($c, $config) = @_;

    my $url = $config->{callback_url};
    unless ($url) {
        $url = $self->ourv('OAUTH_CALLBACK_DEST') || 'oauth_callback';
        if ($url =~ qr{https?://}) { } 
        elsif ($url =~ qr{^/(.*)}) { $url = $c->req->base. $1; } 
        else { $url = $c->req->base. $url; }
    }
    return $url;
}

sub oauth_logout {
    my $self = shift;
    my ($c) = @_;
    my $p = $c->req->params;
    my $dest = $p->{dest_url};
    $self->_logout($c);
    $self->_logout_finish_redirect($c, $dest);
}

sub _logout_finish_redirect {
    my $self = shift;
    my ($c, $dest) = @_;
    $dest or return;
    $c->redirect($dest);
}

=head1 AUTHOR

Toshihiro MORIMOTO C<< dealforest.net@gmail.com >>

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
