package Wiz::Util::Sequence;

use strict;

=head1 NAME

Wiz::Util::Sequence

=head1 VERSION

version 1.0

=cut

our $VERSION = '1.0';

=head1 SYNOPSIS

=head1 DESCRIPTION

my $seq = seq_memcached(['localhost:11112']);

Default key is 'seq' in memcached.
The following when you specify key.

my $seq1 = seq_memcached(['localhost:11112'], 'seq1');
my $seq2 = seq_memcached(['localhost:11112'], 'seq2');

my $seq = seq_tokyo_cabinet('/tmp/cab-seq-test.tch');

or

my $seq = seq_tokyo_cabinet('/tmp/cab-seq-test.tch', 'seq');

`seq_tokyo_cabinet` don't use transaction, so fast but not secure.
`seq_tokyo_cabinet_strict` use transaction.

my $seq = seq_tokyo_cabinet_strict('/tmp/cab-seq-test.tch', 'seq');

=cut

=head1 CONSTRUCTOR

=cut 

use Cache::Memcached::Fast;

use Wiz::Util::Array qw(args2array);
use Wiz::ConstantExporter [qw(
    seq_memcached
    seq_tokyo_cabinet
)];

sub seq_memcached {
    my ($servers, $key) = @_;
    $key ||= 'seq';
    my $memd = Cache::Memcached::Fast->new({'servers' => $servers});
    $memd->add($key, 0);
    $memd->incr($key);
}

sub seq_tokyo_cabinet {
    my ($cab_file, $key) = @_;
    use TokyoCabinet;
    $key ||= 'key';
    my $cab = new TokyoCabinet::HDB;
    $cab->open($cab_file, $cab->OWRITER | $cab->OCREAT);
    $cab->addint($key, 1);
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
