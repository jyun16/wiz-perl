package Wiz::Net::Service::Twitter::API::ResultSet;

=head1 NAME

Wiz::Net::Service::Twitter::API::ResultSet

=head1 VERSION

version 1.0

=cut

our $VERSION = '1.0';

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut

use Clone qw(clone);

use Wiz::Noose;
use Wiz::Constant qw(:common);

has 'api' => (is => 'rw');
has 'method' => (is => 'rw');
has 'param' => (is => 'rw');
has 'data' => (is => 'rw', default => []);
has 'init' => (is => 'rw');
has 'proc' => (is => 'rw');
has 'req' => (is => 'rw');
has 'has_error' => (is => 'rw');
has 'error' => (is => 'rw');
has 'code' => (is => 'rw');

my %PROC = (
    search                      => 'search',
    statuses_home_timeline      => 'statuses',
    statuses_fiends_timeline    => 'statuses',
    statuses_user_timeline      => 'statuses',
    statuses_mentions           => 'statuses',
    statuses_retweeted_by_me    => 'statuses',
    statuses_retweeted_to_me    => 'statuses',
    statuses_retweeted_of_me    => 'statuses',
    statuses_friends            => 'statuses_user',
    statuses_followers          => 'statuses_user',
    get_lists                   => 'list',
    get_list_statuses           => 'list_statuses',
    get_list_memberships        => 'list',
    get_list_subscriptions      => 'list',
    get_list_members            => 'list_members',
    get_list_subscribers        => 'list_members',
    direct_messages             => 'direct_messages',
    direct_messages_sent        => 'direct_messages',
    friendships_incoming        => 'friendships',
    friendships_outgoing        => 'friendships',
    friends_ids                 => 'friendships',
    followers_ids               => 'friendships',
    favorites                   => 'list_statuses',
    blocks_blocking             => 'blocks',
);

sub BUILD {
    my $self = shift;
    my ($args) = @_;
    $self->{param} = clone $args->{param};
    my $proc = $PROC{$args->{method}};
    $self->can("_init_$proc") ? $self->init(\&{"_init_$proc"}) : $self->init(sub {});
    $self->can("_req_$proc") ?
        $self->req(\&{"_req_$proc"}) :
        $self->req(sub {
            my $self = shift;
            my $api = $self->api;
            $api->_request('GET', $api->_url($self->{method}), $self->{param});
        });
    $self->can("_proc_$proc") ? $self->proc(\&{"_proc_$proc"}) : $self->proc(sub {});
}

sub _init {
    my $self = shift;
    $self->{data} = [];
    for (qw(code has_error error)) { $self->{$_} = undef; }
}

sub next {
    my $self = shift;
    my $api = $self->api;
    $self->_init;
    $self->init->($self);
    my $res = $self->req->($self);
    if ($api->has_error) {
        for (qw(code has_error error)) { $self->{$_} = $api->{$_}; }
    }
    else { $self->proc->($self, $res); }
    @{$self->{data}} ? TRUE : FALSE;
}

sub _proc_search {
    my $self = shift;
    my ($res) = @_;
    if ($res->{results}) {
        $self->{data} = $res->{results};
        $self->{param}{page} = $res->{page} + 1;
        $self->{param}{max_id} ||= $res->{max_id};
    }
}

sub _init_statuses {
    my $self = shift;
    unless (defined $self->{param}{cursor}) { $self->{param}{cursor} = -1; }
}

sub _proc_statuses {
    my $self = shift;
    my ($res) = @_;
    if ($res and @$res) {
        $self->{data} = $res;
        $self->{param}{page}++;
    }
}

sub _init_statuses_user {
    my $self = shift;
    unless (defined $self->{param}{cursor}) { $self->{param}{cursor} = -1; }
}

sub _proc_statuses_user {
    my $self = shift;
    my ($res) = @_;
    if ($res->{users}) {
        $self->{data} = $res->{users};
        defined $res->{next_cursor} and $self->{param}{cursor} = $res->{next_cursor};
    }
}

sub _init_list {
    my $self = shift;
    unless (defined $self->{param}{cursor}) { $self->{param}{cursor} = -1; }
}

sub _req_list {
    my $self = shift;
    my $api = $self->api;
    $api->_request('GET', $api->_url($self->method, $api->{screen_name}), $self->{param});
}

sub _proc_list {
    my $self = shift;
    my ($res) = @_;
    if ($res->{lists}) {
        $self->{data} = $res->{lists};
        defined $res->{next_cursor} and $self->{param}{cursor} = $res->{next_cursor};
    }
}

sub _init_list_statuses {
    my $self = shift;
    unless (defined $self->{param}{page}) { $self->{param}{page} = 1; }
}

sub _req_list_statuses {
    my $self = shift;
    my $api = $self->api;
    $api->_request('GET', $api->_url($self->method, $api->{screen_name}, $self->{param}{id}), $self->{param});
}

sub _proc_list_statuses {
    my $self = shift;
    my ($res) = @_;
    if ($res and @$res) {
        $self->{data} = $res;
        $self->{param}{page}++;
    }
}

sub _init_list_members {
    my $self = shift;
    unless (defined $self->{param}{cursor}) { $self->{param}{cursor} = -1; }
}

sub _req_list_members {
    my $self = shift;
    my $api = $self->api;
    $api->_request('GET', $api->_url($self->method, $api->{screen_name}, $self->{param}{list_id}), $self->{param});
}

sub _proc_list_members {
    my $self = shift;
    my ($res) = @_;
    if ($res->{users}) {
        $self->{data} = $res->{users};
        defined $res->{next_cursor} and $self->{param}{cursor} = $res->{next_cursor};
    }
}

sub _init_direct_messages {
    my $self = shift;
    unless (defined $self->{param}{page}) { $self->{param}{page} = 1; }
}

sub _req_direct_messages {
    my $self = shift;
    my $api = $self->api;
    $api->_request('GET', $api->_url($self->method, $api->{screen_name}), $self->{param});
}

sub _proc_direct_messages {
    my $self = shift;
    my ($res) = @_;
    if ($res and @$res) {
        $self->{data} = $res;
        $self->{param}{page}++;
    }
}

sub _init_friendships {
    my $self = shift;
    unless (defined $self->{param}{cursor}) { $self->{param}{cursor} = -1; }
}

sub _req_friendships {
    my $self = shift;
    my $api = $self->api;
    $api->_request('GET', $api->_url($self->method), $self->{param});
}

sub _proc_friendships {
    my $self = shift;
    my ($res) = @_;
    if ($res->{ids}) {
        $self->{data} = $res->{ids};
        defined $res->{next_cursor} and $self->{param}{cursor} = $res->{next_cursor};
    }
}

sub _init_blocks {
    my $self = shift;
    unless (defined $self->{param}{page}) { $self->{param}{page} = 1; }
}

sub _req_blocks {
    my $self = shift;
    my $api = $self->api;
    $api->_request('GET', $api->_url($self->method), $self->{param});
}

sub _proc_blocks {
    my $self = shift;
    my ($res) = @_;
    if ($res and @$res) {
        $self->{data} = $res;
        $self->{param}{page}++;
    }
}

=head1 AUTHOR

Junichiro NAKAMURA, C<< <jyun16@gmail.com> >>

=head1 COPYRIGHT & LICENSE

Copyright 2009,2010 The Wiz Project. All rights reserved.

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
