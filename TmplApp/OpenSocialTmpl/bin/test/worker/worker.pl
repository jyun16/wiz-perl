#!/usr/bin/perl

use strict;

use Wiz::Web::Framework::BatchBase;

sub main {
    my $c = get_context;
    my $worker = $c->worker('Sample');
    $worker->work;
    return 0;
}

exit main;
