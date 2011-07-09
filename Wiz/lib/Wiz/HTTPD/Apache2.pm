package Wiz::HTTPD::Apache2;

use strict;

=head1 NAME

Wiz::HTTPD::Apache2

=head1 VERSION

version 1.0

=head1 MEMO

=cut

use Wiz qw(import_parent_symbols);
use Wiz::HTTPD qw(is_static host_name_with_port);
use Wiz::HTTPD::Apache::Base;

use Apache2::ServerUtil;

BEGIN {
    getppid == 1 or return;
    import_parent_symbols('Wiz::HTTPD::Apache::Base');
};

sub _create_request {
    my ($r) = @_;
    my $c = $r->connection;
    my $headers = $r->headers_in;
    my @http_headers = ();
    for (keys %$headers) { push @http_headers, ($_, $headers->{$_}); }
    my $contents;
    my $error;
    if ($r->method eq 'POST') {
        my $data = read_post_data($r);
        if (defined $data->{data}) { $contents = $data->{data}; }
        elsif ($data->{error_message}) {
            $error->{message} = $data->{error_message};
            $error->{code} = $data->{error_code};
        }
    }
    my $req = new Wiz::HTTP::Request(
        $r->method,
        $r->uri,
        \@http_headers,
        $contents,
    );
    if ($error) { $req->error($error->{message}); $req->error_code($error->{code}); }
    if (
        $req->header('x-https-request') or
        $req->header('x-https-request') eq 'on' or
        $ENV{HTTPS} eq 'on'
    ) {
        $req->scheme('https');
    }
    else {
        $req->scheme('http');
    }
    my ($host, $port);
    if ($host = $req->header('x-forwarded-host')) {
        if ($host =~ /^(.+):(\d+)$/) { $host = $1; $port = $2; }
        else { $port = $req->scheme eq 'https' ? 443 : 80; }
    }
    else {
        $host = $headers->{host};
        $host =~ /([^:]*):*(?:\d*)/;
        $host = $1;
        $port = $r->get_server_port;
    }
    $host and $req->host($host);
    $req->port($port);
    $req->client_host($c->remote_host || $c->remote_ip);
    $req->complement;
    $req->path =~ m#^(/[^/]*)#;
    my $app_base = $Wiz::HTTPD::Apache2::APP_NAMES->{$1} ? $1 : '';
    $app_base eq '/' and $app_base = '';
    $req->base(sprintf '%s://%s%s/', $req->scheme, host_name_with_port($req), $app_base);
    return $req;
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


