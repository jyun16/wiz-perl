package Wiz::Web::Framework::Controller::API;

=head1 NAME

Wiz::Web::Framework::Controller::API

=head1 VERSION

version 1.0

=cut

our $VERSION = '1.0';

=head1 SYNOPSIS

Create file to contain the following data name is "api.pdat" into the application config directory.

 {
     allow   => {
         'api/userid'  => [
             '192.168.0.1/24'
         ],
     },
 },

The key "allow" exists for allowed host to acccess this api.
"api/userid" is path to api(ex http://hogehoge.hoge/api/userid).
"192.168.0.1/24" is ip address allowed to access the api.

* Sample controller

 package XXXXX::Controller::API;

 use base qw(
 Catalyst::Controller::Wiz::API
 );
 
 sub userid {
     my $self = shift;
     my ($c) = @_;
 
     my $data = {
         userid  => 'USERID',
     };
 
     $self->json($c, $data);
 }

If you access to http://xxxxx/api/userid, you can get floowing data.

 {
     "userid": "USERID"
 }

=cut

use JSON::Syck;
use Net::IP::CMatch;

use Catalyst::Wiz::API::Error qw(:all);

use Wiz::Noose;
use Wiz::Util::Hash qw(hash_anchor_alias);

extends qw(Wiz::Web::Framework::Controller);

sub __begin {
    my $self = shift;
    my ($c) = @_;
    my $conf = hash_anchor_alias($c->app_conf("api"));
    my $allow = $conf->{$self->ourv('ALLOW_CONF_NAME') || 'allow'};
    unless (
        ($self->ourv('ALLOW_LOGINED_USER') && $c->logined) or
        (@{$allow->{$c->req->path}} and match_ip($c->req->address, @{$allow->{$c->req->path}}))
    ) {
        $self->_error($c);
    }
}

sub _error {
    my $self = shift;
    my ($c) = @_;
    my $data = {};
    set_error($data, INVALID_ACCESS);
    my $log = $c->applog('error');
    if (defined $log) {
        $log->error(
            sprintf "invalid access to api (%s from %s)",
            $c->req->path,
            $c->req->address
        );
    }
    $c->req->action(undef);
    $c->detach('json', [ $data ]);
}

sub json {
    my $self = shift;
    my ($c, $data) = @_;
    $c->res->content_type("application/json");
    $c->res->body(JSON::Syck::Dump($data));
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
