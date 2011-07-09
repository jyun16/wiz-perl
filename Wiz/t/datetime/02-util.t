#!/usr/bin/perl

use lib qw(../../lib ./lib ../lib ./t/datetime/lib ./datetime/lib);
use DateTime;
use Wiz::DateTime;
use Wiz::DateTime::Util;
use DateTimeTest qw/no_plan/;

chtestdir;

run_compare evaldt => 'output';

__END__
=== $d->sec2hour(3600)
--- evaldt : $d->sec2hour(3600)
--- output : $_ = 1

=== $d->sec2hour(3500)
--- evaldt : $d->sec2hour(3500)
--- output : $_ = 0

=== $d->sec2hour(5200)
--- evaldt : $d->sec2hour(5200)
--- output : $_ = 1

=== $d->sec2hour(5250)
--- evaldt : $d->sec2hour(5250)
--- output : $_ = 1

=== $d->sec2hour(5450, upunit => 0.5)
--- evaldt : $d->sec2hour(5450, upunit => 0.5)
--- output : $_ = "2.0"

=== $d->sec2hour(5450, upunit => 0.25)
--- evaldt : $d->sec2hour(5450, upunit => 0.25)
--- output : $_ = 1.75

=== $d->sec2hour(5250, offunit => 0)
--- evaldt : $d->sec2hour(5250, offunit => 0)
--- output : $_ = 1

=== $d->sec2hour(5250, upunit => 0)
--- evaldt : $d->sec2hour(5250, upunit => 0)
--- output : $_ = 2

=== $d->sec2hour(5250, offunit => 0.25)
--- evaldt : $d->sec2hour(5250, offunit => 0.25)
--- output : $_ = "1.25"

=== $d->sec2hour(5150)
--- evaldt : $d->sec2hour(5150)
--- output : $_ = 1

=== $d->sec2hour(5150, upunit => 0.5)
--- evaldt : $d->sec2hour(5150, upunit => 0.5)
--- output : $_ = 1.5

=== $d->sec2hour(5150, upunit => 0.25)
--- evaldt : $d->sec2hour(5150, upunit => 0.25)
--- output : $_ = "1.50"

=== $d->sec2hour(5150, offunit => 0.5)
--- evaldt : $d->sec2hour(5150, offunit => 0.5)
--- output : $_ = "1.0"

=== $d->sec2hour(5150, offunit => 0.25)
--- evaldt : $d->sec2hour(5150, offunit => 0.25)
--- output : $_ = 1.25

=== sec2hour(3600)
--- evaldt : Wiz::DateTime::Util::sec2hour(3600)
--- output : $_ = 1

=== $d->sec2hour() # 19:35:50
--- evaldt : $d->sec2hour
--- output : $_ = 19

=== $d->sec2hour(upunit => 0.5) # 19:35:50 
--- evaldt : $d->sec2hour(upunit => 0.5)
--- output : $_ = "20.0"
