package Wiz::Web::Framework::Controller::Login::OpenID;

=head1 NAME

Wiz::Web::Framework::Controller::Login::OpenID

=head1 VERSION

version 1.0

=cut

our $VERSION = '1.0';

=head1 SYNOPSIS

=cut

use LWP::UserAgent;
use Cache::File;
use Net::OpenID::Consumer;

use Wiz::Noose;
use Wiz::Constant qw(:common);
use Wiz::Util::Validation qw(is_url);

use Catalyst::Wiz::OpenID qw(trim_openid_identity);

extends qw(Wiz::Web::Framework::Controller::Login);

my %DEFAULT = (
    openid_identify_field => 'openid_identity',
);

sub openid_login {
    my $self = shift;
    my ($c) = @_;

    my $af = $c->autoform([$self->ourv('AUTOFORM', '@')]);
    if ($c->req->method eq 'GET' and $self->_has_checkid_params($c->req->params)) {
        $self->_checkid_params2session($c);
    }
    else {
        if ($c->req->param('openid_identity') eq '') {
            my $msgid = $self->ourv('LOGIN_FAILED_MESSAGE_ID') || 'login_failed';
            $c->stash->{$msgid} = $c->error_message($msgid);
        }
        else {
            $af->check_params;
            $af->has_error or $self->_openid_login($c);
        }
    }
    $c->stash->{f} = $af;
}

sub _openid_login {
    my $self = shift;
    my ($c) = @_;

    my $params = $c->req->params;
    my $conf = $c->app_conf('openid');
    my $csr = $self->_create_csr($c, $params);
    my $uri = $c->req->base;
    (my $openid_identity = $c->req->param('openid_identity')) =~ s/\s//g;
    if (my $claimed_identity = $csr->claimed_identity($params->{openid_identity})) {
        my $check_url = $claimed_identity->check_url(
            trust_root      => $uri,
            return_to       => $uri . 'openid_return_to',
            delayed_return  => $conf->{delayed_return},
        );
        $c->redirect($check_url);
    }
}

sub _create_csr {
    my $self = shift;
    my ($c, $params) = @_;

    my $ua = new LWP::UserAgent;
    my $conf = $c->app_conf('openid');
    defined $conf->{proxy} and $ua->proxy([qw(http)], $conf->{proxy});
    return new Net::OpenID::Consumer(
        debug           => $conf->{debug},
        ua              => $ua,
        args            => $params,
        consumer_secret => $conf->{consumer_secret},
        required_root   => $c->uri_for->as_string,
        cache           => new Cache::File(
            cache_root          => $conf->{cache_root},
            default_expires     => $conf->{cache_expire},
        ),
    );
}

# args: $c, $verified_identity
sub _openid_force_login_failed {}

sub openid_return_to {
    my $self = shift;
    my ($c) = @_;

    my $csr = $self->_create_csr($c, $c->req->params);
    if (my $setup_url = $csr->user_setup_url) {}
    elsif (my $vident = $csr->verified_identity) {
        my $identity_field = $self->ourv('OPENID_IDENTITY_FIELD') || $DEFAULT{openid_identify_field};
        if ($self->ourv('OPENID_FORCE_LOGIN')) {
            my $model = $c->slave_model($self->ourv('OPENID_MODEL'));
            my $user = $model->getone($identity_field => trim_openid_identity($vident->url));
            if ($user) {
                $c->force_login($user, $self->ourv('AUTHZ_LABEL'), $self->ourv('AUTHZ_DB_LABEL'),);
                $self->_redirect_after_login($c, 
                    $self->ourv('OPENID_VERIFIED_DEST'),
                    { $identity_field => $vident->url }
                );
            }
            else {
                $self->_openid_force_login_failed($c, $vident) or
                    $c->redirect($self->_complement_dest($c, $self->ourv('OPENID_NOT_VERIFIED_DEST')),
                        { $identity_field => $vident->url });
            }
        }
        else {
            $self->_redirect_after_login($c,
                $self->ourv('OPENID_VERIFIED_DEST'),
                { $identity_field => $vident->url }
            );
        }
    }
    elsif ($csr->user_cancel) {
        $c->redirect($self->_complement_dest($c, $self->ourv('OPENID_USER_CANCEL_DEST')));
    }
    else {
        $c->redirect($self->_complement_dest($c, $self->ourv('OPENID_NOT_VERIFIED_DEST')));
    }
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
