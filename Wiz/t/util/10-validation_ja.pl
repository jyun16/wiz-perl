#!/usr/bin/perl

use strict;
use warnings;

use lib qw(../../lib);

use Wiz::Constant qw(:common);
use Wiz::Test qw(no_plan);
use Wiz::Util::Validation::JA qw(:all);

chtestdir;

sub main{
    warn is_katakana('フフー');
    return 0;
}

exit main;
