#!/usr/bin/perl

use strict;

use File::Basename;
use FindBin;

sub main {
	my @target = grep !/mach/, (grep /site_perl/, @INC);
	my $target = $target[0];
	my $lib = dirname $FindBin::Bin;
	print `ln -s $lib/lib/Wiz.pm $target`;
	print `ln -s $lib/lib/Wiz $target`;
	return 0;
}

exit main;

