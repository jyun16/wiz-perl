#!/usr/bin/perl

use strict;
use warnings;

use lib '../../lib';

use Wiz::Test qw(no_plan);

BEGIN{ chtestdir; use_ok('TestPackage', qw(:sub1 :sub)); };

is(func1, 'Function no.1', 'Export a sub with an export name 1');
is(func2, 'Function no.2', 'Export a sub with an export name 2');
is(func3, 'Function no.3', 'Export a sub without an export name 1');
is(func4, 'Function no.4', 'Export a sub without an export name 2');

exit(0);
