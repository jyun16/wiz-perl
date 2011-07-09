#!/usr/bin/perl

use strict;
use warnings;

use lib qw(lib ../../lib);

use Wiz::Test qw(no_plan);
use TestPackage qw(:from_hash);

chtestdir;

is FROM_HASH_1, 'from_hash_1';
is FROM_HASH_2, 'from_hash_2';
