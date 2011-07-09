package Wiz::Command::Benchmark;

=head1 NAME

Wiz::Command::Benchmark

=head1 VERSION

version 1.0

=head1 SYNOPSIe strict;

=head2 Sample script - benchmark.pl

 #!/usr/bin/perl

 use strict; 

 use Wiz::Command::Benchmark qw(main);
 
 sub b_hoge {
     # benchmark code.
 }
 
 sub b_fuga {
     # benchmark code.
 }
 
 main;

When subroutine name is b_$NAME, auto execute it as benchmark script.

=head2 execute

Execute all benchmark script, default 10 times.

 ./benchmark.pl

If you execute 10000 times,

 ./benchmark.pl -n 10000

Execute all benchmark script only once.

 ./benchmark.pl -s

If you execute benchmark b_hoge only,

 ./benchmark.pl hoge

=cut

our $VERSION = '1.0';

use Benchmark qw(cmpthese);
use Class::Inspector;

use Wiz::Args::Simple;
use Wiz::ConstantExporter [qw(
main
)];

my $NUM = 10;
my @FUNCS;
my $PKG;

sub main {
    $PKG = (caller)[0];
    @FUNCS = grep {/^b_/} @{Class::Inspector->functions($PKG)};
    my $args = init_args();
    if ($args->{s}) { execute(); }
    else { bench(); }
}

sub bench {
    my %target = ();
    for (@FUNCS) { $target{$_} = \&{"${PKG}::$_"}; }
    cmpthese $NUM, \%target;
}

sub execute {
    no strict 'refs';
    for (@FUNCS) { &{"${PKG}::$_"}(); }
}

sub init_args {
    my $args = Wiz::Args::Simple::getopts(<<EOS);
n(num):
s(single)
h(help)
EOS
    $args->{n} and $NUM = $args->{n};
    if ($args->{no_opt_args}) {
        @FUNCS = map { "b_$_" } @{$args->{no_opt_args}};
    }
    return $args;
}

sub usage {
    use FindBin;
    my ($opt, $desc) = qw(%-16s %-30s);
    print "$FindBin::Script [ OPTIONS ] [ TARGET FUNCTION ]\n\n";
    printf " $opt $desc\n", '-s, --single', 'No bench';
    printf " $opt $desc\n", '-n, --num', 'Number of executions';
    printf " $opt $desc\n", '-h, --help', 'Usage';
}

=head1 AUTHOR

Junichiro NAKAMURA C<< <jyun16@google.com> >>

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

