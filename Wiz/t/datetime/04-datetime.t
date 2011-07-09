#!/usr/bin/perl

use lib qw(../../lib ./lib ../lib ./t/datetime/lib ./datetime/lib);
use DateTime;
use Wiz::DateTime;
use Wiz::DateTime::Formatter qw/:all/;
use DateTimeTest qw/no_plan/;
use Wiz::DateTime::Unit qw/:all/;

chtestdir;

sub init {
    my $d = Wiz::DateTime->new();
    is ref $d, 'Wiz::DateTime', "create object";
}

sub to_string {
    my $d = Wiz::DateTime->new();
    my $dt = DateTime->now->set_time_zone('local');
    is $d->to_string, $dt->strftime("%Y-%m-%d %H:%M:%S"), 'to_string';
    is "$d", $dt->strftime("%Y-%m-%d %H:%M:%S"), 'overload';
    is ref $d->_dt, "DateTime", '_dt returns DateTime object';
}

sub set_epoch {
    my $d = Wiz::DateTime->new;
    my $t = time;
    my($sec, $min, $hour, $mday, $mon, $year) = (localtime $t)[0 .. 7];

    $year += 1900;
    $mon++;
    $d->set_epoch($t);
    is($d->to_string, sprintf("%04d-%02d-%02d %02d:%02d:%02d", $year, $mon, $mday, $hour, $min, $sec), "set_epoch");
    is $d->epoch, $t, "epoch";
}

sub clone {
    my $adt = Wiz::DateTime->today();
    my $clone = $adt->clone;
    ok((overload::StrVal($adt) ne overload::StrVal($clone) and $adt == $clone), "clone");
}


init();
to_string();
set_epoch();
clone();

run_compare input               => 'output';
run_compare unit                => 'output';
run_compare end                 => 'output';
run_compare nth_day_of_week     => 'output';
run_compare set_nth_day_of_week => 'output';
run_compare add                 => 'output';
run_compare evaldt              => 'output';

__END__
=== now
--- input  : Wiz::DateTime->now()->_dt;
--- output : DateTime->now(time_zone => 'local');

=== today
--- input  : Wiz::DateTime->today()->_dt;
--- output : DateTime->today(time_zone => 'local');

=== today is 00:00:00
--- input  : Wiz::DateTime->today()->hms(':');
--- output : "00:00:00";

=== set_today
--- input  : Wiz::DateTime->now()->set_today->_dt;
--- output : DateTime->today(time_zone => 'local');

=== set_now
--- input  : Wiz::DateTime->today()->set_now->_dt;
--- output : DateTime->now(time_zone => 'local');

=== is_today
--- input  : Wiz::DateTime->today()->is_today
--- output : 1

=== _to_dt_args
--- input to_dt_args
Wiz::DateTime->now,
{
   year   => 1, month => 1, hour => 1, minute => 1,
   second => 1, microsecond => 1, nanosecond => 1
}
--- output
{
   years   => 1, months => 1, hours => 1, minutes => 1,
   seconds => 1, microseconds => 1, nanoseconds => 1,
   end_of_month => 'limit',
}
=== _datetime_now
--- input : Wiz::DateTime->_datetime_now
--- output: DateTime->now(time_zone => 'local')

=== _datetime_today
--- input : Wiz::DateTime->_datetime_today
--- output: DateTime->today(time_zone => 'local')

=== _unit_name_year
--- unit     : Year
--- output: 'Wiz::DateTime::Unit::Year'

=== _unit_name_month
--- unit     : Month
--- output: 'Wiz::DateTime::Unit::Month'

=== _unit_name_weekday
--- unit  : Weekday
--- output: 'Wiz::DateTime::Unit::Weekday'

=== _unit_name_number
--- unit  : 100
--- output: undef

=== round_year
--- input : Wiz::DateTime->now->round("year")->_dt;
--- output : DateTime->now(time_zone => "local")->truncate(to => "year")

=== round_month
--- input : Wiz::DateTime->now->round("month")->_dt;
--- output : DateTime->now(time_zone => "local")->truncate(to => "month")

=== round_day
--- input : Wiz::DateTime->new->round("day")->_dt;
--- output : DateTime->now(time_zone => "local")->truncate(to => "day")

=== round_second
--- input : Wiz::DateTime->now->round("second")->_dt;
--- output : DateTime->now(time_zone => "local")->truncate(to => "second")

=== last_day_of_month
--- input last_day_of_month : 1
--- output: "2007-11-30"

=== end year
--- end : year
--- output: "2007-12-31 23:59:59"

=== end month
--- end : month
--- output: "2007-11-30 23:59:59"

=== end day
--- end : day
--- output: "2007-11-28 23:59:59"

=== end hour
--- end : hour
--- output: "2007-11-28 19:59:59"

=== end minute
--- end : minute
--- output: "2007-11-28 19:35:59"

=== nth_day_of_week 1, 1
--- nth_day_of_week : 1, 1
--- output: "2007-11-05"

=== nth_day_of_week 2, 1
--- nth_day_of_week : 2, 1
--- output: "2007-11-12"

=== nth_day_of_week 3, 1
--- nth_day_of_week : 3, 1
--- output: "2007-11-19"

=== nth_day_of_week 4, 1
--- nth_day_of_week : 4, 1
--- output: "2007-11-26"

=== nth_day_of_week 1, 4
--- nth_day_of_week : 1, 4
--- output: "2007-11-01"

=== nth_day_of_week 2, 4
--- nth_day_of_week : 2, 4
--- output: "2007-11-08"

=== nth_day_of_week 3, 4
--- nth_day_of_week : 3, 4
--- output: "2007-11-15"

=== nth_day_of_week 4, 4
--- nth_day_of_week : 4, 4
--- output: "2007-11-22"

=== nth_day_of_week 5, 4
--- nth_day_of_week : 5, 4
--- output: "2007-11-29"

=== set_nth_day_of_week 1, 1
--- set_nth_day_of_week : 1, 1
--- output: "2007-11-05"

=== set_nth_day_of_week 2, 1
--- set_nth_day_of_week : 2, 1
--- output: "2007-11-12"

=== set_nth_day_of_week 3, 1
--- set_nth_day_of_week : 3, 1
--- output: "2007-11-19"

=== set_nth_day_of_week 4, 1
--- set_nth_day_of_week : 4, 1
--- output: "2007-11-26"

=== set_nth_day_of_week 1, 4
--- set_nth_day_of_week : 1, 4
--- output: "2007-11-01"

=== set_nth_day_of_week 2, 4
--- set_nth_day_of_week : 2, 4
--- output: "2007-11-08"

=== set_nth_day_of_week 3, 4
--- set_nth_day_of_week : 3, 4
--- output: "2007-11-15"

=== set_nth_day_of_week 4, 4
--- set_nth_day_of_week : 4, 4
--- output: "2007-11-22"

=== set_nth_day_of_week 5, 4
--- set_nth_day_of_week : 5, 4
--- output: "2007-11-29"

=== add DAY * 2
--- evaldt: $d + DAY * 2
--- output: "2007-11-30 19:35:50"

=== add DAY * 10
--- evaldt: $d + DAY * 10;
--- output: "2007-12-08 19:35:50"

=== add MONTH
--- evaldt: $d + MONTH;
--- output: "2007-12-28 19:35:50"

=== add MONTH * 2
--- evaldt: $d + MONTH * 2
--- output: "2008-01-28 19:35:50"

=== add MONTH * 3
--- evaldt: $d + MONTH * 3
--- output: "2008-02-28 19:35:50"

=== add YEAR
--- evaldt: $d + YEAR
--- output: "2008-11-28 19:35:50"

=== add YEAR * 2
--- evaldt: $d + YEAR * 2
--- output: "2009-11-28 19:35:50"

=== subtract YEAR * 2
--- evaldt: $d -= YEAR * 2; $d
--- output: "2005-11-28 19:35:50"

=== calc YEAR * 2 + 3 * MONTH - 2 * YEAR
--- evaldt: $d + YEAR * 2 + 3 * MONTH - YEAR * 4 + DAY * 1
--- output: "2006-03-01 19:35:50"

=== calc leap year(2/29) -> next year(2/28)
--- evaldt: $d += 3 * MONTH; $d->set_last_day_of_month; $d += YEAR * 1; $d->ymd("-");
--- output: "2009-02-28"

=== calc next year(2/28) -> leap year(2/28)
                       2007-11-28
3 * MONTH + YEAR * 1   2009-02-28
$d->last_day_of_month  2009-02-29
- YEAR * 1             2008-02-28
--- evaldt
$d += (3 * MONTH + YEAR * 1);
($d->last_day_of_month - YEAR * 1)->ymd("-");
--- output: "2008-02-28"

=== calc delta
--- evaldt : ref( $d - $d2 )
--- output : "Wiz::DateTime::Delta"

=== calc gt ''
--- evaldt : $d > $d2
--- output : ''

=== calc gt 1
--- evaldt : $d2 > $d
--- output : 1

=== calc lt ''
--- evaldt : $d2 < $d
--- output : ''

=== calc lt 1
--- evaldt : $d < $d2
--- output : 1

=== calc == ''
--- evaldt : $d == $d2
--- output : ''

=== calc == 1
--- evaldt : $d == $d
--- output : 1

=== calc eq ''
--- evaldt : $d eq $d2
--- output : ''

=== calc eq 1
--- evaldt : $d eq $d
--- output : 1

=== calc <=> -1
--- evaldt : $d2 <=> $d
--- output : 1

=== calc <=> 0
--- evaldt : $d <=> $d
--- output : +0

=== calc <=> 1
--- evaldt : $d <=> $d2
--- output : -1

=== calc cmp -1
--- evaldt : $d2 cmp $d
--- output : 1

=== calc cmp 0
--- evaldt : $d cmp $d
--- output : +0

=== calc cmp 1
--- evaldt : $d cmp $d2
--- output : -1

=== between in
--- evaldt : $d->between($d - DAY * 2, $d2);
--- output : 1

=== between same
--- evaldt : $d->between($d, $d);
--- output : 1

=== between less
--- evaldt : $d->between($d + DAY, $d2);
--- output : ''

=== between more
--- evaldt : $d->between($d + DAY * 3, $d - DAY * 2);
--- output : ''

=== age 2007/11/28 -> 2027/11/28
--- evaldt : $d->age($d + YEAR * 20);
--- output : 20

=== age
--- evaldt : $d->age($d + YEAR * 20 - HOUR);
--- output : 20

=== age 2007/11/28 -> 2007/11/28
--- evaldt : $d->age($d);
--- output : +0

=== age 2007/11/28 -> 2007/11/29
--- evaldt : $d->age($d2);
--- output : +0

=== age 1987/11/28 -> now
--- evaldt : ($d - 20 * YEAR)->age();
--- output : (Wiz::DateTime->now - (Wiz::DateTime->now->set_epoch(1196246150) - Wiz::DateTime::Unit::YEAR * 20))->year

=== age 2/29 + 1 year
--- evaldt : my $d3 = ($d + 3 * MONTH)->last_day_of_month; $d3->age($d3 + YEAR + 1 * DAY);
--- output : 1

=== asian_age 2/29 + 1 year
--- evaldt : my $d3 = ($d + 3 * MONTH)->last_day_of_month; $d3->asian_age($d3 + YEAR + 1 * DAY);
--- output : 2

=== add method
--- evaldt : $d->add(year => 2); $d->ymd("/");
--- output : "2009/11/28"

=== add method with CONSTANT
--- evaldt : $d->add(YEAR * 2); $d->ymd("/");
--- output : "2009/11/28"

=== subtract method
--- evaldt : $d->subtract(year => 2); $d->ymd("/");
--- output : "2005/11/28"

=== subtract method with CONSTANT
--- evaldt : $d->subtract(YEAR * 2); $d->ymd("/");
--- output : "2005/11/28"

=== set_format and strftime_format
--- evaldt : $d->set_format();
--- output : "%Y-%m-%d %T"

=== strftime_format
--- evaldt : $d->strftime_format
--- output : "%Y-%m-%d %T"

=== set_format and strftime_format
--- evaldt : $d->set_format(Wiz::DateTime::Formatter::DB2); $d->strftime_format
--- output : "%Y-%m-%d %H.%M.%S"

=== set_end_of_month and get end_of_month
--- evaldt : $d->set_end_of_month('preserve'); $d->get_end_of_month; 
--- output : 'preserve'

=== time_zone
--- evaldt : $d->time_zone
--- output : "Asia/Tokyo"

=== set_time_zone; time_zone
--- evaldt : $d->set_time_zone("UTC"); $d->time_zone
--- output : "UTC"

=== ADT->parse GENERAL
--- evaldt : Wiz::DateTime->parse('2007-11-01');
--- output : "2007-11-01 00:00:00"

=== ADT->parse GENERAL with offset
--- evaldt : Wiz::DateTime->parse('2007-11-01 10:10:10+1000');
--- output : "2007-11-01 10:10:10"

=== ADT->parse GENERAL ymd with offset
--- evaldt : Wiz::DateTime->parse('2007-11-01+1000');
--- output : "2007-11-01 00:00:00"

=== ADT->parse GENERAL with offset
--- evaldt : my $adt = Wiz::DateTime->parse('2007-11-01 10:10:10+1000'); $adt->offset;
--- output : 60* 60 * 10

=== ADT->parse TAI64N
--- evaldt : Wiz::DateTime->parse(TAI64N => '@40000000474ec9e20eeb4260');
--- output : "2007-11-29 23:16:56"

=== ADT->parse ANY => tai64n
--- evaldt : Wiz::DateTime->parse(ANY => '@40000000474ec9e20eeb4260');
--- output : "2007-11-29 23:16:56"

=== ADT->new "YYYY/MM/DD"
--- evaldt : Wiz::DateTime->new("2007/11/12");
--- output : "2007-11-12 00:00:00"

=== ADT->new "YYYYMMDD"
--- evaldt : Wiz::DateTime->new("20071224");
--- output : "2007-12-24 00:00:00"

=== ADT->new "YYYY/MM/DD HH:MM:SS"
--- evaldt : Wiz::DateTime->new("2007/12/24 22:23:59");
--- output : "2007-12-24 22:23:59"

=== ADT->new year => 2007, month => 1, day => 15
--- evaldt : Wiz::DateTime->new(year => 2007, month => 1, day => 15);
--- output : "2007-01-15 00:00:00"

=== ADT->new {year => 2007, month => 1, day => 15}
--- evaldt : Wiz::DateTime->new({year => 2007, month => 1, day => 15});
--- output : "2007-01-15 00:00:00"

=== offset local
--- evaldt : $d->offset
--- output : 32400

=== offset UTC;
--- evaldt : $d->set_time_zone("UTC")->offset
--- output : +0

=== offset_string "+0900";
--- evaldt : $d->offset_string()
--- output : '+0900'

=== offset_string "+09:00";
--- evaldt : $d->offset_string('%s%02d:%02d')
--- output : '+09:00'

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

=== strftime TAI64N
--- evaldt
$d = Wiz::DateTime->now(time_zone => 'Asia/Tokyo');
$d->set_epoch(1196345816);
$d->set(nanosecond => 2503);
$d->strftime(Wiz::DateTime::Formatter::TAI64N);
--- output: '@40000000474ec9e2000009c7';

=== round
--- evaldt : $d->round('day'); $d->ymd("-");
--- output : '2007-11-28'

=== set_year
--- evaldt : $d->round('day')->set_year(2005); $d->ymd("-");
--- output : '2005-11-28'

=== set_day
--- evaldt : $d->round('day')->set_day(1); $d->ymd("-");
--- output : '2007-11-01'

=== set_month
--- evaldt : $d->round('day')->set_month(1); $d->ymd("-");
--- output : '2007-01-28'

=== set
--- evaldt : $d->round('day')->set(year => 2003, month =>1, day => 1); $d->ymd("-");
--- output : '2003-01-01'


=== set_parse_format
--- evaldt : $d->set_parse_format(); 
--- output : 'GENERAL'

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
