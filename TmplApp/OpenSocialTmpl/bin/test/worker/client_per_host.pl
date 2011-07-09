#!/usr/bin/perl

use strict;

use Wiz::Constant qw(:common);
use Wiz::Web::Framework::BatchBase;

sub main {
    my $c = get_context;
    my $worker = $c->worker('Sample');
    $worker->per_host(TRUE);
    $worker->register(test => 'TEST');
    return 0;
}

exit main;
