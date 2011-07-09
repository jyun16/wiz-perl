#!/usr/bin/perl

use lib qw(../lib);

use Data::Dumper;
use Wiz::Test qw(no_plan);
use Wiz::IO::Capture qw(:capture_target);

sub main {
    stdout_test();
    stderr_test();
    warn_test();
    all_test();
    return 0;
}

sub stdout_test {
    my $cap = new Wiz::IO::Capture(target => CAPTURE_TARGET_STDOUT);
    print "[STDOUT] 1\n";
    $cap->start;
    print "[STDOUT] 2 - captured\n";
    $cap->stop;
    print "[STDOUT] 3\n";
    is $cap->stdout, "[STDOUT] 2 - captured\n", 'capture stdout';
}

sub stderr_test {
    my $cap = new Wiz::IO::Capture(target => CAPTURE_TARGET_STDERR);
    print STDERR "[STDERR] 1\n";
    $cap->start;
    print STDERR "[STDERR] 2 - captured\n";
    $cap->stop;
    print STDERR "[STDERR] 3\n";
    is $cap->stderr, "[STDERR] 2 - captured\n", 'capture stderr';
}

sub warn_test {
    my $cap = new Wiz::IO::Capture(target => CAPTURE_TARGET_WARN);
    warn "[WARN] 1";
    $cap->start;
    warn "[WARN] 2 - captured";
    $cap->stop;
    warn "[WARN] 3";
    like $cap->warn, qr/WARN/, 'capture warn';
}

sub all_test {
    my $cap = new Wiz::IO::Capture(target => CAPTURE_TARGET_STDOUT | CAPTURE_TARGET_STDERR | CAPTURE_TARGET_WARN);
    print "[STDOUT] 1\n";
    print STDERR "[STDERR] 1\n";
    warn "[WARN] 1";
    $cap->start;
    print "[STDOUT] 2 - captured\n";
    print STDERR "[STDERR] 2 - captured\n";
    warn "[WARN] 2 - captured";
    $cap->stop;
    print "[STDOUT] 3\n";
    print STDERR "[STDERR] 3\n";
    warn "[WARN] 3";
    is $cap->stdout, "[STDOUT] 2 - captured\n", 'capture all(stdout)';
    is $cap->stderr, "[STDERR] 2 - captured\n", 'capture all(stderr)';
    like $cap->warn, qr/WARN/, 'capture all(warn)';
}

exit main;
