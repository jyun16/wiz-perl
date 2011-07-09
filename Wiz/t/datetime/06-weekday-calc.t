#!/usr/bin/perl

use lib qw(../../lib ./lib ../lib ./t/datetime/lib ./datetime/lib);
use DateTime;
use Wiz::DateTime;
use Wiz::DateTime::Definition;
use DateTimeTest qw/no_plan/;

chtestdir;

run_is evaldt => 'output';

__END__
=== weekday calc self 2007/11/28 += 10 Weekday
--- evaldt : $d->set_date_definition('jp'); $d += Wiz::DateTime::Unit::WEEKDAY * 10; $d->ymd('/');
--- output : '2007/12/12';

=== weekday calc 2007/11/28 + 10 Weekday
--- evaldt : $d->set_date_definition('jp'); my $d2 = $d + Wiz::DateTime::Unit::WEEKDAY * 10; $d2->ymd('/');
--- output : '2007/12/12';

=== weekday calc
--- evaldt : $d->set_date_definition('jp'); my $d2 = $d + Wiz::DateTime::Unit::WEEKDAY * 10; $d->ymd('/');
--- output : '2007/11/28';

=== weekday calc  2007/11/28 + 22 Weekday
--- evaldt : $d->set_date_definition('jp'); my $d2 = $d + Wiz::DateTime::Unit::WEEKDAY * 22; $d2->ymd('/');
--- output : '2007/12/31';

=== weekday calc
--- evaldt : $d->set_date_definition('jp'); my $d2 = $d + Wiz::DateTime::Unit::WEEKDAY * 27; $d2->ymd('/');
--- output : '2008/01/08';

=== weekday calc std
--- evaldt : $d->set_date_definition('jp'); my $d2 = $d + Wiz::DateTime::Unit::WEEKDAY * 22 + YEAR; $d2->ymd('/');
--- output : '2008/12/31';

=== weekday calc std self 2007/11/28 += 10 Weekday
--- evaldt : $d->set_date_definition('standard'); $d += Wiz::DateTime::Unit::WEEKDAY * 10; $d->ymd('/');
--- output : '2007/12/12';

=== weekday calc std 2007/11/28 + 10 Weekday
--- evaldt : $d->set_date_definition('standard'); my $d2 = $d + Wiz::DateTime::Unit::WEEKDAY * 10; $d2->ymd('/');
--- output : '2007/12/12';

=== weekday calc std
--- evaldt : $d->set_date_definition('standard'); my $d2 = $d + Wiz::DateTime::Unit::WEEKDAY * 10; $d->ymd('/');
--- output : '2007/11/28';

=== weekday calc std 2007/11/28 + 22 Weekday
--- evaldt : $d->set_date_definition('standard'); my $d2 = $d + Wiz::DateTime::Unit::WEEKDAY * 22; $d2->ymd('/');
--- output : '2007/12/28';

=== weekday calc std
--- evaldt : $d->set_date_definition('standard'); my $d2 = $d + Wiz::DateTime::Unit::WEEKDAY * 27; $d2->ymd('/');
--- output : '2008/01/04';

=== weekday calc std
--- evaldt : $d->set_date_definition('standard'); my $d2 = $d + Wiz::DateTime::Unit::WEEKDAY * 22 + YEAR; $d2->ymd('/');
--- output : '2008/12/28';

=== weekday calc self 2007/11/28 += 10 Weekday
--- evaldt : $d->set_date_definition('jp+cn'); $d += Wiz::DateTime::Unit::WEEKDAY * 10; $d->ymd('/');
--- output : '2007/12/12';

=== weekday calc 2007/11/28 + 10 Weekday
--- evaldt : $d->set_date_definition('jp+cn'); my $d2 = $d + Wiz::DateTime::Unit::WEEKDAY * 10; $d2->ymd('/');
--- output : '2007/12/12';

=== weekday calc
--- evaldt : $d->set_date_definition('jp+cn'); my $d2 = $d + Wiz::DateTime::Unit::WEEKDAY * 10; $d->ymd('/');
--- output : '2007/11/28';

=== weekday calc  2007/11/28 + 22 Weekday
--- evaldt : $d->set_date_definition('jp+cn'); my $d2 = $d + Wiz::DateTime::Unit::WEEKDAY * 22; $d2->ymd('/');
--- output : '2008/01/02';

=== weekday calc
--- evaldt : $d->set_date_definition('jp+cn'); my $d2 = $d + Wiz::DateTime::Unit::WEEKDAY * 27; $d2->ymd('/');
--- output : '2008/01/09';

=== weekday calc std
--- evaldt : $d->set_date_definition('jp+cn'); my $d2 = $d + Wiz::DateTime::Unit::WEEKDAY * 22 + YEAR; $d2->ymd('/');
--- output : '2009/01/02';
