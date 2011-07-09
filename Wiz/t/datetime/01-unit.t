#!/usr/bin/perl

use lib qw(../../lib);
use Wiz::Test qw/no_plan/;
use Scalar::Util;

chtestdir;

BEGIN{ use_ok "Wiz::DateTime::Unit" };

use Wiz::DateTime::Unit qw/:all/;

foreach my $method (qw/YEAR MONTH WEEKDAY/) {
    my $pkg = 'Wiz::DateTime::Unit::' . ucfirst lc $method;
    ok my $o = $pkg->_new, $pkg;
    is  ref $o, $pkg, 'ref object => ' . $pkg;
    is  ${$o * 100}, 100, 'multiply 100';
    is  ${$o * 15}, 15, 'multiply 15';
}

is DAY   , 60 * 60 * 24, 'day seconds';
is HOUR  , 60 * 60, 'hour seconds';
is MINUTE, 60, 'minute seconds';
is SECOND, 1, 'seconds';

is scalar @{MONTH * 10 + YEAR * 20}, 2, 'plus objects.';
is scalar @{MONTH * 10 - YEAR * 20}, 2, 'plus objects.';
is Scalar::Util::reftype(MONTH + MONTH - DAY), 'ARRAY', 'plus/minus object';
is Scalar::Util::reftype(MONTH - YEAR), "ARRAY", 'minus objects';
is Scalar::Util::reftype(MONTH - DAY), "ARRAY", 'minus DAY';
is Scalar::Util::reftype(MONTH - (MONTH - DAY)), "ARRAY", 'minus DAY';
is Scalar::Util::reftype(MONTH + DAY), "ARRAY", 'plus DAY';
is Scalar::Util::reftype(3 * MONTH + YEAR * 1), "ARRAY", '3 * MONTH + YEAR * 1';

is MONTH->is_unit, 1, 'is_unit';

is MONTH  , 1, 'MONTH';
is YEAR   , 1, 'YEAR';
is WEEKDAY, 1, 'MONTH';

ok MONTH   eq 1, 'MONTH eq';
ok YEAR    eq 1, 'YEAR  eq';
ok WEEKDAY eq 1, 'MONTH eq';


my $unit_scalar = MONTH;
my $unit_array  = MONTH - DAY;
is($unit_scalar ? 1 : 0, 1, "MONTH");
is($unit_array  ? 1 : 0, 1, "MONTH - DAY");

is Scalar::Util::reftype($unit_scalar + $unit_array ), "ARRAY", "unit_scalar + unit_array";
is Scalar::Util::reftype($unit_array  + $unit_scalar), "ARRAY", "unit_array + unit_scalar";

ok(Wiz::DateTime::Unit->_new());
ok(Wiz::DateTime::Unit::Month->_new);
ok(Wiz::DateTime::Unit::Year->_new);
ok(Wiz::DateTime::Unit::Weekday->_new);
