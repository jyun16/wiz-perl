package Wiz::Web::Framework::Server::Apache2;

use strict;

=head1 NAME

Wiz::Web::Framework::Server::Apache2

=head1 APACHE CONFIG

 PerlSwitches -I/var/work/perl/labo/server/httpd/framework/TmplApp/lib
 PerlModule TmplApp
 <Location />
 SetHandler perl-script
 PerlResponseHandler TmplApp
 </Location>

=head1 VERSION

version 1.0

=cut

use Wiz qw(import_parent_symbols);
use Wiz::HTTPD qw(is_static);
use Wiz::HTTPD::Apache2;
use Wiz::Web::Framework::ContextBase;
use Wiz::Web::Framework::Context;

our $VERSION = '1.0';
our %CONTEXT_BASE;

BEGIN {
    getppid == 1 or return;
    import_parent_symbols('Wiz::HTTPD::Apache2');
};

sub get_app_root {
    my ($app_name) = @_;
    (my $app_path = $app_name) =~ s/::/\//;
    $INC{"$app_path.pm"} =~ m#(.*$app_name)/lib/(?:.*)#;
    return $1;
}

sub create_context_base {
    my ($args, $conf) = @_;
    return new Wiz::Web::Framework::ContextBase(
        app_name    => $args->{app_name},
        app_root    => $args->{app_root},
        app_base    => $args->{app_base},
        conf        => $conf,
    );
}

sub context_package_name {
    'Wiz::Web::Framework::Context';
}

sub init {
    %CONTEXT_BASE and return;
    my $app_names = $Wiz::HTTPD::Apache2::APP_NAMES;
    no strict 'refs';
    for (keys %$app_names) {
        my $app_name = $app_names->{$_};
        my $app_root = get_app_root($app_name);
        my $conf = \%{"${app_name}::CONFIG"};
        my $cb = create_context_base({
            app_name    => $app_name,
            app_root    => $app_root,
            app_base    => $_,
        }, $conf);
        $CONTEXT_BASE{$_} = $cb;
        my $controllers = $cb->controllers;
        for (keys %$controllers) { eval "use $controllers->{$_}"; }
    }
}

sub get_context_base {
    my ($path) = @_;
    init();
    $path =~ m#^(/[^/]*)#;
    my $cb = $CONTEXT_BASE{$1};
    $cb ||= $CONTEXT_BASE{'/'};
    return $cb;
}

{
    sub read_post_data {
        my $r = shift;
        my ($path, $trush) = split /\?/, $r->uri;
        my $cb = get_context_base($path);
        my $max_request_size =
            $cb->conf->{max_request_size} ||
            $Wiz::HTTPD::Apache::Base::MAX_REQUEST_SIZE;
        my $ret;
        my $buf = '';
        if ($Wiz::HTTPD::Apache::Base::MAX_REQUEST_SIZE) {
            while ($r->read($buf, $Wiz::HTTPD::Apache::Base::BUFFER_SIZE)) {
                $ret .= $buf;
                if (length $ret > $max_request_size) {
                    return { error_message => 'Over max request size', error_code => 403 };
                }
            }
        }
        else {
            while ($r->read($buf, $Wiz::HTTPD::Apache::Base::BUFFER_SIZE)) {
                $ret .= $buf;
            }
        }
        return { data => $ret };
    }
    sub hook {
        my ($req, $res) = @_;
        my $cb = get_context_base($req->path);
        my $path = $req->path;
        eval {
            my $c = bless $cb, context_package_name;
            $c->init($req, $res);
            if (is_static($req)) {
                eval {
                    $cb->read_static_file($c, $path);
                };
                if ($@) { write_error($@); }
            }
            else {
                $cb->execute_controller($c, $path);
            }
        };
        if ($@) {
            warn $@;
            write_error($@);
            $res->code(500);
        }
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


