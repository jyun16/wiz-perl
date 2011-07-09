package Wiz::Web::Framework::Server::Nginx;

use strict;

=head1 NAME

Wiz::Web::Framework::Server::Nginx

=head1 SYNOPSIS

=head2 nginx.conf simple

 http {
     perl_modules        /var/www-work/TmplApp/lib;
     perl_require        TmplApp.pm;
     server {
         listen          8080;
         location / {
             set     $WIZ_APP_ROOT '/var/www-work/TmplApp/lib;';
             set     $WIZ_APP_ENV 'test';
             perl    TmplApp::handler;
         }
     }
 }

=head2 nginx.conf with self proxy

 http {
     perl_modules        /var/www-work/TmplApp/lib;
     perl_require        TmplApp.pm;
     server {
         listen          80;
         proxy_redirect          off;
         proxy_connect_timeout   5;
         proxy_send_timeout      5;
         proxy_read_timeout      10;
         proxy_buffering         off;
         proxy_set_header        Host                $host;
         proxy_set_header        Server-Port         $server_port;
         proxy_set_header        X-Forwarded-Host    $host:$server_port;
         proxy_set_header        X-Forwarded-For     $proxy_add_x_forwarded_for;
         location ~ '\.(?:.*)$'  {
             root    /var/www-work/TmplApp/root;
             index   index.html index.htm;
         }
         location /  {
             proxy_pass http://localhost:8080;
         }
     }
     server {
         listen          8080;
         location / {
             set     $WIZ_APP_ROOT '/var/www-work/TmplApp/lib;';
             set     $WIZ_APP_ENV 'test';
             perl    TmplApp::handler;
         }
     }
 }

=head1 VERSION

version 1.0

=cut

use File::Basename;

use Wiz qw(import_parent_symbols);
use Wiz::HTTPD qw(is_static);
use Wiz::HTTPD::Nginx;
use Wiz::Web::Framework::ContextBase;
use Wiz::Web::Framework::Context;

our $VERSION = '1.0';
our %CONTEXT_BASE = ();

no warnings 'uninitialized';

BEGIN {
    import_parent_symbols('Wiz::HTTPD::Nginx');
};

sub init {
    %CONTEXT_BASE and return;
    my ($req) = @_;
    no strict 'refs';
    my $app_root = $req->engine_handler->variable('WIZ_APP_ROOT');
    my $app_name = basename $app_root;
    my $conf = \%{"${app_name}::CONFIG"};
    my $cb = new Wiz::Web::Framework::ContextBase(
        app_name    => $app_name,
        app_root    => $app_root,
        app_base    => '/',
        conf        => $conf,
    );
    $CONTEXT_BASE{'/'} = $cb;
    my $controllers = $cb->controllers;
    for (keys %$controllers) { eval "use $controllers->{$_}"; }
}

sub get_context_base {
    my ($req) = @_;
    init($req);
    $req->path =~ m#^(/[^/]*)#;
    my $cb = $CONTEXT_BASE{$1};
    $cb ||= $CONTEXT_BASE{'/'};
    return $cb;
}

sub hook {
    my ($req, $res) = @_;
    my $cb = get_context_base($req);
    my $path = $req->path;
    eval {
        my $c = bless $cb, 'Wiz::Web::Framework::Context';
        $c->init($req, $res);
        if (is_static($req)) {
            eval {
                $cb->read_static_file($c, $path);
            };
            if ($@) { write_error($req->engine_handler, $@); }
        }
        else {
            $cb->execute_controller($c, $path);
        }
    };
    if ($@) {
        write_error($req->engine_handler, $@);
        $res->code(500);
    }
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


