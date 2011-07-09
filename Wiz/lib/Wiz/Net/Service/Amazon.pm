package Wiz::Net::Service::Amazon;

=head1 NAME

Wiz::Net::Service::Amazon

=head1 VERSION

version 1.0

=cut

our $VERSION = '1.0';

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut

use Carp;
use LWP::UserAgent;
use MIME::Base64;
use XML::XPath;
use Date::Format;
use URI;
use URI::Escape qw(uri_escape);
use Digest::SHA qw(hmac_sha256_base64);
use XML::Simple;

use Wiz::Noose;

$XML::Simple::PREFERRED_PARSER = 'XML::Parser';

has 'api_url'           => (is => 'rw', default => 'http://ecs.amazonaws.jp/onca/xml');
has 'access_key'        => (is => 'rw');
has 'secret_key'        => (is => 'rw');
has 'response_group'    => (is => 'rw', default => 'Small');
has 'service'           => (is => 'rw', default => 'AWSECommerceService');
has 'operation'         => (is => 'rw', default => 'ItemSearch');
has 'version'           => (is => 'rw', default => '2009-03-31');
has 'timeout'           => (is => 'rw', default => 30);

sub item_search {
    my $self = shift;
    my ($p) = @_;
    $self->access_key or confess(q|Please define AWSAccessKeyId. $self->access_key('XXXXXXXXXXXXXXX')|);
    my $uri_base = sprintf '%s?Service=%s&Version=%s&Operation=%s&ResponseGroup=%s&AWSAccessKeyId=%s',
        $self->api_url,
        $self->service,
        $self->version,
        $self->operation,
        $self->response_group,
        $self->access_key;
    $p->{search_index} ||= 'All';
    foreach my $k (keys %$p) { $uri_base = $uri_base.'&'.$k.'='.$p->{$k}; }
    my $uri = new URI($uri_base);
    my $ua = new LWP::UserAgent;
    $ua->timeout($self->timeout);
    my $response = $ua->get($self->append_signature($uri));
    return $response->code == 200 ? XMLin $response->content : { fatal_error => $response->code };
}

sub append_signature {
    my $self = shift;
    my ($uri) = @_;
    $self->secret_key or confess(q|Please define SecretKey. $self->secret_key('XXXXXXXXXXXXXXX')|);
    my %query = $uri->query_form;
    my @now = gmtime;
    $query{Timestamp} ||= sprintf '%04d-%02d-%02dT%02d:%02d:%02dZ', $now[5]+1900, $now[4]+1, @now[3,2,1,0];
    my $qstring = join '&', map {"$_=". uri_escape($query{$_},"^A-Za-z0-9\-_.~")} sort keys %query;
    my $signme = join chr(10), "GET", $uri->host, $uri->path, $qstring;
    my $sig = hmac_sha256_base64($signme, $self->secret_key);
    $sig .= '=' while length($sig) % 4;
    $sig = uri_escape $sig,"^A-Za-z0-9\-_.~";
    $qstring .= "&Signature=$sig";
    $uri->query($qstring);

    return $uri;
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
