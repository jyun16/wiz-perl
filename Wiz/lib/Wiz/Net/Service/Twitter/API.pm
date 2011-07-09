package Wiz::Net::Service::Twitter::API;

=head1 NAME

Wiz::Net::Service::Twitter::API

=head1 VERSION

version 1.0

=cut

our $VERSION = '1.0';

=head1 SYNOPSIS

 my $t = new Wiz::Net::Service::Twitter::API(screen_name => 'ANY USER', password => 'ANY PASSWORD');

 my $user = $t->users_show || die $t->error;


 while ($rs->next) {
     for (@{$rs->data}) {
         warn $_->{screen_name};
     }
 }
 $rs->has_error and die $rs->error;


=head1 DESCRIPTIOs

=cut

use URI;
use LWP::UserAgent;
use HTTP::Request;
use HTTP::Request::Common;
use JSON::XS;
use Web::Scraper;
use File::MimeInfo;
use WWW::Mechanize;
use Net::OAuth;
use OAuth::Lite::Token;
use Digest::SHA;

use Wiz::Noose;
use Wiz::Dumper;
use Wiz::Net::OAuth;
use Wiz::Constant qw(:common);
use Wiz::Util::Hash qw(args2hash);
use Wiz::Util::String qw(trim_sp);
use Wiz::Net::Service::Twitter::API::ResultSet;

has 'version'           => (is => 'rw', default => 1);
has 'screen_name'       => (is => 'rw');
has 'user_id'           => (is => 'rw');
has 'password'          => (is => 'rw');
has 'ua'                => (is => 'rw');
has 'has_error'         => (is => 'rw');
has 'error'             => (is => 'rw');
has 'errors'            => (is => 'rw');
has 'code'              => (is => 'rw');
has 'die'               => (is => 'rw');
has 'consumer_key'      => (is => 'rw');
has 'consumer_secret'   => (is => 'rw');
has 'request_token_url' => (is => 'rw', default => 'https://twitter.com/oauth/request_token');
has 'authorize_url'     => (is => 'rw', default => 'https://twitter.com/oauth/authorize');
has 'access_token_url'  => (is => 'rw', default => 'https://twitter.com/oauth/access_token');
has 'xauth_url'         => (is => 'rw', default => 'https://api.twitter.com/oauth/access_token');
has 'signature_method'  => (is => 'rw', default => 'HMAC-SHA1');
has 'use_oauth'         => (is => 'rw', default => FALSE);
has 'use_xauth'         => (is => 'rw', default => FALSE);
has 'access_token'      => (is => 'rw');

my (%URL, @API, %API_METHOD, @API_RETURNS_RESULT_SET, %INIT_PARAM);

BEGIN {
    %URL = (
        search                          => 'http://search.twitter.com/search.json',
        trends                          => 'http://search.twitter.com/trends.json',
        trends_current                  => 'http://search.twitter.com/trends/current.json',
        trends_daily                    => 'http://search.twitter.com/trends/daily.json',
        trends_weekly                   => 'http://search.twitter.com/trends/weekly.json',

        statuses_public_timeline        => 'http://api.twitter.com/%s/statuses/public_timeline.json',
        statuses_home_timeline          => 'http://api.twitter.com/%s/statuses/home_timeline.json',
        statuses_friends_timeline       => 'http://api.twitter.com/%s/statuses/friends_timeline.json',
        statuses_user_timeline          => 'http://api.twitter.com/%s/statuses/user_timeline.json',
        statuses_mentions               => 'http://api.twitter.com/%s/statuses/mentions.json',
        statuses_retweeted_by_me        => 'http://api.twitter.com/%s/statuses/retweeted_by_me.json',
        statuses_retweeted_to_me        => 'http://api.twitter.com/%s/statuses/retweeted_to_me.json',
        statuses_retweeted_of_me        => 'http://api.twitter.com/%s/statuses/retweeted_of_me.json',

        statuses_show                   => 'http://api.twitter.com/%s/statuses/show/%s.json',
        statuses_update                 => 'http://api.twitter.com/%s/statuses/update.json',
        statuses_destroy                => 'http://api.twitter.com/%s/statuses/destroy/%s.json',
        statuses_retweet                => 'http://api.twitter.com/%s/statuses/retweet/%s.json',
        statuses_retweets               => 'http://api.twitter.com/%s/statuses/retweets/%s.json',
        statuses_retweets               => 'http://api.twitter.com/%s/statuses/retweets/%s.json',
        statuses_id_retweeted_by        => 'http://api.twitter.com/%s/statuses/%s/retweeted_by.json',
        statuses_id_retweeted_by_ids        => 'http://api.twitter.com/%s/statuses/%s/retweeted_by/ids.json',

        users_show                      => 'http://api.twitter.com/%s/users/show.json',
        users_lookup                    => 'http://api.twitter.com/%s/users/lookup.json',
        users_search                    => 'http://api.twitter.com/%s/users/search.json',
        users_suggestions               => 'http://api.twitter.com/%s/users/suggestions.json',
        users_suggestions_category      => 'http://api.twitter.com/%s/users/suggestions/%s.json',
        statuses_friends                => 'http://api.twitter.com/%s/statuses/friends.json',
        statuses_followers              => 'http://api.twitter.com/%s/statuses/followers.json',

        post_lists                      => 'http://api.twitter.com/%s/%s/lists.json',
        post_lists_id                   => 'http://api.twitter.com/%s/%s/lists/%s.json',
        get_lists                       => 'http://api.twitter.com/%s/%s/lists.json',
        get_list_id                     => 'http://api.twitter.com/%s/%s/lists/%s.json',
        delete_list_id                  => 'http://api.twitter.com/%s/%s/lists/%s.json',
        get_list_statuses               => 'http://api.twitter.com/%s/%s/lists/%s/statuses.json',
        get_list_memberships            => 'http://api.twitter.com/%s/%s/lists/memberships.json',
        get_list_subscriptions          => 'http://api.twitter.com/%s/%s/lists/subscriptions.json',

        get_list_members                => 'http://api.twitter.com/%s/%s/%s/members.json',
        post_list_members               => 'http://api.twitter.com/%s/%s/%s/members.json',
        delete_list_members             => 'http://api.twitter.com/%s/%s/%s/members.json',
        get_list_members_id             => 'http://api.twitter.com/%s/%s/%s/members/%s.json',

        get_list_subscribers            => 'http://api.twitter.com/%s/%s/%s/subscribers.json',
        post_list_subscribers           => 'http://api.twitter.com/%s/%s/%s/subscribers.json',
        delete_list_subscribers         => 'http://api.twitter.com/%s/%s/%s/subscribers.json',
        get_list_subscribers_id         => 'http://api.twitter.com/%s/%s/%s/subscribers/%s.json',

        direct_messages                 => 'http://api.twitter.com/%s/direct_messages.json',
        direct_messages_sent            => 'http://api.twitter.com/%s/direct_messages/sent.json',
        direct_messages_new             => 'http://api.twitter.com/%s/direct_messages/new.json',
        direct_messages_destroy         => 'http://api.twitter.com/%s/direct_messages/destroy/%s.json',

        friendships_create              => 'http://api.twitter.com/%s/friendships/create.json',
        friendships_destroy             => 'http://api.twitter.com/%s/friendships/destroy.json',
        friendships_exists              => 'http://api.twitter.com/%s/friendships/exists.json',
        friendships_show                => 'http://api.twitter.com/%s/friendships/show.json',
        friendships_incoming            => 'http://api.twitter.com/%s/friendships/incoming.json',
        friendships_outgoing            => 'http://api.twitter.com/%s/friendships/outgoing.json',

        friends_ids                     => 'http://api.twitter.com/%s/friends/ids.json',
        followers_ids                   => 'http://api.twitter.com/%s/followers/ids.json',

        account_verify_credentials      => 'http://api.twitter.com/%s/account/verify_credentials.json',
        account_rate_limit_status       => 'http://api.twitter.com/%s/account/rate_limit_status.json',
        account_end_session             => 'http://api.twitter.com/%s/account/end_session.json',
        account_update_delivery_device  => 'http://api.twitter.com/%s/account/update_delivery_device.json',
        account_update_profile_colors   => 'http://api.twitter.com/%s/account/update_profile_colors.json',
        account_update_profile_image    => 'http://api.twitter.com/%s/account/update_profile_image.json',
        account_update_profile_background_image => 'http://api.twitter.com/%s/account/update_profile_background_image.json',
        account_update_profile          => 'http://api.twitter.com/%s/account/update_profile.json',

        favorites                       => 'http://api.twitter.com/%s/favorites.json',
        favorites_create                => 'http://api.twitter.com/%s/favorites/create/%s.json',
        favorites_destroy               => 'http://api.twitter.com/%s/favorites/destroy/%s.json',

        notifications_follow            => 'http://api.twitter.com/%s/notifications/follow/%s.json',
        notifications_leave             => 'http://api.twitter.com/%s/notifications/leave/%s.json',

        blocks_create                   => 'http://api.twitter.com/%s/blocks/create/%s.json',
        blocks_destroy                  => 'http://api.twitter.com/%s/blocks/destroy/%s.json',
        blocks_exists                   => 'http://api.twitter.com/%s/blocks/exists/%s.json',
        blocks_blocking                 => 'http://api.twitter.com/%s/blocks/blocking.json',
        blocks_blocking_ids             => 'http://api.twitter.com/%s/blocks/blocking/ids.json',

        report_spam                     => 'http://api.twitter.com/%s/report_spam.json',

        saved_searches                  => 'http://api.twitter.com/%s/saved_searches.json',
        saved_searches_show             => 'http://api.twitter.com/%s/saved_searches/show/%s.json',
        saved_searches_create           => 'http://api.twitter.com/%s/saved_searches/create/%s.json',
        saved_searches_destroy          => 'http://api.twitter.com/%s/saved_searches/destroy/%s.json',

        trends_available                => 'http://api.twitter.com/%s/trends/available.json',
        trends_location                 => 'http://api.twitter.com/%s/trends/woeid.json',

        get_geo_nearby_places           => 'http://api.twitter.com/%s/geo/nearby_places.json',
        geo_reverse_geocode             => 'http://api.twitter.com/%s/geo/reverse_geocode.json',
        geo_id                          => 'http://api.twitter.com/%s/geo/id/%s.json',
        help_test                       => 'http://api.twitter.com/%s/help/test.json',
    );
    @API = qw(
        trends
        trends_current
        trends_daily
        trends_weekly
        statuses_public_timeline
        statuses_update
        users_show
        users_lookup
        users_search
        users_suggestions
        direct_messages_new
        friendships_create
        friendships_destroy
        friendships_exists
        friendships_show

        account_verify_credentials
        account_rate_limit_status
        account_end_session
        account_update_delivery_device
        account_update_profile_colors
        account_update_profile_image
        account_update_profile_background_image
        account_update_profile

        blocks_blocking_ids

        saved_searches

        trends_available

        geo_nearby_places
        geo_reverse_geocode

        help_test
    );
    %API_METHOD = (
        statuses_update                 => 'POST',
        direct_messages                 => 'POST',
        friendships_create              => 'POST',
        friendships_destroy             => 'DELETE',
        account_end_session             => 'POST',             
        account_update_delivery_device  => 'POST',
        account_update_profile_colors   => 'POST',
        account_update_profile_image    => 'MultiPart',
        account_update_profile_background_image => 'MultiPart',
        account_update_profile          => 'POST',
        report_spam                     => 'POST',
        saved_searches_create           => 'POST',
    );
    @API_RETURNS_RESULT_SET = qw(
        search
        statuses_home_timeline
        statuses_friends_timeline
        statuses_user_timeline
        statuses_mentions
        statuses_retweeted_by_me
        statuses_retweeted_to_me
        statuses_retweeted_of_me
        statuses_friends
        statuses_followers
        get_lists
        get_list_statuses
        get_list_memberships
        get_list_subscriptions
        get_list_members
        get_list_subscribers
        direct_messages
        direct_messages_sent
        friendships_incoming
        friendships_outgoing
        friends_ids
        followers_ids
        favorites
        blocks_blocking
    );
    %INIT_PARAM = (
        users_lookup => sub {
            my $self = shift;
            my ($param) = @_;
            for (qw(user_id screen_name)) { $self->_modify_array_value(',', $_, $param); }
        },
    );
    no strict 'refs';
    my $pkg = __PACKAGE__;
    for my $m (@API) {
        *{"$pkg::$m"} = sub {
            my $self = shift;
            my ($param) = args2hash @_;
            $INIT_PARAM{$m} and $INIT_PARAM{$m}->($self, $param);
            $self->_request($API_METHOD{$m} || 'GET', $self->_url($m), $param);
        };
    }
    for my $m (@API_RETURNS_RESULT_SET) {
        *{"$pkg::$m"} = sub {
            my $self = shift;
            my ($param) = args2hash @_;
            $INIT_PARAM{$m} and $INIT_PARAM{$m}->($self, $param);
            my $rs = new Wiz::Net::Service::Twitter::API::ResultSet(
                api     => $self,
                method  => $m,
                param   => $param
            );
            return $rs;
        }
    }
};

sub BUILD {
    my $self = shift;
    if ($self->{use_oauth}) {
        $self->{oauth} = new Wiz::Net::OAuth(
            version             => '1.0a',
            consumer_key        => $self->{consumer_key},
            consumer_secret     => $self->{consumer_secret},
            request_token_url   => $self->{request_token_url},,
            authorize_url       => $self->{authorize_url},
            access_token_url    => $self->{access_token_url},
            xauth_url           => $self->{xauth_url},
            access_token        => $self->{access_token},
        );
    }
    else {
        $self->{ua} = new LWP::UserAgent;
    }
}

sub statuses_show {
    my $self = shift;
    my ($param) = args2hash @_;
    $self->_request('GET', $self->_url('statuses_show', $param->{id}));
}

sub statuses_destroy {
    my $self = shift;
    my ($param) = args2hash @_;
    $self->_request('POST', $self->_url('statuses_destroy', $param->{id}));
}

sub statuses_retweet {
    my $self = shift;
    my ($param) = args2hash @_;
    $self->_request('POST', $self->_url('statuses_retweet', $param->{id}));
}

sub statuses_retweets {
    my $self = shift;
    my ($param) = args2hash @_;
    $self->_request('GET', $self->_url('statuses_retweets', $param->{id}));
}

sub statuses_id_retweeted_by {
    my $self = shift;
    my ($param) = args2hash @_;
    $self->_request('GET', $self->_url('statuses_id_retweeted_by', $param->{id}));
}

sub statuses_id_retweeted_by_ids {
    my $self = shift;
    my ($param) = args2hash @_;
    $self->_request('GET', $self->_url('statuses_id_retweeted_by_ids', $param->{id}));
}

sub users_suggestions_category {
    my $self = shift;
    my ($param) = args2hash @_;
    $self->_request('GET', $self->_url('users_suggestions_category', $param->{slug}), $param);
}

sub post_lists {
    my $self = shift;
    my ($param) = args2hash @_;
    $self->_request('POST', $self->_url('post_lists', $self->{screen_name}), $param);
}

sub post_lists_id {
    my $self = shift;
    my ($param) = args2hash @_;
    $self->_request('POST', $self->_url('post_lists_id', $self->{screen_name}, $param->{id}), $param);
}

sub get_list_id {
    my $self = shift;
    my ($param) = args2hash @_;
    $self->_request('GET', $self->_url('get_list_id', $self->{screen_name}, $param->{id}));
}

sub delete_list_id {
    my $self = shift;
    my ($param) = args2hash @_;
    $self->_request('DELETE', $self->_url('delete_list_id', $self->{screen_name}, $param->{id}));
}

sub post_list_members {
    my $self = shift;
    my ($param) = args2hash @_;
    $self->_request('POST', $self->_url('post_list_members', $self->{screen_name}, $param->{list_id}));
}

sub delete_list_members {
    my $self = shift;
    my ($param) = args2hash @_;
    $self->_request('DELETE', $self->_url('delete_list_members', $self->{screen_name}, $param->{list_id}));
}

sub get_list_members_id {
    my $self = shift;
    my ($param) = args2hash @_;
    $self->_request('GET', $self->_url('get_list_members_id', $self->{screen_name}, $param->{list_id}, $param->{id}));
}

sub post_list_subscribers {
    my $self = shift;
    my ($param) = args2hash @_;
    $self->_request('POST', $self->_url('post_list_subscribers', $self->{screen_name}, $param->{list_id}));
}

sub delete_list_subscribers {
    my $self = shift;
    my ($param) = args2hash @_;
    $self->_request('DELETE', $self->_url('delete_list_subscribers', $self->{screen_name}, $param->{list_id}));
}

sub get_list_subscribers_id {
    my $self = shift;
    my ($param) = args2hash @_;
    $self->_request('GET', $self->_url('get_list_subscribers_id', $self->{screen_name}, $param->{list_id}, $param->{id}));
}

sub direct_messages_destroy {
    my $self = shift;
    my ($param) = args2hash @_;
    $self->_request('POST', $self->_url('direct_messages_destroy', $param->{id}));
}

sub favorites_create {
    my $self = shift;
    my ($param) = args2hash @_;
    $self->_request('POST', $self->_url('favorites_create', $param->{id}));
}

sub favorites_destroy {
    my $self = shift;
    my ($param) = args2hash @_;
    $self->_request('POST', $self->_url('favorites_destroy', $param->{id}));
}

sub notifications_follow {
    my $self = shift;
    my ($param) = args2hash @_;
    $self->_request('POST', $self->_url('notifications_follow', $param->{id}), $param);
}

sub notifications_leave {
    my $self = shift;
    my ($param) = args2hash @_;
    $self->_request('POST', $self->_url('notifications_leave', $param->{id}), $param);
}

sub blocks_create {
    my $self = shift;
    my ($param) = args2hash @_;
    $self->_request('POST', $self->_url('blocks_create', $param->{id}), $param);
}

sub blocks_destroy {
    my $self = shift;
    my ($param) = args2hash @_;
    $self->_request('POST', $self->_url('blocks_destroy', $param->{id}), $param);
}

sub blocks_exists {
    my $self = shift;
    my ($param) = args2hash @_;
    $self->_request('GET', $self->_url('blocks_exists', $param->{id}), $param);
}

sub saved_searches_show {
    my $self = shift;
    my ($param) = args2hash @_;
    $self->_request('GET', $self->_url('saved_searches_show', $param->{id}));
}

sub saved_searches_create {
    my $self = shift;
    my ($param) = args2hash @_;
    $self->_request('POST', $self->_url('saved_searches_create', $param->{id}), $param);
}

sub saved_searches_destroy {
    my $self = shift;
    my ($param) = args2hash @_;
    $self->_request('POST', $self->_url('saved_searches_destroy', $param->{id}), $param);
}

sub trends_location {
    my $self = shift;
    my ($param) = args2hash @_;
    $self->_request('GET', $self->_url('trends_location', $param->{woeid}));
}

sub geo_id {
    my $self = shift;
    my ($param) = args2hash @_;
    $self->_request('GET', $self->_url('geo_id', $param->{id}));
}

sub _oauth_error {
    my $self = shift;
    my ($oauth) = @_;
    $self->{has_error} = TRUE;
    $self->{error} = $oauth->error;
    $self->{code} = $oauth->code;
    $self->die and die $oauth->error;

}

sub get_access_token_by_xauth {
    my $self = shift;
    $self->_init_error;
    my $oauth = $self->{oauth};
    my $ret = $oauth->get_access_token_by_xauth(
        screen_name => $self->{screen_name}, 
        password    => $self->{password},
    );
    if ($oauth->has_error) { $self->_oauth_error($oauth); return; }    
    return $ret;
}

sub broute_get_access_token {
    my $self = shift;
    my ($screen_name, $password) = @_;
    $screen_name ||= $self->screen_name;
    $password ||= $self->password;
    $self->_init_error;
    my $oauth = $self->{oauth};
    $oauth->get_request_token;
    if ($oauth->has_error) { $self->_oauth_error($oauth); return; }    
    my $auth_url = $oauth->get_url_to_authorize;
    my $ret = $oauth->get_access_token(
        verifier    => $self->_request_twitter4pin($auth_url, $screen_name, $password)
    );
    if ($oauth->has_error) { $self->_oauth_error($oauth); return; }    
    return $ret;
}

sub _request_twitter4pin {
    my $self = shift;
    my ($url, $screen_name, $password) = @_;
    my $mech = new WWW::Mechanize(autocheck => 1);
    $mech->get($url);
    $mech->submit_form(
        fields => {
            'session[username_or_email]' => $screen_name,
            'session[password]'          => $password,
        },
    );
    my $scraper = scraper { process '//div[@id="oauth_pin"]', 'pin' => 'TEXT' };
    my $data = $scraper->scrape($mech->content);
    trim_sp($data->{pin});
}

sub _url {
    my $self = shift;
    my ($name, @args) = @_;
    sprintf $URL{$name}, ($self->version, @args);
}

sub _init_error {
    my $self = shift;
    for (qw(code has_error error)) { $self->{$_} = undef; }
}

sub _request {
    my $self = shift;
    my ($method, $url, $param) = @_;
    $self->_init_error;
    my $req;
    if ($method eq 'MultiPart') {
        $req = POST $url, Content_type => 'form-data', Content => [ %$param ];
    }
    else {
        my $uri = new URI($url);
        if ($method ne 'POST') { $uri->query_form($param); }
        $req = new HTTP::Request($method => $uri->as_string);
        if ($method eq 'POST') {
            my $u = new URI();
            $u->query_form($param);
            $req->content($u->query);
        }
    } 
    my $res;
    if ($self->{use_oauth}) {
        my $uri = new URI($url);
        $uri->query_form($param);
        my $oauth = $self->{oauth};
        my $access_token = $self->{access_token};
        if ($self->{use_xauth}) {
            $access_token = $self->get_access_token_by_xauth;
            if ($oauth->has_error) { $self->_oauth_error($oauth); return; }    
        }
        my $ret = $oauth->request(
            method          => $method,
            url             => $url,
            access_token    => $access_token,
            params          => $param,
        );
        if ($oauth->has_error) { $self->_oauth_error($oauth); return; }    
        return decode_json($ret);
    }
    else {
        $req->authorization_basic($self->{screen_name}, $self->{password});
        $res = $self->{ua}->request($req);
    }
    $self->{code} = $res->code;
    if ($res->is_error) {
        my $content = $res->decoded_content || $res->content;
        eval {
            $content = decode_json($content);
            if ($content->{errors}) {
                $self->{errors} = $content;
                $content = $content->{errors}[0]{message};
            }
            else { $content = $content->{error}; }
        };
        $self->{has_error} = TRUE;
        $self->{error} = $content;
        $self->{die} and die $content;
        return undef;
    }
    else {
        my $ret;
        eval { $ret = decode_json($res->decoded_content || $res->content); };
        return $ret ? $ret : ($res->decoded_content || $res->content);
    }
}

sub _modify_array_value {
    my $self = shift;
    my ($delimiter, $name, $param) = @_;
    if ($param->{$name} and ref $param->{$name} eq 'ARRAY') {
        $param->{$name} = join $delimiter, @{$param->{$name}};
    }
}

1;

__END__

=head1 METHODS

=head2 search

 Authentication: false
 Limit: 1 call per request
 Parameters: 
     callback: If supplied, the response will use the JSONP format with a callback of the given name.
     lang:
     locale:
     max_id: Returns tweets with status ids less than the given id.
     q:
     rpp: The number of tweets to return per page, up to a max of 100.
     page:
     since: Returns tweets with since the given date.  Date should be formatted as YYYY-MM-DD
     since_id: Returns tweets with status ids greater than the given id.
     geocode:
     show_user: When true, prepends "<user>:" to the beginning of the tweet.
     until: Returns tweets with generated before the given date.  Date should be formatted as YYYY-MM-DD
     result_type: Specifies what type of search results you would prefer to receive.
         mixed: In a future release this will become the default value. Include both popular and real time results in the response.
         recent: The current default value. Return only the most recent results in the response.
         popular: Return only the most popular results in the response.

=head2 users_show

 Get user info.

 Authentication: false
 Limit: 1 call per request
 Parameters: 
     id: screen_name or user_id
     user_id:
     screen_name:

=head2 users_lookup

 Get users info.

 Authentication: true
 Limit: 1 call per request
 Parameters: 
     user_id: csv
     screen_name: csv

=head2 users_search

 Like search for users.

 Authentication: true
 Limit: 1 call per request and up to 60 calls per hour
 Parameters: 
     q: search string (
     per_page: 
     page: 

=head2 users_suggestions

 Get category for suggession.

 Authentication: false (if you passed to auth then return result for the user)
 Limit: 1 call per request

=head2 users_suggestions_category

 Get suggession.

 Authentication: true
 Limit: 1 call per request
 Parameters:
    slug: category name

=head2 statuses_friends

 Get friends users status. limit 100.

 Authentication: false unless requesting it from a protected user.
 Limit: 1 call per request
 Parameters:
    id:
    user_id:
    screen_name:
    cursor:

=head2 statuses_followers

 Get followers users status. limit 100.

 Authentication: false unless requesting it from a protected user.
 Limit: 1 call per request
 Parameters:
    id:
    user_id:
    screen_name:
    cursor:

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
