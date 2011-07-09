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
=== _parse TAI64N
--- evaldt : $d->_parse('TAI64N', '@40000000474ec9e20eeb4260');
--- output : { epoch => 1196345816, nanosecond => 2503 }

=== _parse TAI64N set_parse_format
--- evaldt : $d->set_parse_format('TAI64N'); $d->_parse('@40000000474ec9e20eeb4260');
--- output : { epoch => 1196345816, nanosecond => 2503 }

=== parse GENERAL YYYY/M/D
--- evaldt : $d->parse("2007/1/1"); $d->to_string(Wiz::DateTime::Formatter::GENERAL_DETAIL);
--- output : '2007-01-01 00:00:00.0 Asia/Tokyo'

=== parse GENERAL YYYY/M/D H:M:S
--- evaldt : $d->parse("2007/1/1 1:2:3"); $d->to_string(Wiz::DateTime::Formatter::GENERAL_DETAIL);
--- output : '2007-01-01 01:02:03.0 Asia/Tokyo'

=== parse ACCESS_LOG
--- evaldt : $d->parse('ACCESS_LOG', '17/Feb/2006:11:24:41 +0900'); $d->to_string(Wiz::DateTime::Formatter::GENERAL_DETAIL);
--- output: '2006-02-17 11:24:41.0 +0900'

=== parse ACCESS_LOG -1200
--- evaldt : $d->parse('ACCESS_LOG', '17/Feb/2006:11:24:41 -1200'); $d->to_string(Wiz::DateTime::Formatter::GENERAL_DETAIL);
--- output: '2006-02-17 11:24:41.0 -1200'

=== parse ERROR_LOG
--- evaldt : $d->parse('ERROR_LOG','Fri Feb 17 11:24:41 2006'); $d->to_string(Wiz::DateTime::Formatter::GENERAL_DETAIL);
--- output: '2006-02-17 11:24:41.0 Asia/Tokyo'

=== parse RFC822
--- evaldt : $d->parse('RFC822', 'Fri, 17-Feb-2006 11:24:41 +0900'); $d->to_string(Wiz::DateTime::Formatter::GENERAL_DETAIL);
--- output: '2006-02-17 11:24:41.0 +0900'

=== parse RFC822 -1200
--- evaldt : $d->parse('RFC822', 'Fri, 17-Feb-2006 11:24:41 -1200'); $d->to_string(Wiz::DateTime::Formatter::GENERAL_DETAIL);
--- output: '2006-02-17 11:24:41.0 -1200'

=== parse RFC822
--- evaldt : $d->parse('RFC822', 'Fri, 17-Feb-06 11:24:41 +0900'); $d->to_string(Wiz::DateTime::Formatter::GENERAL_DETAIL);
--- output: '2006-02-17 11:24:41.0 +0900'

=== parse RFC822 -1200
--- evaldt : $d->parse('RFC822', 'Fri, 17-Feb-06 11:24:41 -1200'); $d->to_string(Wiz::DateTime::Formatter::GENERAL_DETAIL);
--- output: '2006-02-17 11:24:41.0 -1200'

=== parse RFC850
--- evaldt : $d->parse('RFC850', 'Fri, 17-Feb-06 11:24:41 JST'); $d->to_string(Wiz::DateTime::Formatter::GENERAL_DETAIL);
--- output: '2006-02-17 11:24:41.0 Asia/Tokyo'

=== parse RFC850 ROK
--- evaldt : $d->parse('RFC850', 'Fri, 17-Feb-06 11:24:41 ROK'); $d->to_string(Wiz::DateTime::Formatter::GENERAL_DETAIL);
--- output: '2006-02-17 11:24:41.0 Asia/Seoul'

=== parse RFC850
--- evaldt : $d->parse('RFC850', 'Fri, 17-Feb-2006 11:24:41 JST'); $d->to_string(Wiz::DateTime::Formatter::GENERAL_DETAIL);
--- output: '2006-02-17 11:24:41.0 Asia/Tokyo'

=== parse RFC850 ROK
--- evaldt : $d->parse('RFC850', 'Fri, 17-Feb-2006 11:24:41 ROK'); $d->to_string(Wiz::DateTime::Formatter::GENERAL_DETAIL);
--- output: '2006-02-17 11:24:41.0 Asia/Seoul'

=== parse W3C 1
--- evaldt : $d->parse('W3C', '2006-02-17T11:40:10.45+09:00'); $d->to_string(Wiz::DateTime::Formatter::GENERAL_DETAIL);
--- output: '2006-02-17 11:40:10.45 +0900'

=== parse W3C 1 -12:00
--- evaldt : $d->parse('W3C', '2006-02-17T11:40:10.45-12:00'); $d->to_string(Wiz::DateTime::Formatter::GENERAL_DETAIL);
--- output: '2006-02-17 11:40:10.45 -1200'

=== parse W3C 2
--- evaldt : $d->parse('W3C', '2006-02-17T11:40:10+09:00'); $d->to_string(Wiz::DateTime::Formatter::GENERAL_DETAIL);
--- output : '2006-02-17 11:40:10.0 +0900'

=== parse W3C 2 -12:00
--- evaldt : $d->parse('W3C', '2006-02-17T11:40:10-12:00'); $d->to_string(Wiz::DateTime::Formatter::GENERAL_DETAIL);
--- output : '2006-02-17 11:40:10.0 -1200'

=== parse W3C 3
--- evaldt : $d->parse('W3C', '2006-02-17T11:40+09:00'); $d->to_string(Wiz::DateTime::Formatter::GENERAL_DETAIL);
--- output : '2006-02-17 11:40:00.0 +0900'

=== parse W3C 3 -12:00
--- evaldt : $d->parse('W3C', '2006-02-17T11:40-12:00'); $d->to_string(Wiz::DateTime::Formatter::GENERAL_DETAIL);
--- output : '2006-02-17 11:40:00.0 -1200'

=== parse W3C 4
--- evaldt : $d->parse('W3C', '2007-02-04'); $d->to_string(Wiz::DateTime::Formatter::GENERAL_DETAIL);
--- output : '2007-02-04 00:00:00.0 Asia/Tokyo'

=== parse W3C 5
--- evaldt : $d->parse('W3C', '2007-01'); $d->to_string(Wiz::DateTime::Formatter::GENERAL_DETAIL);
--- output : '2007-01-01 00:00:00.0 Asia/Tokyo'

=== parse DATE
--- evaldt : $d->parse('DATE', 'Fri Feb 17 11:24:41 JST 2006'); $d->to_string(Wiz::DateTime::Formatter::GENERAL_DETAIL);
--- output : '2006-02-17 11:24:41.0 Asia/Tokyo'

=== parse DATE ROK
--- evaldt : $d->parse('DATE', 'Fri Feb 17 11:24:41 ROK 2006'); $d->to_string(Wiz::DateTime::Formatter::GENERAL_DETAIL);
--- output : '2006-02-17 11:24:41.0 Asia/Seoul'

=== parse MYSQL
--- evaldt : $d->parse('MYSQL', '2007-10-23 20:21:20'); $d->to_string(Wiz::DateTime::Formatter::GENERAL_DETAIL);
--- output : '2007-10-23 20:21:20.0 Asia/Tokyo'

=== parse DB2
--- evaldt : $d->parse('DB2', '2007-10-23 20.21.20'); $d->to_string(Wiz::DateTime::Formatter::GENERAL_DETAIL);
--- output : '2007-10-23 20:21:20.0 Asia/Tokyo'

=== parse DB2 microsec
--- evaldt : $d->parse('DB2', '2007-10-23 20.21.20.10234'); $d->to_string(Wiz::DateTime::Formatter::GENERAL_DETAIL);
--- output : '2007-10-23 20:21:20.10234 Asia/Tokyo'

=== parse APACHE_DIRINDEX
--- evaldt : $d->parse('APACHE_DIRINDEX', '23-Oct-2007 20:21:20'); $d->to_string(Wiz::DateTime::Formatter::GENERAL_DETAIL);
--- output : '2007-10-23 20:21:20.0 Asia/Tokyo'

=== parse TIME
--- evaldt : $d->parse('TIME', '20:21:20'); $d->to_string(Wiz::DateTime::Formatter::GENERAL);
--- output : '1970-01-01 20:21:20'

=== parse TIME_DETAIL
--- evaldt : $d->parse('TIME_DETAIL', '20:21:20.100'); $d->to_string(Wiz::DateTime::Formatter::GENERAL_DETAIL);
--- output : '1970-01-01 20:21:20.100 Asia/Tokyo'

=== parse TRADITIONAL
--- evaldt : $d->parse('TRADITIONAL', 'June 11, 2007');  $d->to_string(Wiz::DateTime::Formatter::GENERAL_DETAIL);
--- output : '2007-06-11 00:00:00.0 Asia/Tokyo'

=== parse MILITARY
--- evaldt : $d->parse('MILITARY', '11 June 2007');  $d->to_string(Wiz::DateTime::Formatter::GENERAL_DETAIL);
--- output : '2007-06-11 00:00:00.0 Asia/Tokyo'
