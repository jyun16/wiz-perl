#!/usr/bin/perl

use strict;

use lib 'lib';

use Wiz::Test qw(no_plan);
use Wiz::Dumper;
use Wiz::Util::PDS;

sub main {
    load_pds('Hoge', 'data');
    wd $Hoge::common;
    return 0;
}

exit main;
