package Wiz::HTTPD::Nginx;

use strict;

=head1 NAME

Wiz::HTTPD::Nginx

=head1 VERSION

version 1.0

=head1 MEMO

=cut

use nginx;
use URI;
use HTTP::Request::Params;
use Nginx::Simple;
use File::Basename;

use Wiz::HTTPD qw(is_static host_name_with_port);
use Wiz::HTTP::Request;
use Wiz::HTTP::Response;

our $VERSION = '1.0';

no warnings 'uninitialized';

our @HEADERS = qw(
host
user-agent
connection
cookie
accept
accept-language
accept-encoding
accept-charset
);

sub handler {
    my ($r) = @_;
    $ENV{WIZ_APP_ENV} = $r->variable('WIZ_APP_ENV');
    _operation($r);
    return OK;
}

sub _output {
    my ($r, $res) = @_;
    for my $h (keys %{$res->headers}) {
        for ($res->header($h)) { $r->header_out($h => $_); }
    }
    $r->status($res->code);
    $r->send_http_header($res->content_type);
    $r->print($res->content);
}

sub _operation {
    my ($r) = @_;
    my $request_body;
    if ($r->has_request_body(sub {
        my ($r) = @_;
        _output($r, _create_response(_create_request($r, $r->request_body)));
    })) {}
    else {
        _output($r, _create_response(_create_request($r)));
    }
}

sub _get_request_headers {
    my ($r) = @_;
    my @headers = ();
    for (@HEADERS) {
        if ((my $v = $r->header_in($_)) ne '') {
            push @headers, ($_, $v);
        }
    }
    return wantarray ? @headers : \@headers;
}

sub _create_request {
    my ($r, $request_body) = @_;
    my $req = new Wiz::HTTP::Request(
        $r->request_method, $r->variable('request_uri'),
        [_get_request_headers($r)],
        $request_body,
    );
    for (qw(x-up-subno x-dcmguid x-jphone-uid)) {
        $req->headers->{$_} = $r->header_in($_);
    }
    my $port = $r->header_in('server-port') || $r->variable('server_port');
    $req->scheme($r->variable('scheme'));
    $req->host($r->variable('host'));
    $req->port($port);
    $req->client_host($r->header_in('x-forwarded-for') || $r->variable('remote_addr'));
    $req->complement;
    $req->engine_handler($r);
    $req->base(sprintf '%s://%s/', $req->scheme, host_name_with_port($req));
    return $req;
}

sub _create_response {
    my ($req) = @_;
    my $res = new Wiz::HTTP::Response;
    unless ($req) { $res->code(404); return $res; }
    $res->init;
    hook($req, $res);
    $res->complement;
    return $res;
}

sub hook {
    my ($req, $res) = @_;
    my $path = $req->path;
    if ($path =~ /.*\..*/) {}
    else {
        $path =~ m#^(/[^/]*?)#;
        my $app_name = basename $req->engine_handler->variable('WIZ_APP_ROOT');
        $path eq '/' and $path = 'index';
        no strict 'refs';
        $path =~ s/^\///;
        eval "use $app_name";
        "${app_name}::$path"->($req, $res);
    }
}

sub write_error {
    my ($r, $msg) = @_;
    $r->log_error(0, $msg);
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

sub _test_response {
    my ($r) = @_;
    my $res;
    my @variables = qw(
        args
        binary_remote_addr
        body_bytes_sent
        content_length
        content_type
        document_root
        document_uri
        host
        is_args
        limit_rate
        nginx_version
        query_string
        remote_addr
        remote_port
        remote_user
        request_filename
        request_body
        request_body_file
        request_completion
        request_method
        request_uri
        scheme
        server_addr
        server_name
        server_port
        server_protocol
        uri
    );
    for (@variables) { $res .= "$_: " . $r->variable($_) . "<br />\n"; }
    $res .= 'URI: ' . $r->uri . "<br />\n";
    $res .= 'REMOTE_ADDR: ' . $r->remote_addr . "<br />\n";
    $res .= 'REQUEST_METHOD: ' . $r->request_method . "<br />\n";
    $res .= 'ARG_PARAMETER(hoge): ' . $r->variable('arg_hoge') . "<br />\n";
    $res .= 'WIZ_APP_NAME: ' . $r->variable('WIZ_APP_NAME') . "<br />\n";
    $res .= 'WIZ_APP_ROOT: ' . $r->variable('WIZ_APP_ROOT') . "<br />\n";
    $res .= 'WIZ_APP_ENV: ' . $r->variable('WIZ_APP_ENV') . "<br />\n";
    # Retrieve cookie parameter -> cookie_$COOKIE_NAME
    $res .= 'COOKIE(ID): ' . $r->variable('cookie_ID') . "<br />\n";
    # Retrieve http header -> http_$HEADER_NAME
    $res .= 'HTTP_HEADER(user_agent): ' . $r->variable('http_user_agent') . "<br />\n";
    # Retrieve query parameter -> arg_$PARAM_NAME
    $res .= 'QUERY_PARAM(hoge): ' . $r->variable('arg_hoge') . "<br />\n";
    $r->status(200);
    $r->send_http_header('text/html; charset=utf-8');
    $r->print($res);
}

