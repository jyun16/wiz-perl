package DateTimeTest;

use Test::Base -Base;
use Wiz::Test -Base;

filters {
    formatter           => [qw/formatter/],
    evaldt              => [qw/evaldt/],
    evaldterr           => [qw/evaldterr/],
    unit                => [qw/unit/],
    input               => [qw/eval/],
    output              => [qw/eval/],
    end                 => [qw/end/],
    dtvalue             => [qw/eval dtvalue/],
    nth_day_of_week     => [qw/eval nth_day_of_week/],
    set_nth_day_of_week => [qw/eval set_nth_day_of_week/],
    datedef             => [qw/eval date_def/],
    year_calendar       => [qw/year_calendar/],
};


package DateTimeTest::Filter;

use Test::Base::Filter -Base;
use Wiz::Test::Filter -Base;
use Wiz::DateTime::Unit qw/:all/;

use constant EPOCH => 1196246150; # 2007/11/28 19:35:50

sub to_dt_args {
    return Wiz::DateTime::_to_dt_args(@_);
}

sub unit {
    my $unit = shift;
    my $class = "Wiz::DateTime::Unit::" . $unit;
    return Wiz::DateTime::_unit_name($unit =~/^\d+$/ ? $unit : $class->_new);
}

sub _unit {
    my $unit = shift;
    my $class = "Wiz::DateTime::Unit::" . $unit;
    return Wiz::DateTime::_unit_name($unit =~/^\d+$/ ? $unit : $class->_new);
}

sub end {
    my $unit = shift;
    my $d = Wiz::DateTime->now();
    $d->set_epoch(EPOCH);
    $d->end($unit);
    return $d;
}

sub nth_day_of_week {
    my $d = Wiz::DateTime->now();
    $d->set_epoch(EPOCH);
    return $d->nth_day_of_week(@_)->ymd("-");
}

sub set_nth_day_of_week {
    my $d = Wiz::DateTime->now();
    $d->set_epoch(EPOCH);
    $d->set_nth_day_of_week(@_);
    return $d->ymd("-");
}

sub last_day_of_month {
    my $d  = Wiz::DateTime->now();
    $d->set_epoch(EPOCH);
    return $d->last_day_of_month->ymd("-");
}

sub evaldt {
    my $code = shift;
    my $d  = Wiz::DateTime->now();
    my $d2 = Wiz::DateTime->now();
    $d->set_epoch(EPOCH);
    $d2->set_epoch(EPOCH + 86400);
    my $d3 = $d->clone;
    $d3 += YEAR * 3 + MONTH * 2 + DAY * -3;

    my $ret = eval $code;
    Carp::croak $@ if $@;
    return $ret;
}

sub evaldterr {
    my $code = shift;
    my $d = Wiz::DateTime->now();
    my $d2 = Wiz::DateTime->now();
    $d->set_epoch(EPOCH);
    $d2->set_epoch(EPOCH + 86400);
    my $ret = eval $code;
    return $@;
}

sub formatter {
    my $formatter = shift;
    my $dt = Wiz::DateTime->new(time_zone => 'Asia/Tokyo');
    $dt->set_epoch(EPOCH);
    no strict "refs";
    my $code = &{"Wiz::DateTime::Formatter::" . $formatter};
    return $code->($dt);
}

sub dump {
    Test::Base::YYY shift();
}

sub date_def {
    my ($day, $def, $dd) = @_;
    my $d = Wiz::DateTime->new($day, $def);
    unless ($dd) {
        return Wiz::DateTime::Definition->date_data($d, $d->prior_date_definition);
    } else {
        return Wiz::DateTime::Definition->date_data($d, $dd);
    }
}

sub year_calendar {
    my $code = shift;
    my $d  = Wiz::DateTime->now();
    my $_test = 1;
    warn "This test costs too much time.\n";
    my ($dd, $holidays) = (eval $code);
  LOOP:
    foreach my $year (sort keys %$holidays) {
        warn $year,"\n";
        my %tmp;
        @tmp{@{$holidays->{$year}}} = ();
        $d = $d->new($year . '-' . $holidays->{$year}->[0], $dd);
        while ($d->year == $year) {
            if (exists $tmp{$d->strftime("%m-%d")} or 
                $d->day_of_week >= 6) {
                # warn "$d - holiday\n";
                $_test &= ($d->is_holiday ? 1 : 0);
            } else {
                # warn "$d - weekday\n";
                $_test &= ($d->is_holiday ? 0 : 1);
            }
            if (not $_test) {
                warn $d->prior_date_definition;
                warn $d, $d->is_holiday ? ' holiday' : ' weekday';
                warn Data::Dumper::Dumper (Wiz::DateTime::Definition->date_data($d, $d->date_definition));
                last LOOP;
            }
            $d += Wiz::DateTime::Unit::DAY;
        }
    }
    return $_test;
}
