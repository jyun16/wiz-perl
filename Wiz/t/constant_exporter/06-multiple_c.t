#!/usr/bin/perl

use strict;
use warnings;

use lib '../../lib';

use Wiz::Test qw(no_plan);

BEGIN{ chtestdir; use_ok('TestPackage', qw(:const1 :const)); };

is(KEY1_1, 1, 'Export a constant number with an export name');
is(KEY1_2, 'value1', 'Export a constant string with an export name');

is(KEY2_1, 2, 'Export a constant number without an export name');
is(KEY2_2, 'value2', 'Export a constant string without an export name');

exit(0);
