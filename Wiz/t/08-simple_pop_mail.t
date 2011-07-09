#!/usr/bin/perl

use strict;
use warnings;

use Wiz::Test qw(no_plan);

use lib qw(../lib);

use Data::Dumper;

use Wiz::SimplePopMail;

chtestdir;

is 1, 1;

#exit main();

sub main {
    my $pop = new Wiz::SimplePopMail(
        pop         => "7pp.jp",
        user        => "7pp",
        password    => "7ppdesuyo",
        auth_mode   => 'PASS',
    );

    warn Dumper $pop->pop;

    return 0;
}
