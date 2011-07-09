package Wiz::Net::OAuth;

use strict;

=head1 NAME

Wiz::Net::OAuth

=head1 VERSION

version 1.0

=cut

our $VERSION = '1.0';

=head1 SYNOPSIS

 my $o = new Wiz::Net::OAuth(
     version             => '1.0a',
     consumer_key        => $conf->{consumer_key},
     consumer_secret     => $conf->{consumer_secret},
     request_token_url   => 'https://twitter.com/oauth/request_token',
     authorize_url       => 'https://twitter.com/oauth/authorize',
     access_token_url    => 'https://twitter.com/oauth/access_token',
     xauth_url           => 'https://api.twitter.com/oauth/access_token',
     access_token        => $conf->{access_token},
 );

 my $request_token = $o->get_request_token or die $o->error;
 
 my $access_token = $o->get_access_token_by_xauth(
     screen_name => $conf->{screen_name},
     password    => $conf->{password},
 );
 wd $access_token;
 
 my $url_to_authorize = $o->get_url_to_authorize(
     request_token   => $request_token,
 ) or die $o->error;
 
 my $pin = _request_twitter4pin($url_to_authorize);
 my $access_token = $o->get_access_token(
     request_token   => $request_token,
     verifier        => $pin
 ) or die $o->error;
 
 my $res = $o->request(
     method          => 'GET',
     url             => "http://api.twitter.com/1/$conf->{screen_name}/lists.json",
     params          => { cursor => -1 },
 );
 $o->has_error and die $o->error;
 wd $res;

or simple 

 my $o = new Wiz::Net::OAuth(
     version             => '1.0a',
     consumer_key        => $conf->{consumer_key},
     consumer_secret     => $conf->{consumer_secret},
     request_token_url   => 'https://twitter.com/oauth/request_token',
     authorize_url       => 'https://twitter.com/oauth/authorize',
     access_token_url    => 'https://twitter.com/oauth/access_token',
     xauth_url           => 'https://api.twitter.com/oauth/access_token',
     access_token        => $conf->{access_token},
 );
 
 $o->get_request_token;
 $o->has_error and die $o->error;
 
 $o->get_access_token(
     verifier        => _request_twitter4pin($o->get_url_to_authorize)
 );
 $o->has_error and die $o->error;
 
 wd $o->request(
     method          => 'GET',
     url             => "http://api.twitter.com/1/$conf->{screen_name}/lists.json",
     params          => { cursor => -1 },
 );
 $o->has_error and die $o->error;

=head1 DESCRIPTION

=cut

use URI;
use Clone qw(clone);
use LWP::UserAgent;
use Digest::SHA;
use Digest::HMAC_SHA1;
use Net::OAuth;
use JSON::XS;
use HTTP::Request;
use HTTP::Request::Common;

use Wiz::Noose;
use Wiz::Dumper;
use Wiz::Constant qw(:common);
use Wiz::Util::Hash qw(args2hash);
use Wiz::Web::Util qw(parse_query uri_escape uri_unescape);

use Wiz::ConstantExporter [qw(
    check_oauth_signature_from_header
    create_oauth_signature
    create_oauth_signature_base
    parse_oauth_header
)];

has 'ua'                => (is => 'rw');
has 'version'           => (is => 'rw', default => '1.0', setter => sub {
    my $self = shift;
    my ($val) = @_; 
    if ($val eq '1.0a') {
        $Net::OAuth::PROTOCOL_VERSION = Net::OAuth::PROTOCOL_VERSION_1_0A;
    }
    elsif ($val == 1.0) {
        $Net::OAuth::PROTOCOL_VERSION = Net::OAuth::PROTOCOL_VERSION_1_0;
    }
    return $val;
});
has 'consumer_key'      => (is => 'rw');
has 'consumer_secret'   => (is => 'rw');
has 'request_token_url' => (is => 'rw');
has 'authorize_url'     => (is => 'rw');
has 'access_token_url'  => (is => 'rw');
has 'xauth_url'         => (is => 'rw');
has 'signature_method'  => (is => 'rw', default => 'HMAC-SHA1');
has 'request_token'     => (is => 'rw');
has 'access_token'      => (is => 'rw');
has 'has_error'         => (is => 'rw');
has 'error'             => (is => 'rw');
has 'errors'            => (is => 'rw');
has 'code'              => (is => 'rw');
has 'die'               => (is => 'rw');

sub BUILD {
    my $self = shift;
    $self->{ua} = new LWP::UserAgent;
}

sub create_request {
    my $self = shift;
    my $type = shift;
    my ($args) = args2hash @_;
    my $class = $type =~ s/^\+// ? $type : Net::OAuth->request($type);
    $self->_init_error;
    my $req = $class->new(
        version          => $self->{version},
        consumer_key     => $self->{consumer_key},
        consumer_secret  => $self->{consumer_secret},
        signature_method => $self->{signature_method},
        timestamp        => time,
        nonce               => Digest::SHA::sha1_base64(time . $$ . rand),
        %$args,
    );
    $req->sign;
    return $req;
}

sub get_request_token {
    my $self = shift;
    my ($args) = clone args2hash @_;
    $args->{callback} ||= 'oob';
    my $req = $self->create_request(
        'request token',
        request_method      => 'POST',
        request_url         => $self->request_token_url,
        %$args,
    );
    my $realm = delete $args->{realm};
    my $res = $self->{ua}->request(POST $self->request_token_url, [], Authorization => $req->to_authorization_header($realm));
    if ($res->is_success) {
        my $ret = parse_query($res->content);
        $ret = { token => $ret->{oauth_token}, secret => $ret->{oauth_token_secret} };
        $self->{request_token} = $ret;
        return $ret;
    }
    else {
        $self->_error_res($res);
    }
}

sub get_url_to_authorize {
    my $self = shift;
    my ($args) = clone args2hash @_;
    my $uri = new URI($self->authorize_url);
    my $request_token = delete $args->{request_token};
    $request_token ||= $self->{request_token};
    $uri->query_form(
        oauth_token => $request_token->{token},
        %$args,
    );
    return $uri->as_string;
}

sub get_access_token {
    my $self = shift;
    my ($args) = clone args2hash @_;
    my $request_token = delete $args->{request_token};
    $request_token ||= $self->{request_token};
    my $req = $self->create_request(
        'access token',
        request_method      => 'POST',
        request_url         => $self->access_token_url,
        token               => $request_token->{token},
        token_secret        => $request_token->{secret},
        %$args,
    );
    my $realm = delete $args->{realm};
    my $res = $self->{ua}->request(POST $self->access_token_url, [], Authorization => $req->to_authorization_header($realm));
    if ($res->is_success) {
        my $ret = parse_query($res->content);
        $ret = { token => $ret->{oauth_token}, secret => $ret->{oauth_token_secret} };
        $self->{access_token} = $ret;
        return $ret;
    }
    else {
        $self->_error_res($res);
    }
}

sub get_access_token_by_xauth {
    my $self = shift;
    my ($args) = clone args2hash @_;
    my $screen_name = delete $args->{screen_name};
    my $password = delete $args->{password};
    my $req = $self->create_request(
        'XauthAccessToken',
        request_method      => 'POST',
        request_url         => $self->xauth_url,
        x_auth_username     => $screen_name,
        x_auth_password     => $password,
        x_auth_mode         => 'client_auth',
        %$args,
    );
    my $realm = delete $args->{realm};

    my $http_req = new HTTP::Request(POST => $self->xauth_url);
    my $u = new URI();
    $u->query_form(
        x_auth_username     => $screen_name,
        x_auth_password     => $password,
        x_auth_mode         => 'client_auth',
    );
    $http_req->content($u->query);
    my $header = $req->to_authorization_header($args->{realm});
    $header =~ /(.*),x_auth_mode=.*/;
    $header = $1;
    $http_req->header(
        Authorization => $header,
    );
    my $res = $self->{ua}->request($http_req);
    if ($res->is_success) {
        my $ret = parse_query($res->content);
        $ret = { token => $ret->{oauth_token}, secret => $ret->{oauth_token_secret} };
        $self->{access_token} = $ret;
        return $ret;
    }
    else {
        $self->_error_res($res);
    }
}

sub request {
    my $self = shift;
    my ($args) = args2hash @_;
    my $access_token = $args->{access_token};
    $access_token ||= $self->{access_token};
    my $req = $self->create_request(
        'protected resource',
        request_method      => $args->{method},
        request_url         => $args->{url},
        token               => $access_token->{token},
        token_secret        => $access_token->{secret},
        extra_params        => $args->{params},
    );
    my $uri = new URI($args->{url});
    if ($args->{method} ne 'POST') {
        $uri->query_form(%{$args->{params}});
    }
    my $http_req = new HTTP::Request($args->{method} => $uri->as_string);
    if ($args->{method} eq 'POST') {
        my $u = new URI();
        $u->query_form($args->{params});
        $http_req->content($u->query);
    }
    $http_req->header(
        Authorization => $req->to_authorization_header($args->{realm})
    );
    my $res = $self->{ua}->request($http_req);
    if ($res->is_success) {
        return $res->content;
    }
    else {
        $self->_error_res($res);
    }
}

sub _init_error {
    my $self = shift;
    for (qw(code has_error error)) { $self->{$_} = undef; }
}

sub _error_res {
    my $self = shift;
    my ($res) = @_;
    $self->{code} = $res->code; 
    my $error = $res->content;
    $error =~ /^\s*$/ and $error = $res->message; 
    eval {
        my $e = decode_json($error);
        $error = $e->{error};
    };
    $self->{has_error} = TRUE;
    $self->{error} = $error;
    $self->{die} and die $error;
    return undef;
}

sub check_oauth_signature_from_header {
    my ($consumer_secret, $header, $method, $uri, $p) = @_;
    my $op = parse_oauth_header($header);
    my $oauth_signature = delete $op->{oauth_signature};
    my $oauth_token_secret = $op->{oauth_token_secret};
    for (keys %$p) { $op->{$_} = $p->{$_}; }
    my $check_signature = create_oauth_signature($consumer_secret, $oauth_token_secret, $method, $uri, $op);
    $oauth_signature eq $check_signature ? TRUE : FALSE;
}

sub create_oauth_signature {
    my ($consumer_secret, $oauth_token_secret, $method, $uri, $p) = @_;
    my $u = new URI($uri);
    $u->query_form({});
    my $base_string = create_oauth_signature_base($method, $u, $p);
    my $hmac = new Digest::HMAC_SHA1("$consumer_secret&$oauth_token_secret");
    $hmac->add($base_string);
    return $hmac->b64digest . '=';
}

sub create_oauth_signature_base {
    my ($method, $u, $op) = @_;
    my @ret = ($method);
    my $uri = $u;
    ref $u eq 'URI' and $uri = $u->as_string;
    push @ret, uri_escape $uri;
    my @r;
    for (sort keys %$op) {
        push @r, "$_=" . (uri_escape $op->{$_});
    }
    push @ret, uri_escape join '&', @r;
    return join '&', @ret;
}

sub parse_oauth_header {
    my ($header) = @_;
    my %ret;
    for (split /,/, $header) {
        /OAuth/ and next;
        s/[\s"]//g;
        /(.*)=(.*)/;
        $ret{$1} = uri_unescape $2;
    }
    return \%ret;
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
