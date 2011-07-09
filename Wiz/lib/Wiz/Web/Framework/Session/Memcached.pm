package Wiz::Web::Framework::Session::Memcached;

=head1 NAME

Wiz::Web::Framework::Session::Memcached

=head1 VERSION

version 1.0

=cut

our $VERSION = '1.0';

use Digest::MD5;
use Storable qw(thaw nfreeze);
use MIME::Base64;
use Cache::Memcached::Fast;

use Wiz::Noose;
use Wiz::Util::Array qw(array_random);

extends qw(
    Wiz::Web::Framework::Session
);

sub BUILD {
    my $self = shift;
    my $conf = $self->conf;
    if ($conf->{servers}) {
        my %servers = ();
        for (@{$conf->{servers}}) {
            $servers{$_} = new Cache::Memcached::Fast({ servers => [ $_ ] });
        }
        $self->{session_servers} = \%servers;
    }
    else {
        $self->{session_servers} = {
            $conf->{server} => new Cache::Memcached::Fast({ servers => [ $conf->{server} ] })
        };
    }
}

sub session_server {
    my $self = shift;
    my ($sid) = @_;
    my $server = $self->_extract_server_from_sid($sid);
    my $session_server = $self->{session_servers};
    $server and return $session_server->{$server};
    $session_server->{array_random(keys %$session_server)};
}

sub session {
    my $self = shift;
    unless ($self->{session_data}) {
        my $sid = $self->_get_session_id;
        my $session_server = $self->session_server($sid);
        if ($session_server and $sid) {
            my $session_data = $session_server->get($sid);
            if ($session_data) {
                my $base = thaw decode_base64 $session_data;
                if ($base->{expires} > time) {
                    $self->{session_data} = $base->{data};
                    $self->{session_id} = $sid;
                }
            }
        }
        unless ($self->{session_data}) {
            ($self->{session_id}, $self->{session_data}) = $self->_create_session;
        }
    }
    return $self->{session_data};
}

sub _set_session {
    my $self = shift;
    my ($sid, $data, $opts) = @_;
    my $conf = $self->conf;
    my $expires = $self->_calc_expires($conf->{expires});
    $expires ||= 86400;
    my $expire_time = time + $expires;
    my $memd_expire = $expires > 2592000 ? $expire_time : $expires;
    $self->session_server($sid)->set($sid => encode_base64 nfreeze({
        expires => $expire_time,
        data    => $data,
    }));
}

sub _remove_session {
    my $self = shift;
    my ($sid) = @_;
    $self->session_server($sid)->delete($sid);
}

sub _create_session_id {
    my $self = shift;
    my $sid = Digest::MD5::md5_hex(rand);
    my $session_server = $self->{session_servers};
    if (ref $session_server eq 'HASH') {
        $sid .= '-' . array_random(keys %$session_server);
    }
    $self->session_server($sid)->get($sid) or return $sid;
    $self->_create_session_id;
}

sub _extract_server_from_sid {
    my $self = shift;
    my ($sid) = @_;
    $sid =~ m/-(.*)/ and return $1;
    return;
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


