package Wiz::Web::Framework::Controller::Show;

=head1 NAME

Wiz::Web::Framework::Controller::Show

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
    my $m = $self->_model($c, $af, $p, $s);
    my $pkey = $m->ourv('PRIMARY_KEY');
    $af->params($self->_execute($c, $af, $p, $s));
}

sub _execute {
    my $self = shift;
    my ($c, $af, $p, $s) = @_;
    my $m = $self->_model($c, $af, $p, $s);
    my $param = $self->_create_search_param($c, $af, $m);
    $self->_append_search_param($c, $param, $m, $af);
    my $show_method = $self->ourv('SHOW_METHOD') || 'getone';
    return $m->$show_method($p);
}

*_create_search_param = 'Wiz::Web::Framework::Controller::List::_create_search_param';
sub _append_search_param {}

sub _model {
    my $self = shift;
    my ($c, $af, $p, $s) = @_;
    return $c->slave_model($self->ourv('MODEL'));
}

sub _before_index {}
sub _after_index {}

sub index {
    my $self = shift;
    my ($c) = @_;
    my $af = $c->autoform([$self->ourv('AUTOFORM', '@')], undef, { language => $c->language });
    $af->mode('show');
    my $p = $c->req->params;
    my $s = $self->_session($c);
    $self->_before_index($c, $af, $p, $s);
    $self->_index($c, $af, $p, $s);
    $self->_after_index($c, $af, $p, $s);
    my $stash = $c->stash;
    $stash->{f} = $af;
    $stash->{s} = $s;

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
