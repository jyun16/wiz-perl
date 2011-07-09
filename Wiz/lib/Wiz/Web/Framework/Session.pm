package Wiz::Web::Framework::Session;

=head1 NAME

Wiz::Web::Framework::Session

=head1 VERSION

version 1.0

=cut

use Wiz::Noose;
use Wiz::Constant qw(:common);

requires 'session';

has 'c' => (is => 'rw');
has 'conf' => (is => 'rw');
has 'label' => (is => 'rw');
has 'session_servers' => (is => 'rw');
has 'session_id' => (is => 'rw');
has 'session_data' => (is => 'rw');
has 'sid_from_param' => (is => 'rw');

my %scale = (
    m   => 60,
    h   => 3600,
    d   => 86400,
);

sub init {
    my $self = shift;
    delete $self->{session_id};
    delete $self->{session_data};
}

sub change_session_id {
    my $self = shift;
    $self->{session_id} = $self->_create_session_id;
    $self->_set_session_id($self->{session_id});
}

sub _session_name {
    my $self = shift;
    if ($self->conf->{session_name}) { return $self->conf->{session_name}; }
    my $session_name_prefix = $self->conf->{session_name_prefix};
    my $ret = $session_name_prefix ? $session_name_prefix : $self->c->app_name . '_session';
    return $ret . '_' . $self->label;
}

sub _get_session_id {
    my $self = shift;
    unless ($self->{session_id}) {
        if ($self->{sid_from_param}) {
            $self->{session_id} = $self->c->req->params->{$self->{sid_from_param}};
        }
        else {
            my $cookies = $self->c->req->cookies;
            $cookies or return;
            my $cookie = $cookies->{$self->_session_name};
            $cookie or return;
            $self->{session_id} = $cookie->value;
        }
    }
    return $self->{session_id};
}

sub _set_session_id {
    my $self = shift;
    my ($sid) = @_;
    unless ($self->{sid_from_param}) {
        $self->c->res->cookies->{$self->_session_name} =
            $self->_create_session_cookie($sid);
    }
    return $sid;
}

sub _create_session {
    my $self = shift;
    my $sid = $self->_create_session_id;
    $self->_set_session_id($sid);
    my $data = {};
    $self->_set_session($sid, $data);
    return ($sid, $data);
}

sub data2server {
    my $self = shift;
    $self->{session_data} or return;
    $self->_set_session(
        $self->{session_id},
        $self->{session_data},
        {
        },
    );
    delete $self->{session_data};
    return;
}

sub _create_session_cookie {
    my $self = shift;
    my ($sid, %attr) = @_;
    my $conf = $self->conf;
    my $expires = $self->_calc_expires($conf->{expires});
    my $cookie = {
        value => $sid,
        expires => time + $expires,
        %attr,
    };
    for (qw(domain path secure)) {
        $cookie->{$_} = $conf->{$_};
    }
    return $cookie;
}

sub _calc_expires {
    my $self = shift;
    my ($expires) = @_;
    $expires =~ /(\d*)([mhd])/ and $expires = $1 * $scale{$2};
    return $expires;
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


