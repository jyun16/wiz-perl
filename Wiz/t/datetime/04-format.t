#!/usr/bin/perl

use lib qw(../../lib ./lib ../lib ./t/datetime/lib ./datetime/lib);
use DateTime;
use Wiz::DateTime;
use Wiz::DateTime::Formatter qw/:all/;
use DateTimeTest qw/no_plan/;
use Wiz::DateTime::Unit qw/:all/;

chtestdir;

run_compare evaldt => 'output';

__END__
=== strftime GENERAL
--- evaldt : $d->strftime(Wiz::DateTime::Formatter::GENERAL)
--- output : '2007-11-28 19:35:50'

=== strftime DATE
--- evaldt : $d->strftime(Wiz::DateTime::Formatter::DATE)
--- output : 'Wed Nov 28 19:35:50 JST 2007'

=== strftime ACCESS_LOG
--- evaldt : $d->strftime(Wiz::DateTime::Formatter::ACCESS_LOG)
--- output : '28/Nov/2007:19:35:50 +0900'

=== strftime ERROR_LOG
--- evaldt : $d->strftime(Wiz::DateTime::Formatter::ERROR_LOG)
--- output : 'Wed Nov 28 19:35:50 2007'

=== strftime APACHE_DIRINDEX
--- evaldt : $d->strftime(Wiz::DateTime::Formatter::APACHE_DIRINDEX)
--- output : '28-Nov-2007 19:35:50'

=== strftime MYSQL
--- evaldt : $d->strftime(Wiz::DateTime::Formatter::MYSQL)
--- output : '2007-11-28 19:35:50'

=== strftime DB2
--- evaldt : $d->strftime(Wiz::DateTime::Formatter::DB2)
--- output : '2007-11-28 19.35.50'

=== strftime RFC822
--- evaldt : $d->strftime(Wiz::DateTime::Formatter::RFC822)
--- output : 'Wed, 28-Nov-2007 19:35:50 +0900'

=== strftime RFC850
--- evaldt : $d->strftime(Wiz::DateTime::Formatter::RFC850)
--- output : 'Wed, 28-Nov-2007 19:35:50 JST'

=== strftime W3C
--- evaldt : $d->strftime(Wiz::DateTime::Formatter::W3C)
--- output : '2007-11-28T19:35:50+09:00'

=== strftime TIME
--- evaldt : $d->strftime(Wiz::DateTime::Formatter::TIME)
--- output : '19:35:50'

=== strftime HTTP
--- evaldt : $d->strftime(Wiz::DateTime::Formatter::HTTP)
--- output : 'Wed, 28 Nov 2007 10:35:50 GMT'

=== strftime TIME_DETAIL
--- evaldt
$d->strftime(Wiz::DateTime::Formatter::TIME_DETAIL);

--- output : '19:35:50.0'

=== strftime TAI64N
--- evaldt
$d = Wiz::DateTime->now(time_zone => 'Asia/Tokyo');
$d->set_epoch(1196345816);
$d->set(nanosecond => 2503);
$d->strftime(Wiz::DateTime::Formatter::TAI64N);
--- output: '@40000000474ec9e2000009c7';
