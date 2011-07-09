package Wiz::HTTP::Request;

use strict;

=head1 NAME

Wiz::HTTP::Request

=head1 VERSION

version 1.0

=cut

use URI;
use IO::Scalar;
use CGI::Simple::Cookie;
use HTTP::Request::Params;

use Wiz::Constant qw(:common);
use Wiz::Util::Hash qw(args2hash);
use Wiz::HTTP::Request::Upload;

use base qw(HTTP::Request Class::Accessor::Fast);

our $VERSION = '1.0';

__PACKAGE__->mk_accessors(qw(
    base path path_query uri_object host scheme port
    action action_package action_method
    user_agent client_host client_port location
    error error_code engine_handler args
));

sub new {
    my $class = shift;
    return $class->SUPER::new(@_);
}

sub param {
    my $self = shift;
    my ($key, $val) = @_;
    if (defined $val) {
        $self->{params}{$key} = $val;
    }
    return $self->{params}{$key};
}

sub params {
    my $self = shift;
    if (@_) {
        my $params = args2hash @_;
        for (keys %$params) {
            $self->{params}{$_} = $params->{$_};
        }
    }
    return $self->{params};
}

sub filename {
    my $self = shift;
    my ($name) = @_;
    defined $name and return $self->{filename}{$name};
    return $self->{filename};
}

sub upload {
    my $self = shift;
    $self->{upload}{shift()};
}

sub implement_params {
    my $self = shift;
    local @ARGV;
    undef @ARGV;
    my $parse_params = new HTTP::Request::Params({ req => $self });
    $self->{params} = $parse_params->params;
    my @content_type = $self->content_type;
    if ($content_type[0] eq 'multipart/form-data') {
        $parse_params->mime->walk_parts(sub {
            my ($part) = @_;
            $part->parts < 2 and return;
            for ($part->parts) {
                my $content_disposition = $_->header('Content-Disposition');
                my ($filename) = $content_disposition =~ /filename="(.*?)"/;
                my ($name) = $content_disposition =~ /name="(.*?)"/;
                if ($filename) {
                    delete $self->{params}{$name};                
                    $self->{upload}{$name} = new Wiz::HTTP::Request::Upload(
                        filename    => $filename,
                        data        => $_->body,
                    );
                }
            }
        });
    }
}

sub implement_cookies {
    my $self = shift;
    my $cookie = $self->header('cookie');
    $cookie and $self->{cookies} = CGI::Simple::Cookie->parse($cookie);
}

sub cookies_ids {
    my $self = shift;
    if ($self->{cookies}) {
        my @ids = keys %{$self->{cookies}}; 
        return wantarray ? @ids : \@ids;
    }
}

sub cookies {
    my $self = shift;
    my ($key, $value) = @_;
    if (defined $value) { $self->{cookies}{$key} = $value; }        
    elsif (defined $key) { return $self->{cookies}{$key}; }
    return $self->{cookies};
}

sub complement {
    my $self = shift;
    $self->uri =~ /([^\?]*)\?*(?:.*)/;
    $self->path($1);
    $self->path_query($self->uri);
    $self->user_agent($self->header('user-agent'));
    $ENV{HTTP_USER_AGENT} = $self->user_agent;
    for (keys %{$self->headers}) {
        if (/^x/) {
            (my $k = $_) =~ s/-/_/g;
            $ENV{"HTTP_" . uc $k} = $self->header($_);
        }
    }
    $self->implement_params;
    $self->host and $self->complement_uri;
    $self->implement_cookies;
}

sub complement_uri {
    my $self = shift;
    my $port = $self->port;
    my $uri = $self->scheme . '://';
    $uri .= $self->host;
    $uri .= $self->path;
    my $uri_object = new URI($uri);
    if ($port != 80 && $port != 443) {
        $uri_object->port($port);
    }
    if ($self->method eq 'GET') {
        $uri_object->query_form($self->params);
    }
    $self->uri_object($uri_object);
    $self->uri($uri_object->as_string);
    $self->path($uri_object->path);
}

sub secure {
    my $self = shift;
    $self->scheme eq 'https' ? TRUE : FALSE;
}

sub address {
    my $self = shift;
    return $self->client_host;
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
