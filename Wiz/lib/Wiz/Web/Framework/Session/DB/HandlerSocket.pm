package Wiz::Web::Framework::Session::DB::HandlerSocket;

=head1 NAME

Wiz::Web::Framework::Session::DB::HandlerSocket

=head1 SQL

 CREATE TABLE session (
     id                      VARCHAR(72) PRIMARY KEY,
     session_data            TEXT,
     expires                 INTEGER
 ) ENGINE=innodb DEFAULT CHARACTER SET utf8 COLLATE utf8_bin;

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

sub session {
    my $self = shift;
    my $conf = $self->conf;
    unless ($self->{session_data}) {
        my $sid = $self->_get_session_id;
        my $hs =
            $self->c->slave_model('Session', $conf->{db})->handler_socket('PRIMARY', [qw(expires session_data)]);
        my $session_data = $hs->retrieve($sid); 
        if ($session_data) {
            if ($session_data->{expires} > time) {
                $self->{session_data} = thaw decode_base64 $session_data->{session_data};
                $self->{session_id} = $sid;
            }
        }
        unless ($self->{session_data}) {
            ($self->{session_id}, $self->{session_data}) = $self->_create_session;
        }
    }
    return $self->{session_data};
}

sub _create_session_id {
    my $self = shift;
    my $conf = $self->conf;
    my $model = $self->c->slave_model('Session', $self->conf->{db});
    my $sid = Digest::MD5::md5_hex(rand);
    my $hs =
        $self->c->slave_model('Session', $conf->{db})->handler_socket('PRIMARY', 'id');
    my $res = $hs->retrieve($sid);
    unless ($res->{id}) {
        return $sid;
    }
    $self->_create_session_id;
}

sub _set_session {
    my $self = shift;
    my ($sid, $data, $opts) = @_;
    my $conf = $self->conf;
    my $expires = $self->_calc_expires($conf->{expires});
    $expires ||= 86400;
    $expires += time;
    my $hs = $self->c->model('Session',
        $conf->{db})->writable_handler_socket('PRIMARY', [qw(id session_data expires)]);
    if ($sid) {
        my $old = $hs->retrieve($sid);
        my $session_data = encode_base64 nfreeze $data;
        if ($old) {
            $hs->update('=', $sid, [ $sid, $session_data, $expires ]);
        }
        else {
            $hs->insert($sid, $session_data, $expires);
        }
    }
}

sub _remove_session {
    my $self = shift;
    my ($sid) = @_;
    my $hs = $self->c->model('Session',
        $self->conf->{db})->writable_handler_socket('PRIMARY', [qw(id)]);
    $hs->delete('=', $sid);
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


