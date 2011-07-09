#!/usr/bin/perl

use strict;
use warnings;

use lib '../../lib';

use Wiz::Test qw(no_plan);

BEGIN{ chtestdir; use_ok('TestPackage', qw(:const1 :sub1)); };

is(KEY1_1, 1, 'Export a constant number with an export name');
is(KEY1_2, 'value1', 'Export a constant string with an export name');

is(func1, 'Function no.1', 'Export a sub with an export name 1');
is(func2, 'Function no.2', 'Export a sub with an export name 2');

exit(0);
