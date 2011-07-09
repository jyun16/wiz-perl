#!/usr/bin/perl

use lib qw(../../lib ./lib ../lib ./t/datetime/lib ./datetime/lib);
use DateTime;
use Wiz::DateTime;
use DateTimeTest qw/no_plan/;
use Wiz::DateTime::Unit qw/:all/;

chtestdir;

run_compare evaldt => 'output';

__END__
=== _parse birthrange 20 30
--- evaldt : [map $_->to_string("%Y-%m-%d"), $d->birthdate_range(20, 30)]
--- output : ['1976-11-29', '1987-11-28']

=== _parse birthrange 20
--- evaldt : [map $_->to_string("%Y-%m-%d"), $d->birthdate_range(20)]
--- output : ['1986-11-29', '1987-11-28']

=== _parse asian birthrange 20 30
--- evaldt : [map $_->to_string("%Y-%m-%d"), $d->asian_birthdate_range(20, 30)]
--- output : ['1977-11-29', '1988-11-28']

=== _parse asian birthrange 20
--- evaldt : [map $_->to_string("%Y-%m-%d"), $d->asian_birthdate_range(20)]
--- output : ['1987-11-29', '1988-11-28']

=== _parse birthrange 20 at 2/29
--- evaldt
$d->set(year => 2008, month => 2, day => 29);
[map $_->to_string("%Y-%m-%d"), $d->birthdate_range(20)]
--- output : ['1987-03-01', '1988-02-29']

=== _parse birthrange 15 at 2/29
--- evaldt
$d->set(year => 2008, month => 2, day => 29);
[map $_->to_string("%Y-%m-%d"), $d->birthdate_range(15)]
--- output : ['1992-03-01', '1993-02-28']

