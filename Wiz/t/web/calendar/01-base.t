#!/usr/bin/perl

use lib qw(../../lib ./lib ../lib ./t/datetime/lib ./datetime/lib);
use Wiz::Test qw/no_plan/;
use Wiz::Web::Calendar::Base;

chtestdir;

sub cal_list {
    my $arg = shift || {};
    my $def = {  year  => 2008,
                 month => 2,
		 date_definition => 'STANDARD',
              };
    $arg->{$_} ||= $def->{$_} foreach keys %$def;
    my $code = shift;
    my $c    = Wiz::Web::Calendar::Base->new($arg);
    return $c->date_hash;
}

sub cal_range {
    my $arg = shift || {};
    my $def = {  range => ['2008-01', '2008-03'] };
    $arg->{$_} ||= $def->{$_} foreach keys %$def;
    my $code = shift;
    my $c    = Wiz::Web::Calendar::Base->new($arg);
    return $c->date_range;
}

sub first {
    my $d = shift;
    if (ref $d eq 'HASH') {
        my $key = (sort {$a <=> $b} keys %$d)[0];
        return $d->{$key};
    } else {
        return [map first($_), @$d];
    }
}

sub last {
    my $d = shift;
    if (ref $d eq 'HASH') {
        my $key = (sort {$b <=> $a} keys %$d)[0];
        return $d->{$key};
    } else {
        return [map &last($_), @$d];
    }
}

sub count {
    return $_ = scalar keys %{shift()};
}

filters {
    cal_list  => [qw/eval cal_list/],
    cal_range => [qw/eval cal_range/],
    output    => [qw/eval/],
};

run_compare cal_list => 'output';
run_compare cal_range => 'output';

__END__
=== first_day
--- cal_list first
--- output
{
    year    => 2008,
    month   => '01',
    day     => 27,
    holiday => 1,
    wday    => 7,
    prev_month => 1,
    class   => [qw/holiday prev/],
}

=== last_day
--- cal_list last
--- output
{
    year    => 2008,
    month   => '03',
    day     => '01',
    holiday => 1,
    wday    => 6,
    next_month => 1,
    class   => [qw/holiday next/],
}

=== first_day (wday_start => 1)
--- cal_list first
{wday_start => 1}
--- output
{
    year    => 2008,
    month   => '01',
    day     => 28,
    holiday => 0,
    wday    => 1,
    prev_month => 1,
    class   => [qw/prev/],
}

=== last_day (wday_start => 1)
--- cal_list last
{wday_start => 1}
--- output
{
    year    => 2008,
    month   => '03',
    day     => '02',
    holiday => 1,
    wday    => 7,
    next_month => 1,
    class   => [qw/holiday next/],
}

=== first_day(current_month)
--- cal_list first
{current_month_only => 1}
--- output
{
    year    => 2008,
    month   => '02',
    day     => '01',
    holiday => 0,
    wday    => 5,
    class   => [],
}

=== first_day(current_month) selected
--- cal_list first
{current_month_only => 1, day => 1}
--- output
{
    year     => 2008,
    month    => '02',
    day      => '01',
    holiday  => 0,
    wday     => 5,
    selected => 1,
    class   => [qw/selected/],
}

=== last_day(current_month)
--- cal_list last
{current_month_only => 1}
--- output
{
    year    => 2008,
    month   => '02',
    day     => '29',
    holiday => 0,
    wday    => 5,
    class   => [],
}

=== count
--- cal_list count
--- output
35

=== count(current_month)
--- cal_list count
{current_month_only => 1}
--- output
29

=== range first_days(current_month)
--- cal_range first
{current_month_only => 1}

--- output
[{
    year    => 2008,
    month   => '01',
    day     => '01',
    holiday => 0,
    wday    => 2,
    class   => [],
},{
    year    => 2008,
    month   => '02',
    day     => '01',
    holiday => 0,
    wday    => 5,
    class   => [],
},{
    year    => 2008,
    month   => '03',
    day     => '01',
    holiday => 1,
    wday    => 6,
    class   => [qw/holiday/],
}]

=== range last_days(current_month)
--- cal_range last
{current_month_only => 1}
--- output
[{
    year    => 2008,
    month   => '01',
    day     => '31',
    holiday => 0,
    wday    => 4,
    class   => [],
},{
    year    => 2008,
    month   => '02',
    day     => '29',
    holiday => 0,
    wday    => 5,
    class   => [],
},{
    year    => 2008,
    month   => '03',
    day     => '31',
    holiday => 0,
    wday    => 1,
    class   => [],
}]
=== first_day with dest_url
--- cal_list first
{dest_url => 'http://example.com/?$y$m$d'}
--- output
{
    year    => 2008,
    month   => '01',
    day     => 27,
    holiday => 1,
    wday    => 7,
    prev_month => 1,
    dest_url   => 'http://example.com/?20080127',
    class   => [qw/holiday prev/],
}
=== first_day with dest_url
--- cal_list first
{dest_url => 'http://example.com/?$ymd'}
--- output
{
    year    => 2008,
    month   => '01',
    day     => 27,
    holiday => 1,
    wday    => 7,
    prev_month => 1,
    dest_url   => 'http://example.com/?2008-01-27',
    class   => [qw/holiday prev/],
}

