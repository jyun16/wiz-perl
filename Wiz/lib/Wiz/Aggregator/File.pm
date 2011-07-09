package Wiz::Aggregator::File;

use strict;
use warnings;

=head1 NAME

Wiz::Aggregator::File - 

=head1 VERSION

version 1.0

=cut

our $VERSION = '1.0';

=head1 SYNOPSIS

=head1 DESCRIPTION

=head2 

=cut

use Carp qw(confess);
use IO::Handle;

use Wiz::Noose;
use Wiz::Constant qw(:common);
use Wiz::Util::File qw(get_absolute_path);
use Wiz::Util::Hash qw(args2hash);

extends qw(Wiz::Aggregator);

has tmp_dir             => (is => 'rw', default => '/tmp');
has sep_prefix          => (is => 'rw', default => '_sep');
has result_prefix       => (is => 'rw', default => '_result');
has output              => (is => 'rw');

sub BUILD {
    my $self = shift;
    my $args = args2hash @_;
    $self->SUPER::BUILD($args);
    for (qw/tmp_dir output/) { defined $args->{$_} and $self->$_(get_absolute_path($args->{$_})); }
    -d $self->tmp_dir or confess 'not find tmp_dir.';
    $self->tmp_dir($self->tmp_dir . ($self->tmp_dir =~ /\/$/ ? '' : '/'));
}

sub _before_job {
    my $self = shift;
    my ($id) = @_;

    my $input_file = $self->tmp_dir. $self->_key($self->sep_prefix, $id);
    open my $fo, '<', $input_file or confess $!;

    my $output_file = $self->tmp_dir. $self->_key($self->result_prefix, $id);
    open my $fw, '>', $output_file or confess $!;

    [$fo, $fw];
}

sub _after_job {
    my $self = shift;
    my ($handles) = @_;
    ref $handles eq 'ARRAY' or return;
    for (@$handles) { $_->close; }
}

sub _before_summarize {
    my $self = shift;
    my @handles;
    for (1..$self->process) {
        my $file = $self->tmp_dir. $self->_key($self->result_prefix, $_);
        open my $fo, '<', $file or confess $!;
        push @handles, $fo;
    }
    return \@handles;
}

sub _after_summarize {
    my $self = shift;
    my ($handles, $result) = @_;
    for (@$handles) { $_->close; }
    if ($self->output) {
        open my $fw, '>', $self->output or confess $!;
        $fw->print($result);
        $fw->close;
    }
}

sub cleanup { 
    my $self = shift;
    for (1..$self->process) {
        for my $method (qw/sep_prefix result_prefix/) {
            unlink $self->tmp_dir. $self->_key($self->$method, $_);
        }
    }
}

sub failed {
    my $self = shift;
    my ($label) = @_;
}

sub succeed {
    my $self = shift;
    my ($label) = @_;
}

=head1 AUTHOR

Toshihiro MORIMOTO C<< dealforest.net@gmail.com >>

=head1 COPYRIGHT & LICENSE

Copyright 2008 The Wiz Project. All rights reserved.

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
