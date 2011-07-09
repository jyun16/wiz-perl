#!/usr/bin/perl

use strict;
use warnings;

use lib qw(../../lib);

use Cwd;

use Wiz::Test qw(no_plan);
use Wiz::Util::System qw(:all);

chtestdir;

$| = 1;

sub main {
    check_multiple_execute_test();
    return 0;
}

sub check_multiple_execute_test {
    my $lock_file = '../lock/test.pid';
    my $cmd_file = './check_multiple_execute.pl';

    my $cwd = cwd;
    chdir 'bin';
    chmod 0755, $cmd_file;

    my $pid = undef;
    if ($pid = fork) {
        sleep 1;
        `$cmd_file`;
        is($? >> 8, 1, 'check_multiple_execute fail');
        `$cmd_file`;
        is($? >> 8, 1, 'check_multiple_execute fail');
        wait;
    }
    elsif (defined $pid) {
        `$cmd_file`;
        is($? >> 8, 0, 'check_multiple_execute success');
    }
    else {
        die "can't open process $! $?";
    }

    chdir $cwd;
}

skip_confirm(2) and exit main;
