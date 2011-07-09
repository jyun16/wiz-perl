package Wiz::Web::Framework::Controller::MultiDelete;

=head1 NAME

Wiz::Web::Framework::Controller::MultiDelete

=head1 VERSION

version 1.0

=cut

our $VERSION = '1.0';

=head1 SYNOPSIS

=cut

use Wiz::Noose;

extends qw(Wiz::Web::Framework::Controller);

sub _index {
    my $self = shift;
    my ($c, $af, $p, $s) = @_;

    my $ids = $c->req->param($self->ourv('IDS_FIELD_NAME'));
    $ids eq '' and return;
    my @ids = split /,/, $ids;
    my $m = $self->_model($c, $af, $p, $s);
    $af->list_values([ $m->select({ -in => { id => \@ids } }) ]);
}

sub _execute_index {
    my $self = shift;
    my ($c, $af, $p, $s) = @_;

    my $ids = $c->req->param($self->ourv('IDS_FIELD_NAME'));
    my @ids = split /,/, $ids;
    $self->_execute($c, { -in => { id => \@ids } }, $af, $p, $s);
}

sub _execute {
    my $self = shift;
    my ($c, $param, $af, $p, $s) = @_;

    my $m = $self->_model($c, $af, $p, $s);
    $m->delete($param);
    $m->commit;
}

sub _model {
    my $self = shift;
    my ($c, $af, $p, $s) = @_;
    return $c->model($self->ourv('MODEL'));
}

sub _before_index {}
sub _after_index {}
sub _before_execute_index {}
sub _after_execute_index {}
sub _finish_redirect_dest {
    my $self = shift;
    my ($c, $session) = @_;
    $session->{finish_redirect_dest} ? $session->{finish_redirect_dest} : 'finish';
}

sub index {
    my $self = shift;
    my ($c) = @_;
    my $method = $c->req->method;
    if ($method eq 'GET' and $self->ourv('USE_TOKEN')) { $c->embed_token; }
    my $af = $c->autoform([$self->ourv('AUTOFORM', '@')], undef, { language => $c->language });
    my $p = $c->req->params;
    my $s =  $self->_session($c);
    if ($method eq 'GET') {
        $self->ourv('USE_TOKEN') and $c->embed_token;
        $self->_before_index($c, $af, $p, $s);
        $self->_index($c, $af, $p, $s);
        $self->_after_index($c, $af, $p, $s);
        $c->stash->{f} = $af;
    }
    elsif ($method eq 'POST') {
        $self->_before_execute_index($c, $af, $p, $s);
        $self->_execute_index($c, $af, $p, $s);
        $self->_after_execute_index($c, $af, $p, $s);
        my @dest = $self->_finish_redirect_dest($c, $self->_session($c));
        $self->_remove_session($c);
        $c->redirect(@dest);
    }
}

sub finish {
    my $self = shift;
    my ($c) = @_;
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
