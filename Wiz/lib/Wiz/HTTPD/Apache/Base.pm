package Wiz::HTTPD::Apache::Base;

use strict;

=head1 NAME

Wiz::HTTPD::Apache::Base

=head1 VERSION

version 1.0

=head1 MEMO

=cut

use APR::Table;
use APR::Brigade ();
use APR::Bucket ();
use APR::Const qw(SUCCESS BLOCK_READ);
use Apache2::Const qw(OK MODE_READBYTES);
use Apache2::Connection;
use Apache2::ServerRec;
use Apache2::ServerUtil;
use Apache2::RequestRec;
use Apache2::RequestUtil;
use Apache2::RequestIO;
use Apache2::Directive;
use HTTP::Request::Params;
use File::MimeInfo;

use Wiz::HTTPD qw(is_static);
use Wiz::HTTP::Request;
use Wiz::HTTP::Response;

our $VERSION = '1.0';
our $MAX_REQUEST_SIZE = 10_000_000;
our $BUFFER_SIZE = 4096;
our $APACHE_CONFIG_TREE;
our $APP_NAMES;
our $SERVER;

sub perl_script_names_from_location {
    my %ret = ();
    my $apache_conf = $APACHE_CONFIG_TREE;
    _perl_script_names_from_location(\%ret, $apache_conf->{Location});
    my $virtual_host = $apache_conf->{VirtualHost};
    if ($virtual_host) {
        for (keys %$virtual_host) {
            _perl_script_names_from_location(\%ret, $virtual_host->{$_}{Location});
        }
    }
    return \%ret;
}

sub _perl_script_names_from_location {
    my ($ret, $locations) = @_;
    $locations or return;
    for (keys %$locations) {
        my $l = $locations->{$_};
        if ($l->{SetHandler} eq 'perl-script' and $l->{PerlSetVar} ne 'WIZ CATALYST') {
            $ret->{$_} = $l->{PerlResponseHandler};
            $ret->{$_} ||= $l->{PerlHandler};
        }
    }
}

BEGIN {
    getppid == 1 or return;
    $APACHE_CONFIG_TREE ||= Apache2::Directive::conftree->as_hash;
    $SERVER = Apache2::ServerUtil->server;
    my $perl_script_names = perl_script_names_from_location();
    for (keys %$perl_script_names) {
        $APP_NAMES->{$_} = $perl_script_names->{$_};
    }
}

sub handler {
    my ($r) = @_;
    my $s = Apache2::ServerUtil->server;
    my $res = _create_response(_create_request($r));
    $r->content_type($res->content_type);
    for my $header (keys %{$res->headers}) {
        for ($res->header($header)) {
            $r->headers_out->add($header => $_);
        }
    }
    $r->print($res->content);
    $r->status($res->code);
    return Apache2::Const::OK;
}

# This is very simple default hook. override it.
sub hook {
    my ($req, $res) = @_;
    my $path = $req->path;
    if (is_static($req)) {
        my $f;
        unless (open $f, '<', $path) {
            $res->code(404);
            write_error("Can't open $path($!)");
            return;
        }
        my $data;
        while (<$f>) { $data .= $_; }
        close $f;
        $res->content_type(mimetype($path));
        $res->content($data);
    }
    else {
        $path =~ m#^(/[^/]*)#;
        my $app_name = $APP_NAMES->{$1};
        $path eq '/' and $path = 'index';
        no strict 'refs';
        "${app_name}::$path"->($req, $res);
    }
}

sub read_post_data {
    my $r = shift;
    my $ret;
    my $buf = '';
    if ($MAX_REQUEST_SIZE) {
        while ($r->read($buf, $BUFFER_SIZE)) {
            $ret .= $buf;
            if (length $ret > $MAX_REQUEST_SIZE) {
                return { error_message => 'Over max request size', error_code => 403 };
            }
        }
    }
    else {
        while ($r->read($buf, $BUFFER_SIZE)) {
            $ret .= $buf;
        }
    }
    return { data => $ret };
}

sub _create_request {
    my ($r) = @_;
}

sub _create_response {
    my ($req) = @_;
    my $res = new Wiz::HTTP::Response;
    $res->init;
    if (!$req) { $res->code(404); }
    elsif ($req->error) {
        write_request_error($req, $res);
    }
    else {
        hook($req, $res);
        $res->complement;
    }
    return $res;
}

sub write_error {
    $SERVER->log->error(shift);
}

sub write_request_error {
    my ($req, $res) = @_;
    $res->code($req->error_code || 403);
    write_error($req->error . ':' . $req->client_host);
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


