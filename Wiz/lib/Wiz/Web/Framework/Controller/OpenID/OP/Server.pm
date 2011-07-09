package Wiz::Web::Framework::Controller::OpenID::OP::Server;

=head1 NAME

Wiz::Web::Framework::Controller::OpenID::OP::Server

=head1 SYNOPSIS

=head1 VERSION

version 1.0

=cut

our $VERSION = '1.0';

=head1 SYNOPSIS

=cut

use URI;
use Data::Dumper;
use HTTP::Status;
use Net::OpenID::Server;

use Wiz::Noose;
use Wiz::Web qw(uri_escape html_escape);

extends qw(Wiz::Web::Framework::Controller);

sub server {
    my $self = shift;
    my ($c) = @_;

    my $p = $c->req->params;
    my $nos = $self->_create_server($c);
    my $conf = $c->app_conf('openid_server');
    my $debug = $conf->{debug};
    if ($debug) { for (keys %$p) { /^openid/ and print STDERR "[$_]: $p->{$_}\n"; } }
    if ($p->{'openid.mode'} eq 'associate') {
        my($type, $data) = $nos->_mode_associate;
        $c->res->content_type($type);
        $c->res->body($data);
    }
    elsif ($p->{'openid.mode'} =~ /^checkid/) {
        my($type, $data) = $nos->_mode_checkid($nos->get_args('openid.mode'));
        if ($debug) {
            print STDERR "[ CHECKID ] " . $p->{'openid.mode'} . "\n";
            print STDERR "[ GET ARGS ] " . $nos->get_args('openid.mode') . "\n";
            print STDERR "[ TYPE ] $type" . "\n";
            print STDERR "[ DATA ] " . (Dumper $data) . "\n";
        }
        if (_check_realm($conf, $c->req->params)) {
            if ($type eq 'redirect') {
                $c->res->redirect($data);
            }
            elsif ($type eq 'setup') {
                $self->_server_setup($c, $nos, $type, $data);
            }
        }
        else {
            $c->res->redirect(_create_return_to_uri('error', $self->_session($c)));
        }
    }
    elsif ($p->{'openid.mode'} eq 'check_authentication') {
        my($type, $data) = $nos->_mode_check_authentication;
        $c->res->content_type($type);
        $c->res->body($data);
    }
    else {
        $c->res->status(RC_BAD_REQUEST);
        $c->res->body('Invalid openid.mode='.$p->{'openid.mode'});
    }
}

sub setup {
    my $self = shift;
    my ($c) = @_;

    if ($c->req->method eq 'POST') {
        if ($c->req->params->{cancel}) {
            $c->res->redirect(_create_return_to_uri('cancel', $self->_session($c)));
        }
        else { $self->_execute_setup($c); }
        $self->_remove_session($c);
    }
    else { $self->_setup($c); }
}

sub _create_server {
    my $self = shift;
    my ($c) = @_;

    my $conf = $c->app_conf('openid_server');
    my $nos = new Net::OpenID::Server(
        get_args        => $c->req->params,
        post_args       => $c->req->params,
        setup_url       => $c->uri_for($self->ourv('OPENID_SERVER_SETUP_URL')),
        endpoint_url    => $c->uri_for($self->ourv('OPENID_SERVER_ENDPOINT_URL')),
        get_user        => sub {
            $self->_create_server_get_user($c, $conf, @_);
        },
        get_identity    => sub {
            $self->_create_server_get_identity($c, $conf, @_);
        },
        is_identity     => sub {
            $self->_create_server_is_identity($c, $conf, @_);
        },
        is_trusted      => sub {
            $self->_create_server_is_trusted($c, $conf, @_);
        },
        server_secret   => sub {
            $self->_create_server_server_secret($c, $conf, @_);
        },
    );
}

sub _create_return_to_uri {
    my ($mode, $params) = @_;

    return $params->{return_to} . "&openid.mode=$mode&" .
        join('&', (
            map { "openid.$_=" . uri_escape($params->{$_}, '=&') }
                qw(identity assoc_handle trust_root))
        );
}

sub _check_realm {
    my ($conf, $params) = @_;

    my $realm = new URI(
        $params->{'openid.trust_root'} ? $params->{'openid.trust_root'} : $params->{'openid.realm'}
    );
    my $uri = new URI($params->{'openid.return_to'});
    my @realm = split /\./, $realm->host;

    if ($conf->{debug}) {
        print STDERR "[ check_realm: @realm ]\n";
    }
    else {
        if (@realm < 2) {
            warn "realm is too short"; return 0;
        }
        elsif (@realm == 2) {
            if ($realm[0] eq '*') {
                warn 'realm has very long range';
                return 0;
            }
        }
    }
    my $realm_regex = uri_escape $realm->host;
    $realm_regex =~ s/\./\\./g;
    $realm_regex =~ s/\*/\\.*/;

    return $uri->host =~ qr/$realm_regex/
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
