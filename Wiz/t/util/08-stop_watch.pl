#!/usr/bin/perl

use lib qw(../../lib);

use Data::Dumper;

use Wiz::Util::StopWatch;

my $sw = new Wiz::Util::StopWatch;

$sw->start;
select undef, undef, undef, 0.2;
$sw->stop_print;

sleep 1;

$sw->start;
select undef, undef, undef, 0.2;
$sw->stop_print;

$sw->start;
select undef, undef, undef, 0.2;
$sw->stop_print;

$sw->start;

select undef, undef, undef, 0.2;
$sw->lap;
print $sw;

$sw->stop;

print Dumper $sw->lap_history;
