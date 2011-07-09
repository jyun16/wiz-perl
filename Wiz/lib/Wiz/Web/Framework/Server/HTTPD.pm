package Wiz::Web::Framework::Server::HTTPD;

=head1 NAME

Wiz::Web::Framework::Server::HTTPD

=head1 VERSION

version 1.0

=cut

use Wiz::Noose;
use Wiz::Util::String qw(normal2camel);
use Wiz::Util::File qw(dirname filename);
use Wiz::Web::Framework::ContextBase;
use Wiz::Web::Framework::Context;
use Wiz::HTTPD qw(is_static);

extends qw(Wiz::HTTPD);

our $VERSION = '1.0';

sub create_context_base {
    my $self = shift;
    my ($args, $conf) = @_;
    return new Wiz::Web::Framework::ContextBase(
        app_name    => $args->{app_name},
        app_root    => $args->{app_root},
        app_base    => '/',
        conf        => $conf,
    );
}

sub context_package_name {
    'Wiz::Web::Framework::Context';
}

sub BUILD {
    my $self = shift;
    my ($args) = @_;
    no strict 'refs';
    my $conf = \%{"$args->{app_name}::CONFIG"};
    my $cb = $self->create_context_base($args, $conf);
    defined $conf->{max_request_size} and
        $self->max_request_size($conf->{max_request_size});
    my $controllers = $cb->controllers;
    for (keys %$controllers) { eval "use $controllers->{$_}"; }
    if ($self->log_conf) { $self->log(new Wiz::Log($self->log_conf)); }
    $self->hook(sub {
        my ($req, $res) = @_;
        eval {
            my $c = bless $cb, $self->context_package_name;
            $c->init($req, $res);
            my $path = $req->path;
            if (is_static($req)) {
                eval {
                    $cb->read_static_file($c, $path);
                };
                $@ and $self->write_log('error', $@);
            }
            else {
                $cb->execute_controller($c, $path);
            }
        };
        if ($@) {
            $self->write_log('fatal', $@);
            $res->code(500);
        }
    });
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


