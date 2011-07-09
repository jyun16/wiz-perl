#!/usr/bin/perl

use strict;
use warnings;

use lib qw(../lib);

use Wiz::Test qw(no_plan);
use Wiz::Constant qw(:common);
use Wiz::Log qw(:all);

chtestdir;

my $file_path = 'logs/log_test.log';

sub main {
    my $log = create_log();
    debug($log);
    info($log);
    return 0;
}

sub create_log {
    -f $file_path and unlink $file_path;
    my $log = new Wiz::Log(
        level       => DEBUG,
        path        => $file_path,
        stdout      => 1,
        stderr      => {
            level   => INFO,
        }
    );
}

sub debug {
    my ($log) = @_;

    $log->fatal('fatal test');
    file_contains_at_line($file_path, -1, qr|\Q[ FATAL ] fatal test\E|);
    $log->error('error test');
    file_contains_at_line($file_path, -1, qr|\Q[ ERROR ] error test\E|);
    $log->warn('warn test');
    file_contains_at_line($file_path, -1, qr|\Q[ WARN ] warn test\E|);
    $log->info('info test');
    file_contains_at_line($file_path, -1, qr|\Q[ INFO ] info test\E|);
    $log->logging('logging test');
    file_contains_at_line($file_path, -1, qr|\Q[ LOGGING ] logging test\E|);
    $log->debug('debug test');
    file_contains_at_line($file_path, -1, qr|\Q[ DEBUG ] debug test\E|);
}

sub info {
    my ($log) = @_;

    $log->level(INFO);
    $log->fatal('fatal test');
    file_contains_at_line($file_path, -1, qr|\Q[ FATAL ] fatal test\E|);
    $log->error('error test');
    file_contains_at_line($file_path, -1, qr|\Q[ ERROR ] error test\E|);
    $log->warn('warn test');
    file_contains_at_line($file_path, -1, qr|\Q[ WARN ] warn test\E|);
    $log->info('info test');
    file_contains_at_line($file_path, -1, qr|\Q[ INFO ] info test\E|);
    $log->logging('logging test');
    file_contains_at_line($file_path, -1, qr|\Q[ INFO ] info test\E|);
    $log->debug('debug test');
    file_contains_at_line($file_path, -1, qr|\Q[ INFO ] info test\E|);
}

exit main;
