#!/usr/bin/perl

use strict;
use warnings;

use lib qw(../../../lib);

use Wiz::Util::System qw(:all);

sub main {
    my $lock_file = '../lock/test.pid';
    check_multiple_execute($lock_file) or return 1;
    sleep 2;
    unlink $lock_file; 
    return 0;
}

exit main;
