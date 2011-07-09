#!/usr/bin/perl

use strict;
use warnings;

use lib qw(../../lib);

use Wiz::Test qw(no_plan);
use Wiz::Constant qw(:common);
use Wiz::Log qw(:all);
use Wiz::Log::Controller;

chtestdir;

my $logs_dir = './logs';

sub main {
    my $lc = create_log_controller();
    debug($lc->log('log1'), $lc->log('log1')->{conf}{path});
    debug($lc->log('log2'), $lc->log('log2')->{conf}{path});
    info($lc->log('log1'), $lc->log('log1')->{conf}{path});
    info($lc->log('log2'), $lc->log('log2')->{conf}{path});
    return 0;
}

sub create_log_controller {
    return new Wiz::Log::Controller({
        level   => DEBUG,
        logs    => {
            log1    => {
                path    => "$logs_dir/log1.log",
            },
            log2    => {
                path    => "$logs_dir/log2.log",
            },
        }
    });
}

sub debug {
    my ($log, $file_path) = @_;

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
    my ($log, $file_path) = @_;

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
