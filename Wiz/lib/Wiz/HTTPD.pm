package Wiz::HTTPD;

=head1 NAME

Wiz::HTTPD

=head1 VERSION

version 1.0

=head1 MEMO

=cut

use AnyEvent;
use AnyEvent::Socket;
use IO::Handle;
use Errno qw(EAGAIN EINTR);
use AnyEvent::Util qw(WSAEWOULDBLOCK);
use URI;
use HTTP::Parser;
use HTTP::Request::Params;
use File::MimeInfo;
use Proc::Fork;
use Time::HiRes qw(usleep);

use Wiz::Noose;
use Wiz::Constant qw(:common);
use Wiz::Util::String qw(trim_sp);
use Wiz::Util::Hash qw(args2hash);
use Wiz::Util::System qw(hostname);
use Wiz::HTTP::Request;
use Wiz::HTTP::Response;
use Wiz::ModuleReload;
use Wiz::Log qw(:all);
use Wiz::ConstantExporter [qw(
is_static
host_name_with_port
)];

our $VERSION = '1.0';

has 'app_name' => (is => 'rw');
has 'host' => (is => 'rw'); 
has 'port' => (is => 'rw', default => 8080); 
has 'httpd' => (is => 'rw'); 
has 'http_version' => (is => 'rw', default => 1.1); 
has 'hook' => (is => 'rw', default => sub {}); 
has 'max_request_size' => (is => 'rw');
has 'module_reload' => (is => 'rw');
has 'debug' => (is => 'rw', default => FALSE);
has 'log_conf' => (is => 'rw');
has 'log' => (is => 'rw');
has 'read_sleep' => (is => 'rw', default => 200);

sub BUILD {
    my $self = shift;
    my ($args) = @_;
    if ($self->log_conf) {
        $self->log(new Wiz::Log($self->log_conf));
    }
    $self->hook(sub {
        my ($req, $res) = @_;
        my $path = $req->path;
        $path =~ s/^\///;
        if (is_static($req)) {
            $self->read_static_file($path, $res);
        }
        else {
            $path eq '' and $path = 'root';
            no strict 'refs';
            "$args->{app_name}::$path"->($req, $res);
        }
    });
}

sub write_log {
    my $self = shift;
    my ($lv, $msg) = @_;
    $self->log or return;
    $self->log->write($lv, $msg);
}

sub __read_data {
    my $self = shift;
    my ($sock) = @_;
    my $ret;
    while (defined(my $line = <$sock>)) {
        $ret .= $line;
        if (length $ret > $self->max_request_size) {
            return { code => 403, log_msg => 'Over max request size' };
        }
        # TODO dounika sinakya
        usleep $self->read_sleep;
    }
    return { data => $ret };
}

sub listen {
    my $self = shift;
    my $cv = AnyEvent->condvar;
    tcp_server $self->host, $self->port, sub {
        my ($sock, $host, $port) = @_;
        autoflush $sock 1;
        $self->write_log(DEBUG, "Client connected: $host($port)");
        my $sock_watcher; $sock_watcher = AnyEvent->io(
            fh      => $sock,
            poll    => 'r',
            cb      => sub {
                my $req_data = $self->__read_data($sock);
                undef $sock_watcher;
                my $res;
                if ($req_data->{code}) {
                    $req_data->{host} = $host;
                    $res = $self->_create_error_response($req_data);
                }
                else {
                    $res = $self->_create_response(
                        $self->_create_request($req_data->{data}, {
                            client_host => $host,
                            client_port => $port,
                        })
                    );
                }
                $res->header('Content-Length' => length $res->content);
                my $res_data = 'HTTP/' . $self->http_version . ' ' . $res->as_string;
                $self->_write_response($sock, $res_data, length $res_data);
                undef $sock_watcher;
            },
        );
    }, sub {
        my ($fh, $host, $port) = @_;
        $host eq '0.0.0.0' and $host = hostname;
        $self->write_log(INFO, "Wiz::HTTP server is listening on $host:$port");
    };
    if ($self->module_reload) {
        my $cv = AnyEvent->condvar;
        my $time_watcher = AnyEvent->timer(
            interval    => $self->module_reload,
            cb => sub {
                if (my $target = Wiz::ModuleReload::module_reload) {
                    for (keys %$target) {
                        $self->write_log(INFO, "Reloaded: $_($target->{$_})");
                    }
                }
            },
        );
        $cv->wait;
    }
    else {
        $cv->recv;
    }
}

sub read_static_file {
    my $self = shift;
    my ($path, $res) = @_;
    my $f;
    unless (open $f, '<', $path) {
        $res->code(404);
        $self->write_log('error', "$path($!)");
        return;
    }
    my $data;
    while (<$f>) { $data .= $_; }
    close $f;
    $res->content_type(mimetype($path));
    $res->content($data);
    return;
}

sub _read_data {
    my $self = shift;
    my ($sock) = @_;
    my $ret;
    if ($self->max_request_size) {
        my $buf;
        while (sysread $sock, $buf, 24) {
            $ret .= $buf;
            if (length $ret > $self->max_request_size) {
                return { code => 403, log_msg => 'Over max request size' };
            }
        }
    }
    else {
        while (<$sock>) { $ret.= $_; }
    }
    return { data => $ret };
}

sub _create_request {
    my $self = shift;
    my ($req_data, $info) = @_;
    my $parser = new HTTP::Parser(request => 1);
    if ($parser->add($req_data) == 0) {
        my $req = $parser->request;
        bless $req, 'Wiz::HTTP::Request';
        $req->scheme('http');
        my ($host, $port);
        if ($req->header('x-forwarded-host')) {
            my @x_forwarded_host = split /,/, $req->header('x-forwarded-host');
            $host = trim_sp(shift @x_forwarded_host);
            if ($host =~ /^([^:]*):?(\d*)$/) { $host = $1; $port = $2; }
            else { $port = $req->scheme eq 'https' ? 443 : 80; }
        }
        else {
            $host = $req->header('host');
            $host =~ /([^:]*):*(\d*)/;
            $host = $1;
            $port = $2;
        }
        $req->host($host);
        $req->port($port || 80);
        my $base = $req->scheme . "://$host";
        if ($req->port != 80 && $req->port != 443) { $base .= ":$port"; }
        $req->base("$base/");
        $self->write_log(DEBUG, "Request: " . $req->uri);
        $req->client_host($info->{client_host});
        $req->client_port($info->{client_port});
        $req->complement;
        return $req;
    }
    return undef;
}

sub _create_response {
    my $self = shift;
    my ($req) = @_;
    my $res = new HTTP::Response;
    unless ($req) { $res->code(404); return $res; }
    bless $res, 'Wiz::HTTP::Response';
    $res->init;
    $self->hook->($req, $res, $self);
    $res->complement;
    return $res;
}

sub _create_error_response {
    my $self = shift;
    my $args = args2hash @_;
    $self->write_log('error', $args->{log_msg} . " (by $args->{host})");
    my $res = new HTTP::Response;
    $res->code($args->{code});
    return $res;
}

sub _write_response {
    my $self = shift;
    my ($sock, $res_data, $res_len, $offset) = @_;
    my $w_sock_watcher; $w_sock_watcher = AnyEvent->io(
        fh      => $sock,
        poll    => 'w',
        cb      => sub {
            defined $offset or $offset = 0;
            while (my $len = syswrite $sock, $res_data, $res_len, $offset) {
                $offset += $len;
                $offset == $res_len and last;
            }
            if ($! == EAGAIN && $offset != $res_len) {
                undef $w_sock_watcher;
                $self->_write_response($sock, $res_data, $res_len, $offset);
            }
            undef $w_sock_watcher;
        }
    );
}

sub is_static {
    my ($req) = @_;
    my $uri = new URI($req->uri);
    return $uri->path =~ /.*\..*/ ? 1 : 0;
}

sub host_name_with_port {
    my ($req) = @_;
    my $port = $req->port;
    my $ret = $req->host;
    if ($port and $port !~ /^(?:80|443)$/) { $ret .= ":$port"; }
    return $ret;
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


