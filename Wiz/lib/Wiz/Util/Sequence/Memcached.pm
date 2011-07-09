package Wiz::Util::Sequence::Memcached;

use strict;

=head1 NAME

Wiz::Util::Sequence::Memcached

=head1 VERSION

version 1.0

=cut

our $VERSION = '1.0';

=head1 SYNOPSIS

 my $s = new Wiz::Util::Sequence::Memcached(
     servers     => [qw(localhost:13131)],
     key         => 'seq_test',
     auto_extend => 300,
 );
 
 my $seq = $s->get;

Very simple.

You remove sequence with to get sequence, use `use get_and_remove`.

 my $seq = $s->get_and_remove;

You can use `generate` when you don't use auto_extend.

 $s->generate(1, 200);

The method create sequence 1 .. 200.

All method can take sequence key name.

 my $foo_seq = $s->get('foo');
 my $bar_seq = $s->get('bar');

=head1 DESCRIPTION

=cut

=head1 CONSTRUCTOR

=cut 

use Cache::Memcached::Fast;

use Wiz::Noose;

has 'servers' => (is => 'rw');
has 'key' => (is => 'rw');
has 'memd' => (is => 'rw');
has 'auto_extend' => (is => 'rw', default => 0);
has 'check_limit' => (is => 'rw', default => 0);

sub BUILD {
    my $self = shift;
    $self->memd(Cache::Memcached::Fast->new({'servers' => $self->servers}));
}

sub generate {
    my $self = shift;
    my ($min, $max, $key) = @_;
    $key ||= $self->key;
    my $memd = $self->memd;
    my $cur_max = $memd->get("${key}_max") || 0;
    $cur_max and $cur_max >= $max and return;
    $min <= $cur_max and die '$min < $cur_max';
    for ($min .. $max) { $memd->set($key . ++$cur_max, $_); }
    $memd->set("${key}_max", $cur_max);
    defined $memd->get("${key}_cur") or $memd->set("${key}_cur", 0);
}

sub cur {
    my $self = shift;
    my ($key) = @_;
    $key ||= $self->key;
    $self->memd->get("${key}_cur");
}

sub max {
    my $self = shift;
    my ($key) = @_;
    $key ||= $self->key;
    $self->memd->get("${key}_max");
}

sub fetch {
    my $self = shift;
    my ($id, $key) = @_;
    $key ||= $self->key;
    $self->memd->get("${key}$id");
}

sub get {
    my $self = shift;
    my ($key) = @_;
    $key ||= $self->key;
    my $memd = $self->memd;
    if ($self->auto_extend and $memd->get("${key}_cur") == $memd->get("${key}_max")) {
        my $min = $memd->get("${key}_cur") + 1;
        $self->generate($min, $min + $self->auto_extend - 1, $key);
    }
    elsif ($self->check_limit and $memd->get("${key}_cur") == $memd->get("${key}_max")) {
        return undef;
    }
    $memd->get($key . $memd->incr("${key}_cur"));
}

sub get_and_remove {
    my $self = shift;
    my ($key) = @_;
    $key ||= $self->key;
    my $memd = $self->memd;
    if ($self->auto_extend and $memd->get("${key}_cur") == $memd->get("${key}_max")) {
        my $min = $memd->get("${key}_cur") + 1;
        $self->generate($min, $min + $self->auto_extend - 1, $key);
    }
    elsif ($self->check_limit and $memd->get("${key}_cur") == $memd->get("${key}_max")) {
        return undef;
    }
    my $cur = $memd->incr("${key}_cur");
    my $ret = $memd->get($key . $cur);
    $memd->delete($key . $cur);
    return $ret;
}

=head1 AUTHOR

Junichiro NAKAMURA, C<< <jyun16@gmail.com> >>

=head1 COPYRIGHT & LICENSE

Copyright 2010 The Wiz Project. All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice,
self list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright
notice, self list of conditions and the following disclaimer in the
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
We welcome anyone who cooperates with us in developing self software.

We'll invite you to self project's member.

=cut

1;

__END__
