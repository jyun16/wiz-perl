#!/usr/bin/perl

use strict;
use warnings;

use lib '../../lib';

use Wiz::Test qw(no_plan);

BEGIN{ chtestdir; use_ok('TestPackage', qw(KEY1_1)); };

is(KEY1_1, 1, 'Export a constant number with an export name');

exit(0);
