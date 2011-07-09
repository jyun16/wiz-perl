#!/usr/bin/perl

use lib qw(../../lib ./lib ../lib ./t/datetime/lib ./datetime/lib);
use DateTime;
use Wiz::DateTime;
use Wiz::DateTime::Formatter qw/:all/;
use DateTimeTest qw/no_plan/;
use DateTime::TimeZone::Local;
use Wiz::DateTime::Unit qw/:all/;

chtestdir;

run_compare evaldt => 'output';

__END__
=== delta year
--- evaldt : ($d - $d2)->year
--- output : $_ = 0

=== delta month
--- evaldt : ($d - $d2)->month
--- output : $_ = 0

=== delta day
--- evaldt : ($d - $d2)->day
--- output : $_ = -1

=== delta year
--- evaldt : ($d3 - $d)->year_only
--- output : $_ = 4

=== delta month
--- evaldt : ($d3 - $d)->month_only
--- output : $_ = -10

=== delta day
--- evaldt : ($d3 - $d)->day_only
--- output : $_ = -3
