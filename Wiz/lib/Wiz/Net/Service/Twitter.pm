package Wiz::Net::Service::Twitter;

=head1 NAME

Wiz::Net::Service::Twitter

=head1 VERSION

version 1.0

=cut

our $VERSION = '1.0';

=head1 SYNOPSIS

 use Wiz::Net::Service::Twitter;

 #OAuth authorization.   
 my $client = Wiz::Net::Service::Twitter(
                config => {
                    consumer_key    => 'xxxxxxxxxxx',
                    consumer_secret => 'xxxxxxxxxxx',
                },
                user_info => {
                    token  => 'xxxxxxxxxxx',
                    secret => 'xxxxxxxxxxx',
                },
            );

 #Basic authorization.
 my $client = Wiz::Net::Service::Twitter(
                basic => 1,
                user_info => {
                    username => 'xxxxxx',
                    password => 'xxxxxx',
                },
            );

=head1 DESCRIPTION

=cut

use strict;
use warnings;

use Carp qw(confess);
use Net::Twitter;
use Scalar::Util qw(blessed);

use Wiz::Web qw(html_unescape);
use Wiz::Constant qw(:common);
use Wiz::Util::Hash qw(args2hash);

use constant TYPE_CLIENT_BASIC => 1;
use constant TYPE_CLIENT_OAUTH => 2;
use constant DEFAULT_CLIENT_TRAITS       => ['API::REST', 'API::Search'];
use constant DEFAULT_CLIENT_AUTH_TRAITS  => ['API::REST', 'API::Search', 'OAuth'];
use constant DECODE_TIMELINE_FIELDS      => qw(name description location text source);
use constant DECODE_TIMELINE_USER_FIELDS => qw(text source name kana);

use base 'Class::Accessor::Fast';
__PACKAGE__->mk_accessors(qw/client client_auth config log is_oauth is_basic/);

sub new {
    my $class = shift;
    my ($param) = args2hash(@_);
    $param->{user_info} or confess q|required user_info.|;
    unless ($param->{basic} || $param->{config}) { confess q|required config for oauth mode.|; }

    my $config = $param->{config};
    my $client_type = ($param->{basic}) ? TYPE_CLIENT_BASIC : TYPE_CLIENT_OAUTH; 
    my $init_data = ($client_type == TYPE_CLIENT_BASIC) 
        ? { traits => DEFAULT_CLIENT_TRAITS }
        : { 
            traits => DEFAULT_CLIENT_AUTH_TRAITS, 
            consumer_key => $config->{consumer_key}, 
            consumer_secret => $config->{consumer_secret}, 
        };

    my $self = $class->SUPER::new({ 
        config      => $param->{config},
        client      => Net::Twitter->new({ traits => DEFAULT_CLIENT_TRAITS }),
        client_auth => Net::Twitter->new( $init_data ),
        is_oauth    => $client_type == TYPE_CLIENT_OAUTH,
        is_basic    => $client_type == TYPE_CLIENT_BASIC,
    });
    $self->is_basic and $self->refresh_user( $param->{user_info} );
    $self->is_oauth and $self->refresh_token( $param->{user_info} );
    ref $param->{log} eq 'Wiz::Log' and $self->log($param->{log});
    $self;
}

sub refresh_user {
    my $self = shift;
    my ($user_info) = args2hash (@_);
    $self->is_basic or return DISABLE;
    defined $user_info->{username} && defined $user_info->{password} or return FAIL;

    $self->client_auth->username($user_info->{username});
    $self->client_auth->password($user_info->{password});
    SUCCESS;
}

sub refresh_token {
    my $self = shift;
    my ($user_info) = args2hash (@_);
    $self->is_oauth or return DISABLE;

    my ($access_token, $secret);
    if (ref $user_info eq 'Wiz::OAuth::Token' || ref $user_info eq 'Wiz::Net::OAuth::Token') {
        ($access_token, $secret) = $user_info->token2args;
    }
    elsif (ref $user_info eq 'OAuth::Lite::Token') {
        $secret       = $user_info->secret;
        $access_token = $user_info->token;
    } 
    elsif (defined $user_info->{user} && defined $user_info->{user}{token}) {
        #$access_token is $c->u. (use Wiz::Controller::Login::OAuth)
        my $at = $user_info->{user}{token};
        $secret       = $at->{secret};
        $access_token = $at->{token};
    }
    elsif (ref $user_info eq 'HASH') {
        $secret       = $user_info->{secret};
        $access_token = $user_info->{token};
    }
    defined $access_token && defined $secret or return FAIL;

    $self->client_auth->access_token($access_token);
    $self->client_auth->access_token_secret($secret);
    SUCCESS;
}

sub decode4timeline {
    my $self = shift;
    my ($timeline, $force_link) = @_;
    for my $status (@$timeline) {
        for (DECODE_TIMELINE_FIELDS) { $status->{$_} = Encode::decode_utf8($status->{$_}); }
        for (DECODE_TIMELINE_USER_FIELDS) { 
            $status->{user}{$_} = Encode::decode_utf8($status->{user}{$_}); 
            Wiz::Web::html_escape(\$_->{text});
            $force_link and Wiz::Web::Util::AutoLink::auto_link(\$_->{text});
        }
    }
}

sub public_timline {
    my $self = shift;
    my $ret;
    eval { $ret = $self->client->public_timline; };
    $self->_after_execute(undef, $ret, $@);
    $self->_finalize($ret, $@);
}

sub friends_timeline {
    my $self = shift;
    my ($param) = args2hash(@_);
    my $ret;
    $self->_before_execute($param);
    eval { $ret = $self->client_auth->friends_timeline($param); };
    $self->_after_execute($param, $ret, $@);
    $self->_finalize($ret, $@);
}

sub home_timeline {
    my $self = shift;
    my ($param) = args2hash(@_);
    my $ret;
    $self->_before_execute($param);
    eval { $ret = $self->client_auth->home_timeline($param); };
    $self->_after_execute($param, $ret, $@);
    $self->_finalize($ret, $@);
}

sub user_timeline {
    my $self = shift;
    my ($param) = args2hash(@_);
    my $ret;
    $self->_before_execute($param);
    eval { $ret = $self->client_auth->user_timeline($param); };
    $self->_after_execute($param, $ret, $@);
    $self->_finalize($ret, $@);
}

sub mentions {
    my $self = shift;
    my ($param) = args2hash(@_);
    my $ret;
    $self->_before_execute($param);
    eval { $ret = $self->client_auth->mentions($param); };
    $self->_after_execute($param, $ret, $@);
    $self->_finalize($ret, $@);
}

sub search {
    my $self = shift;
    my ($param) = args2hash(@_);
    my $ret;
    $self->_before_execute($param);
    eval { $ret = $self->client_auth->search($param); };
    $ret and html_unescape(\$_->{source}) for @{$ret->{results}};
    $self->_after_execute($param, $ret, $@);
    $self->_finalize($ret, $@);
}

sub show_status {
    my $self = shift;
    my ($param) = args2hash(@_);
    _require_args([qw/id/], $param);
    my $ret;
    $self->_before_execute($param);
    eval { $ret = $self->client->show_status($param); };
    $self->_after_execute($param, $ret, $@);
    $self->_finalize($ret, $@);
}

sub update {
    my $self = shift;
    my ($param) = args2hash(@_);
    _require_args([qw/status/], $param);
    my $ret;
    $self->_before_execute($param);
    eval { $ret = $self->client_auth->update($param); };
    $self->_after_execute($param, $ret, $@);
    $self->_finalize($ret, $@);
}

sub destroy_status {
    my $self = shift;
    my ($param) = args2hash(@_);
    _require_args([qw/id/], $param);
    my $ret;
    $self->_before_execute($param);
    eval { $ret = $self->client_auth->destroy_status($param); };
    $self->_after_execute($param, $ret, $@);
    $self->_finalize($ret, $@);
}

sub show_user {
    my $self = shift;
    my ($param) = args2hash(@_);
    _pre_require_args([qw/id screen_name user_id/], $param);
    my $client = (defined $param->{auth}) ? $self->client_auth : $self->client;
    my $ret;
    $self->_before_execute($param);
    eval { $ret = $client->show_user($param); };
    $self->_after_execute($param, $ret, $@);
    $self->_finalize($ret, $@);
}

sub friends {
    my $self = shift;
    my ($param) = args2hash(@_);
    _pre_require_args([qw/id screen_name user_id/], $param);
    my $client = (defined $param->{auth}) ? $self->client_auth : $self->client;
    my $ret;
    $self->_before_execute($param);
    eval { $ret = $client->friends($param); };
    $self->_after_execute($param, $ret, $@);
    $self->_finalize($ret, $@);
}

sub followers {
    my $self = shift;
    my ($param) = args2hash(@_);
    _pre_require_args([qw/id screen_name user_id/], $param);
    my $client = (defined $param->{auth}) ? $self->client_auth : $self->client;
    my $ret;
    $self->_before_execute($param);
    eval { $ret = $client->followers($param); };
    $self->_after_execute($param, $ret, $@);
    $self->_finalize($ret, $@);
}

sub direct_message {
    my $self = shift;
    my ($param) = args2hash(@_);
    my $ret;
    $self->_before_execute($param);
    eval { $ret = $self->client_auth->direct_message($param); };
    $self->_after_execute($param, $ret, $@);
    $self->_finalize($ret, $@);
}

sub new_direct_message {
    my $self = shift;
    my ($param) = args2hash(@_);
    _require_args([qw/user text/], $param);
    my $ret;
    $self->_before_execute($param);
    eval { $ret = $self->client_auth->new_direct_message($param); };
    $self->_after_execute($param, $ret, $@);
    $self->_finalize($ret, $@);
}

sub sent_direct_message {
    my $self = shift;
    my ($param) = args2hash(@_);
    my $ret;
    $self->_before_execute($param);
    eval { $ret = $self->client_auth->sent_direct_message($param); };
    $self->_after_execute($param, $ret, $@);
    $self->_finalize($ret, $@);
}

sub destroy_direct_message {
    my $self = shift;
    my ($param) = args2hash(@_);
    _require_args([qw/id/], $param);
    my $ret;
    $self->_before_execute($param);
    eval { $ret = $self->client_auth->destroy_direct_message($param); };
    $self->_after_execute($param, $ret, $@);
    $self->_finalize($ret, $@);
}

sub create_friend {
    my $self = shift;
    my ($param) = args2hash(@_);
    _pre_require_args([qw/id screen_name user_id/], $param);
    my $ret;
    $self->_before_execute($param);
    eval { $ret = $self->client_auth->create_friend($param); };
    $self->_after_execute($param, $ret, $@);
    $self->_finalize($ret, $@);
}

sub destroy_friend {
    my $self = shift;
    my ($param) = args2hash(@_);
    _pre_require_args([qw/id screen_name user_id/], $param);
    my $ret;
    $self->_before_execute($param);
    eval { $ret = $self->client_auth->destroy_friend($param); };
    $self->_after_execute($param, $ret, $@);
    $self->_finalize($ret, $@);
}

sub friendship_exists {
    my $self = shift;
    my ($param) = args2hash(@_);
    _require_args([qw/user_a user_b/], $param);
    my $ret;
    $self->_before_execute($param);
    eval { $ret = $self->client_auth->friendship_exists($param); };
    $self->_after_execute($param, $ret, $@);
    $self->_finalize($ret, $@);
}

sub show_friendship {
    my $self = shift;
    my ($param) = args2hash(@_);
    _pre_require_args([qw/source_id source_screen_name target_id target_id_name/], $param);
    my $client = (defined $param->{auth}) ? $self->client_auth : $self->client;
    my $ret;
    $self->_before_execute($param);
    eval { $ret = $self->client_auth->show_friendship($param); };
    $self->_after_execute($param, $ret, $@);
    $self->_finalize($ret, $@);
}

sub friends_ids {
    my $self = shift;
    my ($param) = args2hash(@_);
    _pre_require_args([qw/id screen_name user_id/], $param);
    my $ret;
    $self->_before_execute($param);
    eval { $ret = $self->client_auth->friends_ids($param); };
    $self->_after_execute($param, $ret, $@);
    $self->_finalize($ret, $@);
}

sub followers_ids {
    my $self = shift;
    my ($param) = args2hash(@_);
    _pre_require_args([qw/id screen_name user_id/], $param);
    my $ret;
    $self->_before_execute($param);
    eval { $ret = $self->client_auth->followers_ids($param); };
    $self->_after_execute($param, $ret, $@);
    $self->_finalize($ret, $@);
}

sub verify_credentials {
    my $self = shift;
    my $ret;
    eval { $ret = $self->client_auth->verify_credentials; };
    $self->_after_execute(undef, $ret, $@);
    $self->_finalize($ret, $@);
}

sub rate_limit_status {
    my $self = shift;
    my ($param) = args2hash(@_);
    my $client = (defined $param->{auth}) ? $self->client_auth : $self->client;
    my $ret;
    $self->_before_execute($param);
    eval { $ret = $client->rate_limit_status; };
    $self->_after_execute($param, $ret, $@);
    $self->_finalize($ret, $@);
}

sub end_session {
    my $self = shift;
    my ($param) = args2hash(@_);
    my $ret;
    $self->_before_execute($param);
    eval { $ret = $self->client_auth->end_session; };
    $self->_after_execute($param, $ret, $@);
    $self->_finalize($ret, $@);
}

sub update_delivery_device {
    my $self = shift;
    my ($param) = args2hash(@_);
    _require_args([qw/device/], $param);
    my $ret;
    $self->_before_execute($param);
    eval { $ret = $self->client_auth->update_delivery_device($param); };
    $self->_after_execute($param, $ret, $@);
    $self->_finalize($ret, $@);
}

sub update_profile_colors {
    my $self = shift;
    my ($param) = args2hash(@_);
    my $ret;
    $self->_before_execute($param);
    eval { $ret = $self->client_auth->update_profile_colors($param); };
    $self->_after_execute($param, $ret, $@);
    $self->_finalize($ret, $@);
}

sub update_profile_image {
    my $self = shift;
    my ($param) = args2hash(@_);
    _require_args([qw/image/], $param);
    my $ret;
    $self->_before_execute($param);
    eval { $ret = $self->client_auth->update_profile_image($param); };
    $self->_after_execute($param, $ret, $@);
    $self->_finalize($ret, $@);
}

sub update_profile_background_image {
    my $self = shift;
    my ($param) = args2hash(@_);
    _require_args([qw/image/], $param);
    my $ret;
    $self->_before_execute($param);
    eval { $ret = $self->client_auth->update_profile_background_image($param); };
    $self->_after_execute($param, $ret, $@);
    $self->_finalize($ret, $@);
}

sub update_profile {
    my $self = shift;
    my ($param) = args2hash(@_);
    my $ret;
    $self->_before_execute($param);
    eval { $ret = $self->client_auth->update_profile($param); };
    $self->_after_execute($param, $ret, $@);
    $self->_finalize($ret, $@);
}

sub favorites {
    my $self = shift;
    my ($param) = args2hash(@_);
    my $ret;
    $self->_before_execute($param);
    eval { $ret = $self->client_auth->favorites($param); };
    $self->_after_execute($param, $ret, $@);
    $self->_finalize($ret, $@);
}

sub create_favorite {
    my $self = shift;
    my ($param) = args2hash(@_);
    _require_args([qw/id/], $param);
    my $ret;
    $self->_before_execute($param);
    eval { $ret = $self->client_auth->create_favorite($param); };
    $self->_after_execute($param, $ret, $@);
    $self->_finalize($ret, $@);
}

sub destroy_favorite {
    my $self = shift;
    my ($param) = args2hash(@_);
    _require_args([qw/id/], $param);
    my $ret;
    $self->_before_execute($param);
    eval { $ret = $self->client_auth->destroy_favorite($param); };
    $self->_after_execute($param, $ret, $@);
    $self->_finalize($ret, $@);
}

sub enable_notifications {
    my $self = shift;
    my ($param) = args2hash(@_);
    _require_args([qw/id/], $param);
    my $ret;
    $self->_before_execute($param);
    eval { $ret = $self->client_auth->enable_notifications($param); };
    $self->_after_execute($param, $ret, $@);
    $self->_finalize($ret, $@);
}
*Wiz::Net::Service::Twitter::follow_notifications = \&enable_notifications;

sub disable_notifications {
    my $self = shift;
    my ($param) = args2hash(@_);
    _require_args([qw/id/], $param);
    my $ret;
    $self->_before_execute($param);
    eval { $ret = $self->client_auth->disable_notifications($param); };
    $self->_after_execute($param, $ret, $@);
    $self->_finalize($ret, $@);
}
*Wiz::Net::Service::Twitter::leave_notifications = \&disable_notifications;

sub create_block {
    my $self = shift;
    my ($param) = args2hash(@_);
    _pre_require_args([qw/id screen_name user_id/], $param);
    my $ret;
    $self->_before_execute($param);
    eval { $ret = $self->client_auth->create_block($param); };
    $self->_after_execute($param, $ret, $@);
    $self->_finalize($ret, $@);
}

sub destroy_block {
    my $self = shift;
    my ($param) = args2hash(@_);
    _pre_require_args([qw/id screen_name user_id/], $param);
    my $ret;
    $self->_before_execute($param);
    eval { $ret = $self->client_auth->destroy_block($param); };
    $self->_after_execute($param, $ret, $@);
    $self->_finalize($ret, $@);
}

sub exists_block {
    my $self = shift;
    my ($param) = args2hash(@_);
    _pre_require_args([qw/id screen_name user_id/], $param);
    my $ret;
    $self->_before_execute($param);
    eval { $ret = $self->client_auth->exists_block($param); };
    $self->_after_execute($param, $ret, $@);
    $self->_finalize($ret, $@);
}

sub saved_searches {
    my $self = shift;
    my $ret;
    eval { $ret = $self->client_auth->saved_searches; };
    $self->_after_execute(undef, $ret, $@);
    $self->_finalize($ret, $@);
}

sub show_saved_searches {
    my $self = shift;
    my ($param) = args2hash(@_);
    _require_args([qw/id/], $param);
    my $ret;
    $self->_before_execute($param);
    eval { $ret = $self->client_auth->show_saved_searches($param); };
    $self->_after_execute($param, $ret, $@);
    $self->_finalize($ret, $@);
}

sub create_saved_searches {
    my $self = shift;
    my ($param) = args2hash(@_);
    _require_args([qw/query/], $param);
    my $ret;
    $self->_before_execute($param);
    eval { $ret = $self->client_auth->create_saved_searches($param); };
    $self->_after_execute($param, $ret, $@);
    $self->_finalize($ret, $@);
}

sub destroy_saved_searches {
    my $self = shift;
    my ($param) = args2hash(@_);
    _require_args([qw/id/], $param);
    my $ret;
    $self->_before_execute($param);
    eval { $ret = $self->client_auth->destroy_saved_searches($param); };
    $self->_after_execute($param, $ret, $@);
    $self->_finalize($ret, $@);
}

sub _before_execute { }
sub _after_execute { }

sub _finalize {
    my $self = shift;
    my ($ret, $err) = @_;
    (not defined $err and $err eq '') and $err = undef;

    my $_error = $err;
    if (blessed $err && $err->isa('Net::Twitter::Error')) {
        if ($self->log && $err->code == 403) { 
            my $screen_name = $self->client_auth->username;
            my ($method_name) = (caller 1)[3] =~ /.*::(.*)$/;
            $method_name ||= 'anonymous';
            my ($code, $error) = ($err->code, $err->error);
            $error =~ s/ /_/g;
            $self->log->fatal(qq|$code $error $screen_name $method_name|);
        }
        $err = '['. $err->code. ' : '. $err->message. ']: '. $err->error;
    }
    { data => $ret, error => $err, _error => $_error };
}

sub _pre_require_args {
    my ($require, $args) = @_;
    my $check_flag = 0;
    for (@$require) { defined $args->{$_} and $check_flag = 1; }
    $check_flag or confess "pre required argument [". (join ' ', @$require). "]";
}

sub _require_args {
    my ($require, $args) = @_;
    for (@$require) { defined $args->{$_} or confess "required argument $_"; }
}

=head1 AUTHOR

Toshihiro MORIMOTO C<< dealforest.net@gmail.com >>

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
