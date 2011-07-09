#!/usr/bin/perl

use strict;

use Wiz::Constant qw(:common);
use Wiz::Web::Framework::BatchBase;

sub main {
    my $c = get_context(exclusive => [qw(controllers log message session_controller auth tt autoform memcached)]);
    my $worker = $c->worker('Sample');
    $worker->per_host(TRUE);
    $worker->work;
    return 0;
}

exit main;
