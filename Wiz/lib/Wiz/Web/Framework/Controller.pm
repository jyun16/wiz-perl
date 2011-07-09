package Wiz::Web::Framework::Controller;

=head1 NAME

Wiz::Web::Framework::Controller

=head1 VERSION

version 1.0

=cut

our $VERSION = '1.0';

use Carp;
use Data::Dumper;

use Wiz::Noose;
use Wiz qw(ourv);
use Wiz::Constant qw(:common);
use Wiz::Util::String qw(camel2normal);

sub __begin {}

sub _pager {
    my $self = shift;
    my ($c, $af, $name) = @_;
    my $pager = $af->pager($name);
    $pager->now_page($c->req->param($pager->now_page_param_name));
    $pager->per_page($c->req->param($pager->per_page_param_name));
    return $pager;
}

sub _sort {
    my $self = shift;
    my ($c, $af, $name) = @_;
    my $sort = $af->sort($name);
    my $p = $c->req->param($sort->sort_param_name) || join ',', $self->ourv('DEFAULT_SORT', '@');
    $sort->param($p);
    return $sort;
}

sub _calendar {
    my $self = shift;
    my ($c, $af, $name) = @_;
    return $af->calendar($name);
}

sub use_secure_token {
    my $self = shift;
    my ($c) = @_;
    ($c->conf->{use_secure_token} && $self->ourv('USE_TOKEN')) || FALSE;
}

sub token_error {
    my $self = shift;
    my ($c) = @_;
    my $log = $c->applog('token');
    if (defined $log) {
        local $Data::Dumper::Terse = 1;
        local $Data::Dumper::Indent = 1;
        $log->error(sprintf 'bad token: ip=%s; path=%s, params=%s',
            $c->req->address, $c->req->path, Dumper $c->req->params);
    }
    delete $c->stash->{$c->secure_token_name};
    $c->detach('/error', [ msg => 'token_error' ]);
}

sub _session {
    my $self = shift;
    my ($c, $params) = @_;
    my $session_label = $self->ourv('SESSION_LABEL') || 'default';
    my $session = $self->use_secure_token($c) ?
        ($c->token_session or $self->token_error($c)) : $c->session($session_label);
    my $sname = $self->ourv('SESSION_NAME');
    exists $session->{$sname} or $session->{$sname} = {};
    my $s = $session->{$sname};
    if (defined $params) {
        for (keys %$params) { $s->{$_} = $params->{$_}; }
    }
    return $s;
}

sub _u {
    my $self = shift;
    my ($c) = @_;
    return $c->u($self->ourv('AUTHZ_LABEL'), $self->ourv('SESSION_LABEL') || 'default');
}

sub _remove_session {
    my $self = shift;
    my ($c) = @_;
    my $session_label = $self->ourv('SESSION_LABEL') || 'default';
    my $sname = $self->ourv('SESSION_NAME');
    $self->use_secure_token($c) ?
        $c->remove_token_session : delete $c->session($session_label)->{$sname};
}

sub _clear_session {
    my $self = shift;
    my ($c) = @_;
    my $session_label = $self->ourv('SESSION_LABEL') || 'default';
    my $sname = $self->ourv('SESSION_NAME');
    my $s = $c->session($session_label)->{$sname};
    for (keys %$s) { delete $s->{$_}; }
}

sub _next_dispatch {
    my $self = shift;
    my ($c, $next) = @_;
    defined $c->stash->{root_args} or return $next;
    return (join '/', @{$c->stash->{root_args}}, $next);
}

sub _complement_dest {
    my $self = shift;
    my ($c, $dest) = @_;
    $dest =~ s/\$userid/$c->u->userid/eg;
    return $dest;
}

=head1 AUTHOR

Junichiro NAKAMURA, C<< <jyun16@gmail.com> >>

[Modify] Toshihiro MORIMOTO C<< dealforest.net@gmail.com >>

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
