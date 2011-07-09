package Wiz::Net::OpenSocial::API;

use Wiz::Noose;

=head1 NAME

Wiz::Net::OpenSocial::API

=head1 VERSION

version 1.0

=cut

our $VERSION = '1.0';

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut

use Clone qw(clone);
use JSON::Syck;
use OAuth::Lite;
use OAuth::Lite::Consumer;

use Wiz::Constant qw(:common);
use Wiz::Util::Hash qw(args2hash);
use Wiz::Net::OpenSocial::API::ResultSet;

requires 'api_base';

has 'api_base_domain' => (is => 'rw');
has 'api_version' => (is => 'rw');
has 'consumer_key' => (is => 'rw', required => 1);
has 'consumer_secret' => (is => 'rw', required => 1);
has 'consumer' => (is => 'rw');
has 'token' => (is => 'rw');
has 'token_secret' => (is => 'rw');
has 'viewer_id' => (is => 'rw', required => 1);
has 'has_error' => (is => 'rw');
has 'error' => (is => 'rw');
has 'code' => (is => 'rw');

sub BUILD {
    my $self = shift;
    my ($args) = @_;
    $self->{consumer} = new OAuth::Lite::Consumer(
        consumer_key    => $args->{consumer_key},
        consumer_secret => $args->{consumer_secret},
    );
}

sub request {
    my $self = shift;
    my ($method, $uri, $params, $options) = @_;
    $self->{error} = '';
    $self->{has_error} = FALSE;
    $params ||= {};
    $options ||= {};
    if ($self->token) {
        $options->{token} = new OAuth::Lite::Token(
            token   => $self->token,
            secret  => $self->token_secret,
        );
    }
    my $res = $self->{consumer}->request(
        method  => $method,
        url     => $uri,
        params  => {
            xoauth_requestor_id => $self->viewer_id,
            %$params,
        },
        %$options
    );
    $self->{code} = $res->code;
    if ($res->is_success) {
        my $content = $res->decoded_content;
        if ($content) {
            return $self->_return_result($content);
        }
        return TRUE;
    }
    else {
        my $error = JSON::Syck::Load $res->content;
        $self->{error} = $error->{Error}{Message};
        unless ($self->{error}) {
            $self->{error} = $res->status_line;
        }
        $self->{has_error} = TRUE;
        return undef;
    }
}

sub _return_result {
    my $self = shift;
    my ($content) = @_;
    my $data = JSON::Syck::Load $content;
    my $entry = delete $data->{entry};
    $entry = ref $entry eq 'ARRAY' ? $entry : [ $entry ];
    return wantarray ? ($entry, $data) : $entry;
}

sub friends {
    my $self = shift;
    my ($guid, $param) = @_;
    $param = $self->init_param($param);
    $param->{guid} = $guid;
    return wantarray ? do {
        my ($data) = $self->_friends({ guid => $guid });
        return $data;
    } : do {
        new Wiz::Net::OpenSocial::API::ResultSet(
            api     => $self, 
            param   => $param,
        );
    };
}

sub friends_count {
    my $self = shift;
    my ($guid) = @_;
    my ($trush, $info) = $self->_friends({ guid => $guid, count => 1 });
    $info ? $info->{totalResults} : FALSE;
}

sub is_friend {
    my $self = shift;
    my ($guid, $target) = @_;
    my ($trush, $info) = $self->request('GET',
        sprintf('%s/people/%s/@all/%s',
            $self->api_base, $guid, $target),
    );
    $info ? $info->{totalResults} : FALSE;
}

sub has_app_friends {
    my $self = shift;
    my ($guid, $param) = @_;
    $param = $self->init_param($param);
    $param->{guid} = $guid;
    $param->{filterBy} = 'hasApp';
    $self->friends($param);
}

sub _friends {
    my $self = shift;
    my ($param) = @_;
    my $guid = delete $param->{guid};
    $self->request('GET',
        sprintf('%s/people/%s/@friends', $self->api_base, $guid),
        $param,
    );
}

sub profile {
    my $self = shift;
    my ($guid) = @_;
    $self->request('GET',
        sprintf('%s/people/%s/@self', $self->api_base, $guid),
    );
}

sub viewer_profile {
    my $self = shift;
    $self->request('GET',
        sprintf('%s/people/@me/@self', $self->api_base),
    );
}

sub write_app_data {
    my $self = shift;
    my ($data) = @_;
    $self->request('POST',
        sprintf('%s/appdata/@me/@self/@app', $self->api_base),
        {
        },
        {
            headers => [ 'Content-Type' => 'application/json' ],
            content => JSON::XS::encode_json($data),
        },
    );
}

sub read_app_data {
    my $self = shift;
    my (@res) = $self->request('GET',
        sprintf('%s/appdata/@me/@self/@app', $self->api_base),
        {
            format  => 'json',
            fields  => '' 
        },
    );
    $res[0][0]{$res[1]{id}[0]};
}

sub modify_app_data {
    my $self = shift;
    my ($data) = @_;
    $self->request('PUT',
        sprintf('%s/appdata/@me/@self/@app', $self->api_base),
        {
        },
        {
            headers => [ 'Content-Type' => 'application/json' ],
            content => JSON::XS::encode_json($data),
        },
    );
}

sub remove_app_data {
    my $self = shift;
    my ($key) = @_;
    $self->request('DELETE',
        sprintf('%s/appdata/@me/@self/@app', $self->api_base),
        {
            fields  => $key,
        },
    );
}

sub init_param {
    my $self = shift;
    my ($param) = clone shift;
    if (exists $param->{limit}) {
        $param->{count} = delete $param->{limit}; 
    }
    if (exists $param->{offset}) {
        $param->{startIndex} = delete $param->{offset}; 
    }
    if (ref $param->{fields} eq 'ARRAY') {
        $param->{fields} = join ',', @{$param->{fields}};
    }
    return $param;
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
