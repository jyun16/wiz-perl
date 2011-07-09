#!/usr/bin/perl

use lib qw(../lib);

use Wiz::Test qw(no_plan);
use Wiz::Util qw(:all);

sub main {
    what_your_name_test();
    return 0;
}

sub what_your_name_test {
    my $hoge = 'HOGE';
    my @hoge = ();
    my %hoge = ();
    is what_your_name($hoge), '$hoge';
    is what_your_name(\@hoge), '@hoge';
    is what_your_name(\%hoge), '%hoge';
    is what_your_name_in_func($hoge), '$hoge';
    is what_your_name_in_func(\%hoge), '%hoge';
}

sub what_your_name_in_func {
    what_your_name(shift, 1);
}

exit main;
