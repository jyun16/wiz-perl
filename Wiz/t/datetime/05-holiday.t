#!/usr/bin/perl

use lib qw(../../lib ./lib ../lib ./t/datetime/lib ./datetime/lib);
use DateTime;
use Wiz::DateTime;
use Wiz::DateTime::Definition;
use DateTimeTest qw/no_plan/;

chtestdir;

run_has_hash datedef => 'output';
run_has_hash evaldt  => 'output';
run_compare year_calendar  => 'output';

__END__
=== 01/01 jp
--- datedef : "2007-01-01", ["jp"], "jp"
--- output  : {is_holiday => 1, name => ["元日"]}

=== 06/01/16 jp
--- datedef : "2006-01-16", ["jp"]
--- output  : {name => []}

=== 02/11 jp
--- datedef : "2007-02-11", ["jp"], "jp"
--- output  : {is_holiday => 1, name => ["建国記念の日", "日曜日"]}

=== 02/11 jp
--- datedef : "2007-02-12", ["jp"], "jp"
--- output  : {is_holiday => 1, name => ["振替休日"], is_substitute_holiday => 1}

=== 02/23 jp
--- datedef : "2008-02-23", ["jp"], "jp"
--- output  : {is_holiday => 1, name => ["土曜日"]}

=== 02/24 jp
--- datedef : "2008-02-24", ["jp"], "jp"
--- output  : {is_holiday => 1, name => ["日曜日"]}

=== 02/25 jp
--- datedef : "2008-02-25", ["jp"], "jp"
--- output  : {name => []}

=== 03/05/06 jp
--- datedef : "2003-05-06", ["jp"], "jp"
--- output  : {name => []}

=== 07/12/22 jp
--- datedef : "2007-12-22", ["jp"], "jp"
--- output  : {is_holiday => 1, name => ["土曜日"]}

=== 07/12/23 jp
--- datedef : "2007-12-23", ["jp"], "jp"
--- output  : {is_holiday => 1, name => ["天皇誕生日", "日曜日"]}

=== 07/12/24 jp
--- datedef : "2007-12-24", ["jp"], "jp"
--- output  : {is_holiday => 1, name => ["振替休日"], is_substitute_holiday => 1}

=== 08/05/06 jp
--- datedef : "2008-05-06", ["jp"], "jp"
--- output  : {is_holiday => 1, name => ["振替休日"], is_substitute_holiday => 1}

=== 08/05/07 jp
--- datedef : "2008-05-07", ["jp"], "jp"
--- output  : {name => []}

=== 08/05/08 jp
--- datedef : "2008-05-08", ["jp"], "jp"
--- output  : {name => []}

=== 08/05/06 jp
--- datedef : "2008-05-06", ["jp"]
--- output  : {is_holiday => 1, name => ["振替休日"], is_substitute_holiday => 1}

=== 08/05/07 jp
--- datedef : "2008-05-07", ["jp"]
--- output  : {name => []}

=== 08/05/08 jp
--- datedef : "2008-05-08", ["jp"]
--- output  : {name => []}

=== 01/01 cn
--- datedef : "2007-01-01", ["cn"], "cn"
--- output  : {is_holiday => 1, name => ["元旦"]}

=== 2006/01/29 cn-luna 01/01
--- datedef : "2006-01-29", ["cn"], "cn"
--- output  : {is_holiday => 1, name => ["春节"]}

=== 2008/02/02 standard
--- datedef : "2008-02-02", ["standard"], "standard"
--- output  : {is_holiday => 1, name => ["Saturday"]}

=== 2008/02/03 standard
--- datedef : "2008-02-03", ["standard"], "standard"
--- output  : {is_holiday => 1, name => ["Sunday"]}

=== 2008/02/03 standard+jp
--- datedef : "2008-02-03", ["standard+jp"]
--- output  : {is_holiday => 1, name => ["Sunday", "日曜日"]}

=== 2008/01/01 standard+jp+cn
--- datedef : "2008-01-01", ["standard+jp+cn"]
--- output  : {is_holiday => 1, name => ["元日", "元旦"]}

=== set_date_definition({}); date_data_detailed
--- evaldt
$d->set_date_definition
    (
     {
      calendar =>
      {
       gregorian =>
       {
        ymd => {
                '2007-11-28' => {
                                 is_holiday => 1,
                                 name       => 'hogehoge',
                                }
               }
       }
      }
     }, 'mydef');
Wiz::DateTime::Definition->date_data_detailed($d);

--- output
 {
     name =>
         {
          mydef => ["hogehoge"],
         },
     is_holiday =>
         {
          mydef => 1,
         },
 }

=== set_date_definition({}); date_data
--- evaldt
$d->set_date_definition
    (
     {
      calendar =>
      {
       gregorian =>
       {
        ymd => {
                '2007-11-28' => {
                                 is_holiday => 1,
                                 name       => 'hogehoge',
                                }
               }
       }
      }
     }, 'mydef');
Wiz::DateTime::Definition->date_data($d, $d->date_definition);

--- output
 {
     name                  => ["hogehoge"],
     is_holiday            => 1,
 }

=== set_date_definition(yaml => ...); date_data_detailed
--- evaldt
$d->set_date_definition(yaml => 'conf/myconf.yml');
Wiz::DateTime::Definition->date_data_detailed($d);

--- output
 {
     name =>
         {
          'conf/myconf.yml' => ["hogehoge"],
         },
     is_holiday =>
         {
          'conf/myconf.yml' => 1,
         },
 }

=== set_date_definition(yml => ...); date_data_detailed
--- evaldt
$d->set_date_definition(yml => 'conf/myconf.yml');
Wiz::DateTime::Definition->date_data_detailed($d);

--- output
 {
     name =>
         {
          'conf/myconf.yml' => ["hogehoge"],
         },
     is_holiday =>
         {
          'conf/myconf.yml' => 1,
         },
 }

=== set_date_definition(yml => ...) date_data
--- evaldt
$d->set_date_definition(yml => 'conf/myconf.yml');
Wiz::DateTime::Definition->date_data($d, $d->date_definition);

--- output
 {
     name                  => ["hogehoge"],
     is_holiday            => 1,
 }

=== 2008-weekdays
--- year_calendar
['jp'], {
		# I doubt 1959
		1959 => [qw/
01-01 01-15 03-21
04-10 04-29
05-05 09-24 11-03
11-23
/],
		2006 => [qw/
01-01
01-02 01-09 02-11
03-21 04-29 05-03
05-04 05-05 07-17
09-18 09-23 10-09
11-03 11-23 12-23
			  /],
		 2007 => [qw/
01-01 01-08 
02-12 03-11 03-21
04-30 05-03 05-04
05-05 07-16 09-17
09-24 10-08 11-03
11-23 12-24
			  /],
		 2008 => [qw/
01-01 01-14 02-11
03-20 04-29 05-03
05-05 05-06 07-21
09-15 09-23 10-13
11-03 11-24 12-23
			  /],
		 2009 => [qw/
01-01 01-12 02-11
03-20 04-29 05-04
05-05 05-06 07-20
09-21 09-22 09-23
10-12 11-03 11-23
12-23
			  /],
		 2010 => [qw/
01-01 01-11 02-11
03-22 04-29 05-03
05-04 05-05 07-19
09-20 09-23 10-11
11-03 11-23 12-23
			  /],
		 2032 => [qw/
01-01 01-12 02-11
04-29 05-03 05-04
05-05 07-19 09-20
09-21 09-22 10-11
11-03 11-23 12-23
			  /],
};
--- output
1
