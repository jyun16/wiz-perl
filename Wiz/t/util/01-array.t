#!/usr/bin/perl

use strict;

use lib qw(../../lib);

use Wiz::Test qw(no_plan);
use Wiz::Dumper;
use Wiz::Constant qw(:common);
use Wiz::Util::Array qw(:all);

chtestdir;

sub main {
    array_split_test();
    array_sum_test();
    array_max_test();
    array_min_test();
    array_equals_test();
    array_round_robin_test();
    array_delete_test();
    array_random_test();
#    array_random_with_priority_test();
    array_chomp_test();
    array_trim_test();
    array_head_trim_test();
    array_tail_trim_test();
    array_included_test();
    array_all_pattern_test();
    return 0;
}

sub array_split_test {
    my @a1 = ('a'..'g');
    my ($a1, $a2) = array_split(\@a1, 3);
    is_deeply($a1, [qw(a b c)], q|array_split(\@a1, 3) - 1|);
    is_deeply($a2, [qw(d e f g)], q|array_split(\@a1, 3) - 2|);
}

sub array_sum_test {
    my @a = (0..9);
    is(array_sum(@a), 45, q|array_sum(@a)|);
}

sub array_max_test {
    my @a = (0..5, reverse 6..9);
    is(array_max(@a), 9, q|array_max(@a)|);
}

sub array_min_test {
    my @a = (0..9);
    is(array_min(@a), 0, q|array_min(@a)|);
}

sub array_equals_test {
    my @a1 = (0..9, 'a'..'g');
    my @a2 = (0..9, 'a'..'g');
    my @a3 = ('a'..'g');
    ok(array_equals(\@a1, \@a2), 'array_equals(\@a1, \@a2)');
    ok(!array_equals(\@a1, \@a3), 'array_equals(\@a1, \@a3)');
}

sub array_round_robin_test {
    my @a = (1..3);
    is_deeply(array_round_robin(\@a),
        [[1],[2],[1,2],[3],[1,3],[2,3],[1,2,3]],
        q|array_round_robin(\@a)|);
}

sub array_delete_test {
    my @a = (0..9);
    is_deeply([ array_delete(@a, 5) ], [ (0..4, 6..9) ], q|array_delete(@a, 5)|);
    is_deeply([ array_delete(\@a, 5) ], [ (0..4, 6..9) ], q|array_delete(\@a, 5)|);
}

sub array_random_test {
    my @a = (0..9);
    has_array(\@a, [ array_random(@a) ], q|array_random(@a)|);
}

sub array_random_with_priority_test {
    my @a = (0..2);
    for (0..10) {
        wd array_random_with_priority(\@a, [ 1, 10, 10 ]);
    }
}

sub array_chomp_test {
    my @a = ("hoge\n", "\nfuga\r\n");
    is_deeply([ array_chomp(@a) ], ["hoge", "\nfuga"], q|array_chomp(@a)|);
    is_deeply([ array_chomp(\@a) ], ["hoge", "\nfuga"], q|array_chomp(\@a)|);
    is_deeply(\@a, ["hoge", "\nfuga"], q|@a after array_chomp(\@a)|);
}

sub array_trim_test {
    my @a = ('  hoge  ', "\t  fuga \t\t");
    is_deeply([ array_trim(@a) ], [qw(hoge fuga)], q|array_trim(@a)|);
    is_deeply([ array_trim(\@a) ], [qw(hoge fuga)], q|array_trim(\@a)|);
    is_deeply(\@a, [qw(hoge fuga)], q|@a after array_trim(\@a)|);
}

sub array_head_trim_test {
    my @a = ('  hoge  ', "\t  fuga \t\t");
    is_deeply([ array_head_trim(@a) ], ["hoge  ", "fuga \t\t"], q|array_head_trim(@a)|);
    is_deeply([ array_head_trim(\@a) ], ["hoge  ", "fuga \t\t"], q|array_head_trim(\@a)|);
    is_deeply(\@a, ["hoge  ", "fuga \t\t"], q|@a after array_head_trim(\@a)|);
}

sub array_tail_trim_test {
    my @a = ('  hoge  ', "\t  fuga \t\t");
    is_deeply([ array_tail_trim(@a) ], ["  hoge", "\t  fuga"], q|array_tail_trim(@a)|);
    is_deeply([ array_tail_trim(\@a) ], ["  hoge", "\t  fuga"], q|array_tail_trim(\@a)|);
    is_deeply(\@a, ["  hoge", "\t  fuga"], q|@a after array_tail_trim(\@a)|);
}

sub array_included_test {
    my @a = qw(hoge fuga foo bar);
    is array_included(\@a, 'fuga'), TRUE, q|array_included(@a, 'fuga')|;
    is array_included(\@a, 'x'), FALSE, q|array_included(@a, 'fuga')|;
    is array_included(\@a, [ qw(fuga foo) ]), TRUE, q|array_included(\@a, [ qw(fuga foo) ])|;
    is array_included(\@a, [ qw(fuga x) ]), FALSE, q|array_included(\@a, [ qw(fuga x) ])|;
}

sub array_all_pattern_test {
    my @a = (0..3);
    my $res = array_all_pattern(@a);
    is @$res, 24, q|array_all_pattern(0..3)|;
}

exit main;
