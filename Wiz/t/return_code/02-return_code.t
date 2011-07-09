#!/usr/bin/perl

use lib qw(../../lib);
use Wiz::Test qw/no_plan/;
use Wiz::ReturnCode qw/:all/;

chtestdir;

foreach my $n (undef, 0 .. 10) {
    my $m = defined $n ? $n : "'undef'";
    my $code = return_code($n, "return $m");
    is($code, $n, "code is $m");
    is($code->message, "return $m", "message: reutrn $m");
    ok(return_code_is($code, $n), "\$code return code is $m");
}

