#!/usr/bin/perl

use lib qw(../lib);

package Dummy;

use Wiz qw/ourv/;

our $HOGE = "HOGE";
our @HOGE = (qw/H O G E/);
our %HOGE = (qw/HOGE FUGA/);

package main;

use Wiz::Test qw(no_plan);

use lib qw(../lib);

use Wiz qw(:all);

chtestdir;

my %test_data = (
    hoge    => 'HOGE',
    fuga    => 'FUGA',
    foo     => 'FOO',
);

my $conf_path = 'conf/base.pdat';

is_deeply(\%test_data, get_hash_args(%test_data), 'get_hash_args: hash');
is_deeply(\%test_data, get_hash_args(\%test_data), 'get_hash_args: hash reference');
is_deeply(\%test_data, get_hash_args(_conf => $conf_path), 'get_hash_args: file');
is_deeply(
    {
        xxx => 'XXX', yyy => 'YYY', %test_data
    },
    get_hash_args(
        xxx => 'XXX', yyy => 'YYY', _conf => $conf_path, 
    ),
'get_hash_args: merge');

is(Dummy->ourv("HOGE"), "HOGE", 'ourv');
is(Dummy->ourv("HOGE", '$'), "HOGE", 'ourv $');
is_deeply [Dummy->ourv(qw/HOGE @/)], [qw/H O G E/], "ourv @";
is_deeply {Dummy->ourv(qw/HOGE %/)}, {HOGE => 'FUGA'}, "ourv %"
