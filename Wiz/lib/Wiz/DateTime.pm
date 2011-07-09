package Wiz::DateTime;

local $ENV{PERL_NO_VALIDATION} = 1;

use strict;
use warnings;

use Time::Zone ();
use Wiz::DateTime::Delta ();
use Wiz::DateTime::Definition ();
use Wiz::DateTime::Unit ();
use DateTime::Duration ();
use List::MoreUtils ();
use YAML::Syck ();
use DateTime::TimeZone::Local ();
use constant LOCAL => DateTime::TimeZone::Local->TimeZone();
use Scalar::Util qw/blessed/;

=head1 NAME

Wiz::DateTime - wrapper of DateTime

=head1 VERSION

version 1.0

=cut

our $VERSION = '1.0';

=head1 SYNOPSIS

 use Wiz::DateTime;
 my $d = Wiz::DateTime->new(year => 2006, month => 10, day => 6, time_zone => 'Asia/Tokyo');
 # my $d = Wiz::DateTime->new('2006-10-6 00:00:00', tz => 'Asia/Tokyo');

 $d += 7;  # + 7 seconds
 print $d;

 $d -= 7 * DAY;  # - 7 days
 print $d;

 $d -= 7 * WEEKDAY;  # - 7 weekdays
 print $d;

 my($is_holiday, $holiday_word) = $d->is_holiday("2007-01-01")
 my($is, $date_explanation) = $d->is('custom_date_type', "2007-01-01")

=cut

use DateTime;
use base qw(Exporter);

=head1 EXPORTS

Constans for date and time operation:

 SECOND
 HOUR
 DAY
 MONTH
 YEAR

Formats for parse date and time string:

 GENERAL
 DATE
 ACCESS_LOG
 ERROR_LOG
 APACHE_DIRINDEX
 MYSQL
 DB2
 RFC822
 RFC850
 W3C
 TIME
 TIME_DETAIL

=cut

use Wiz::ConstantExporter {
    HOUR    => 3600,
    DAY     => 86400,
};

use constant {
    _YEAR        => 128,
    _MONTH       => 64,
    _DAY         => 32,
    _HOUR        => 16,
    _MINUTE      => 8,
    _SECOND      => 4,
    _MICROSECOND => 2,
    _NANOSECOND  => 1,
};

use constant _MONTH2NUM =>
    (
     jan => 1,  feb => 2,
     mar => 3,  apr => 4,
     may => 5,  jun => 6,
     jul => 7,  aug => 8,
     sep => 9,  oct => 10,
     nov => 11, dec => 12,
     january   => 1,    february  => 2,
     march     => 3,    april     => 4,
     june      => 6,
     july      => 7,    august    => 8,
     september => 9,    october   => 10,
     november  => 11,   december  => 12,
    );

BEGIN {
    # It is borrwed from DateTime::Format::Manip
    my %TZ_MAP =
        (
         # Abbreviations (see http://www.worldtimezone.com/wtz-names/timezonenames.html)
         # [1] - YST matches worldtimezone.com but not Canada/Yukon
         # [2] - AT  matches worldtimezone.com but not Atlantic/Azores
         # [3] - City chosen at random from similar matches
         idlw   => "-1200",     # International Date Line West (-1200)
         nt     => "-1100",             # Nome (-1100) (obs. -1967)
         hst    => "US/Hawaii",         # Hawaii Standard (-1000)
         cat    => "-1000",      # Central Alaska (-1000) (obs. -1967)
         ahst   => "-1000", # Alaska-Hawaii Standard (-1000) (obs. 1967-1983)
         akst   => "US/Alaska",         # Alaska Standard (-0900)
         yst    => "-0900",             # Yukon Standard (-0900) [1]
         hdt    => "-0900",    # Hawaii Daylight (-0900) (until 1947?)
         akdt   => "US/Alaska",         # Alaska Daylight (-0800)
         ydt    => "-0800",             # Yukon Daylight (-0900) [1]
         pst    => "US/Pacific",        # Pacific Standard (-0800)
         pdt    => "US/Pacific",        # Pacific Daylight (-0700)
         mst    => "US/Mountain",       # Mountain Standard (-0700)
         mdt    => "US/Mountain",       # Mountain Daylight (-0600)
         cst    => "US/Central",        # Central Standard (-0600)
         cdt    => "US/Central",        # Central Daylight (-0500)
         est    => "US/Eastern",        # Eastern Standard (-0500)
         sat    => "-0400",             # Chile (-0400)
         edt    => "US/Eastern",        # Eastern Daylight (-0400)
         ast    => "Canada/Atlantic",   # Atlantic Standard (-0400)
         #nst   => "Canada/Newfoundland",  # Newfoundland Standard (-0300)     nst=North Sumatra    +0630
         nft    => "Canada/Newfoundland", # Newfoundland (-0330)
         #gst   => "-0300",  # Greenland Standard (-0300)        gst=Guam Standard    +1000
         #bst   => "Brazil/East",          # Brazil Standard (-0300)           bst=British Summer   +0100
         adt    => "Canada/Atlantic",   # Atlantic Daylight (-0300)
         ndt    => "Canada/Newfoundland", # Newfoundland Daylight (-0230)
         at     => "-0200",             # Azores (-0200) [2]
         wat    => "Africa/Bangui",     # West Africa (-0100) [3]
         gmt    => "Europe/London",     # Greenwich Mean (+0000)
         ut     => "Etc/Universal",     # Universal (+0000)
         utc    => "UTC",            # Universal (Coordinated) (+0000)
         wet    => "Europe/Lisbon",     # Western European (+0000) [3]
         west   => "Europe/Lisbon", # Alias for Western European (+0000) [3]
         cet    => "Europe/Madrid",     # Central European (+0100)
         fwt    => "Europe/Paris",      # French Winter (+0100)
         met    => "Europe/Brussels",   # Middle European (+0100)
         mez    => "Europe/Berlin",     # Middle European (+0100)
         mewt   => "Europe/Brussels", # Middle European Winter (+0100)
         swt    => "Europe/Stockholm",  # Swedish Winter (+0100)
         bst    => "Europe/London", # British Summer (+0100)             bst=Brazil standard  -0300
         gb     => "Europe/London", # GMT with daylight savings (+0100)
         eet    => "Europe/Bucharest", # Eastern Europe, USSR Zone 1 (+0200)
         cest   => "Europe/Madrid",  # Central European Summer (+0200)
         fst    => "Europe/Paris",      # French Summer (+0200)
         #     ist    => "Asia/Jerusalem",       # Israel standard (+0200) (duplicate of Indian)
         mest   => "Europe/Brussels", # Middle European Summer (+0200)
         mesz   => "Europe/Berlin",   # Middle European Summer (+0200)
         metdst => "Europe/Brussels", # An alias for mest used by HP-UX (+0200)
         sast   => "Africa/Johannesburg", # South African Standard (+0200)
         sst    => "Europe/Stockholm", # Swedish Summer (+0200)             sst=South Sumatra    +0700
         bt     => "+0300",             # Baghdad, USSR Zone 2 (+0300)
         eest   => "Europe/Bucharest", # Eastern Europe Summer (+0300)
         eetedt => "Europe/Bucharest", # Eastern Europe, USSR Zone 1 (+0300)
         #     idt    => "Asia/Jerusalem",       # Israel Daylight (+0300) [Jerusalem doesn't honor DST)
         msk    => "Europe/Moscow",     # Moscow (+0300)
         it     => "Asia/Tehran",       # Iran (+0330)
         zp4    => "+0400",             # USSR Zone 3 (+0400)
         msd    => "Europe/Moscow",     # Moscow Daylight (+0400)
         zp5    => "+0500",             # USSR Zone 4 (+0500)
         ist    => "Asia/Calcutta",     # Indian Standard (+0530)
         zp6    => "+0600",             # USSR Zone 5 (+0600)
         nst    => "+0630", # North Sumatra (+0630)             nst=Newfoundland Std -0330
         #sst   => "+0700",  # South Sumatra, USSR Zone 6 sst=Swedish Summer   +0200
         hkt    => "Asia/Hong_Kong",    # Hong Kong (+0800)
         sgt    => "Asia/Singapore",    # Singapore  (+0800)
         cct    => "Asia/Shanghai", # China Coast, USSR Zone 7 (+0800)
         awst   => "Australia/West", # West Australian Standard (+0800)
         wst    => "Australia/West", # West Australian Standard (+0800)
         pht    => "Asia/Manila",       # Asia Manila (+0800)
         kst    => "Asia/Seoul",        # Republic of Korea (+0900)
         jst    => "Asia/Tokyo", # Japan Standard, USSR Zone 8 (+0900)
         rok    => "ROK",               # Republic of Korea (+0900)
         cast   => "Australia/South", # Central Australian Standard (+0930)
         east   => "Australia/Victoria", # Eastern Australian Standard (+1000)
         gst    => "Pacific/Guam", # Guam Standard, USSR Zone 9 gst=Greenland Std    -0300
         cadt   => "Australia/South", # Central Australian Daylight (+1030)
         eadt   => "Australia/Victoria", # Eastern Australian Daylight (+1100)
         idle   => "+1200",             # International Date Line East
         nzst   => "Pacific/Auckland",  # New Zealand Standard
         nzt    => "Pacific/Auckland",  # New Zealand
         nzdt   => "Pacific/Auckland",  # New Zealand Daylight
        );

    # This is not used
    my %US_MILITARY_ZONE =
        (
         # US Military Zones
         'z'    => "+0000",
         'a'    => "+0100",
         'b'    => "+0200",
         'c'    => "+0300",
         'd'    => "+0400",
         'e'    => "+0500",
         'f'    => "+0600",
         'g'    => "+0700",
         'h'    => "+0800",
         'i'    => "+0900",
         'k'    => "+1000",
         'l'    => "+1100",
         'm'    => "+1200",
         'n'    => "-0100",
         'o'    => "-0200",
         'p'    => "-0300",
         'q'    => "-0400",
         'r'    => "-0500",
         's'    => "-0600",
         't'    => "-0700",
         'u'    => "-0800",
         'v'    => "-0900",
         'w'    => "-1000",
         'x'    => "-1100",
         'y'    => "-1200",
        );

    my %stz2offset;

    foreach my $name (keys %Time::Zone::Zone) {
        if (my ($sign, $n) = $Time::Zone::Zone{$name} =~/^([-])?(\d+)$/) {
            $n /= (60 * 60);
            $stz2offset{$name} = sprintf "%s%02d00", $sign || '+', $n;
        }
    }

    sub _STZ2OFFSET {
        return \%stz2offset
    }

    sub _TZ2STZ {
        return {reverse %TZ_MAP};
    }

    sub _STZ2TZ {
        return \%TZ_MAP;
    }
}

# the following "use" must be here!
use Wiz::DateTime::Parser;
use Wiz::DateTime::Formatter qw/GENERAL/;

=head1 CONSTRUCTOR

=head2 new

There are some ways to create object.

=head3 Simple way

 my $d = Wiz::DateTime->new();                     # current time, timezone is local
 my $d = Wiz::DateTime->new('2007-01-01');         # specify date
 my $d = Wiz::DateTime->new('2007-01');            # specify year and month only
 my $d = Wiz::DateTime->new('2007-01-01', ['jp']); # specify date & holiday type
 my $d = Wiz::DateTime->new('');                   # current time; specify holiday type
 my $d = Wiz::DateTime->new('', [qw/jp chinese/]); # current time; specify holiday types

First argument is date and time string.
see L<Allowed Date and Time Notation>.

=head3 Another way

 # you can write tz as time_zone.
 my $d = Wiz::DateTime->new(date => '2007-01-01', time_zone => 'local', date_definition => ['jp']);
 # you can write tz as time_zone.
 my $d = Wiz::DateTime->new(datetime => '2007-01-01 10:00:00', time_zone => 'local', date_definition => ['jp']);

=head3 DateTime way

 my $d = Wiz::DateTime->new(year => 2007, month => 1, day => 1, time_zone => 'local');
 my $d = Wiz::DateTime->new(
                      year   => 1964,
                      month  => 10,
                      day    => 16,
                      hour   => 16,
                      minute => 12,
                      second => 47,
                      nanosecond => 500000000,
                      time_zone => 'Asia/Taipei',
                    );

=head3 You can write them as reference

 my $d = Wiz::DateTime->new(['2007-01-01', ['standard']]);
 my $d = Wiz::DateTime->new({date => '2007-01-01'});
 my $d = Wiz::DateTime->new({year => 2007, month => 1, day => 1});

=head3 Date Definition

It defines special information of the day.
You can give standard, jp or cn as array ref.
Their names are part of Wiz::DateTime::Definition::* modules.

 standard -> Wiz::DateTime::Definition::STANDARD
 jp       -> Wiz::DateTime::Definition::JP
 cn       -> Wiz::DateTime::Definition::CN

Both capital case letter and lower case letter are ok.

This affects is_holiday, is_weekday, add_weekday methods.
Normally, first date definition is used for these methods.
For example;

  my $d = Wiz::DateTime->new(['2007-01-01', ['jp', 'cn']]);

In this case, JP is used.

If you want mixed definition. You can join names with '+' as the following:

  my $d = Wiz::DateTime->new(['2007-01-01', ['jp+cn']]);

'jp' in the former case and 'jp' and  'cn' in the later case are
called as C<prior date definition> here.

These values can get by C<prior_date_definition> and
can set by C<set_prior_date_definition>.

=cut

sub new {
    my $prot = shift;
    my $class = ref $prot ? ref $prot : $prot;

    my $date_definition = [];

    if (@_ == 1 and my $ref = ref $_[0]) {
        if ($ref eq 'ARRAY') {
            @_ = @{$_[0]};
        } elsif ($ref eq 'HASH') {
            @_ = %{$_[0]};
        } elsif ($ref eq 'Wiz::DateTime') {
            return $_[0]->clone;
        } else {
            Carp::croak 'argument is strange:' . $_[0];
        }
    }

    my $self = bless {
                      _dt              => undef,
                      _parse_format    => 'GENERAL',
                      _format          => GENERAL,
                      _end_of_month    => 'limit',
                      _date_definition => [],
                      _prior_date_defs => [],
                     }, $class;
    if (not @_) {
        $self->set_now;
    } elsif (@_ == 1 or (@_ == 2 and ref $_[1] eq 'ARRAY')) {
        return if not my $parsed = $self->_parse(shift);
        local $@;
        eval {
            $self->_dt($self->_datetime_new(%$parsed));
        };
        return if $@;
        $date_definition = shift;
    } else {
        my %args = @_;
        my %time_zone;
        $time_zone{time_zone} = delete $args{time_zone} || delete $args{tz} || LOCAL;
        $date_definition      = delete $args{date_definition};

        if (my $date = delete $args{date} || delete $args{datetime}) {
            return if not my $parsed = $self->_parse($date);
            %args = %$parsed;
        }
        if (not %args) {
            $self->_dt($self->_datetime_now);
        } else {
            my $dt;
            local $@;
            eval {
                $dt = $self->_datetime_new(%args, %time_zone);
            };
            return if $@;
            $self->_dt($dt);
        }
    }

    $self->set_date_definition($date_definition);
    return $self;
}

sub _dt {
    my($self, $dt) = @_;
    return @_ == 2 ? $self->{_dt} = $dt : $self->{_dt};
}

=head1 METHODS

=head2 methods for changing/getting setting for the object

This type of methods changes timezone/date_definition etc.
These can be called as Class method to change an environment of this Class.
So it effects all object created after this method is used.

=head3 $self = set_date_definition(@definitions)

It sets date definisitions and prior date definitions.
@definitions can take the following.

=over 4

=item strings array

 $d->set_date_definition('jp'); # use Wiz::DateTime::Definition::JP

It sets 'jp' as date definition and prior date definition.

 $d->set_date_definition('jp', 'cn'); # use *::JP and *::CN

It sets 'jp' and 'cn 'as date definition and 'jp' as prior date definition.

So, First definition is regarded as prior date definition.
If you want to set multiple prior date definitions at once.

 $d->set_date_definition('jp+cn'); # use *::JP and *::CN

It sets 'jp' and 'cn 'as date definition and prior date definition.

About these defference and other information, see L<Date Definition>.

=item hash reference

 $d->set_date_definition({calendar => {gregorian => {md => {'01-01' => 'gantan'}}}});

see L<Date Definition Rule>.

=item yml

If argument is not stated with '-' and not hash ref,
It is understood as filename.t

 $d->set_date_definition(yml => '/path/to/holiday.yml');

see L<Date Definition Rule>.

=back

=head3 $self = date_definition

It returns date definition.

=head3 $date_defs = set_prior_date_definition(@date_defs)

It changes prior date definition(s).

See L<Date Definition> for detail.

=head3 $date_defs = prior_date_definition

get prior date definition(s).

See L<Date Definition> for detail.

=head3 $self = set_time_zone($tz)

 $d->set_time_zone('Asia/Tokyo');

It sets timezone.

=head3 $tz = time_zone;

 $tz = $d->time_zone;

It gets timezone. Default is 'local'.

=head3 $format = set_format($format)

 $d->set_format(GENERAL);

It sets the format used by strftime method.
See L<Allowed Date and Time Notation>.

=cut

sub set_format {
    my ($self, $format) = @_;
    $self->{_format} = $format if @_ == 2;
    return $self->{_format} || GENERAL;
}

=head3 $format = strftime_format

It is as same as C<set_format>.

=cut

sub strftime_format {
    my ($self) = @_;
    return $self->{_format} || GENERAL;
}

=head3 $self = set_parse_format($format)

 $d->set_parse_format('GENERAL');

It sets the format used by parse method.
See L<Allowed Date and Time Notation>.

=cut

sub set_parse_format {
    my ($self, $format) = @_;
    Carp::croak "set_parse_format needs string as format: $format" if ref $format;
    $self->{_parse_format} = $format if @_ == 2;
    return $self->{_parse_format} || 'GENERAL';
}

=head3 $parse_format = parse_format($format)

 $d->parse_format;

It get the format used by parse method.
See C<set_parse_format>.

=cut

sub parse_format {
    my ($self) = @_;
    return PARSER()->{GENERAL}   if not ref $self;
    return $self->{_parse_format};
}


=head3 $end_of_month_type = set_end_of_month($end_of_moeth)

It takes 'limit', 'preserve' or 'wrap'.
See C<add>.

=head3 $end_of_month_type = get_end_of_month;

It gets end_of_month value.
See C<add>.

=cut

=head2 class methods

These methods cannot be used as object method.

=head3 $d = now

It returns current datetime Wiz::DateTime object.

=cut

sub now {
    my ($self) = @_;
    my $dt = $self->_datetime_now;
    my $adt = $self->new;
    $adt->_dt($dt);
    return $adt;
}

sub _datetime_now {
    my ($self) = @_;
    my $dt;
    return DateTime->now(time_zone => $self->_time_zone);
}

sub _datetime_new {
    my($prot, %args) = @_;
    if (my $msec = delete $args{microsecond}) {
        $args{nanosecond} = $msec * 1000;
    }
    $args{time_zone} ||= LOCAL;
    return DateTime->new(%args);
}

=head3 $d = today

It returns today Wiz::DateTime object.

=cut

sub today {
    my ($self) = @_;
    my $adt = $self->new();
    $adt->_dt($self->_datetime_today);
    return $adt;
}

sub _datetime_today {
    my ($self) = @_;
    return DateTime->today(time_zone => $self->_time_zone);
}

=head3 $d = current_date

It returns current date Wiz::DateTime object.
This won't change 

=cut

sub current_date {
    my ($self) = @_;
    my $dt = $self->today;
    $dt->set($self->_time_hash);
    return $dt;
}

=head2 methods to return new object

This type methods create new object.
You can pass DateTime object, Wiz::DateTime object
and date and time notation.

=head3 $d = clone;

It returns the clone of $d.

=cut

sub clone {
    my ($self) = @_;
    my $new_adt = $self->new();
    foreach my $key (keys %$self) {
        $new_adt->{$key} = $self->{$key};
    }
    $new_adt->_dt($self->_dt->clone);
    return $new_adt;
}

=head3 $d = parse($type, $date_string)

It return Adwdays::DateTime object.
When you can omit $type, try default formats(GENERAL).

see L<Allowed Date and Time Notation>.

If you want to try all formats, use C<ANY> as C<$type>.

=head3 $d = last_day_of_month

It returns the last date of the month.

=head3 $d = nth_day_of_week($nth, $day_of_week)

This is the first Sunday of the month.
If such a date doesn't exist,  returns undef.

=head2 methods for changing object itself

You can use almost all methods explained in previous 2 section.
But you need to add 'set_' to prefix.
And you can use DateTime::set_* and DateTime::add methods.

=head3 set_now

=cut

sub set_now {
    my($self) = @_;
    $self->_dt($self->_datetime_now);
    return $self;
}

=head3 set_today


=cut

sub set_today {
    my($self) = @_;
    $self->_dt($self->_datetime_today);
    return $self;
}

=head3 set_current_date

=cut

sub set_current_date {
    my ($self) = @_;
    my %time = $self->_time_hash;
    $self->set_today;
    $self->set(%time);
    return $self;
}

sub _time_hash {
    my ($self) = @_;
    return map {$_ => $self->$_} qw/hour minute second nanosecond/;
}


=head3 set_nth_day_of_week($nth, $day_of_week);

=head3 set({year => $y, month => $m, day => $d, ...})

=head3 set_year($year)

=head3 set_month($month)

=head3 set_day($day)

=head3 set_hour($hour)

=head3 set_minute($min)

=head3 set_second($sec)

=head3 set_nanosecond($nsec)

=head3 set_epoch($t)

=head3 set_last_day_of_month

=head3 set_time($time_string)

 $d->set_time("22:10:00");
 $d->set_time("10:10");

If you set the hour which is more than 23,
int($hour / 24) day(s) is(are) added to $d.

=cut

sub set_time {
    my ($self, $str) = @_;
    my ($h, $m, $s) = split /:/, $str;
    Carp::croak('time format is \d{2}:\d{2} or \d{2}:\d{2}:\d{2}') if not defined $m;
    if (my $d = int($h / 24)) {
        $self->add(day => $d);
        $h %= 24;
    }
    $self->set_hour($h);
    $self->set_minute($m);
    $self->set_second($s) if defined $s;
    return $self;
}

sub set_epoch {
    my($self, $t) = @_;

    # The following code doesn't work.
    # $self->_dt($self->_dt->from_epoch(epoch => $t));
    # So I implement as the following.

    defined $t or return;
    my ($sec, $min, $hour, $mday, $mon, $year) = (localtime $t)[0 .. 7];
    $year += 1900;
    $mon++;

    $self->_dt->set(year => $year, month => $mon, day => $mday, hour => $hour, minute => $min, second => $sec);

    return $self;
}


=head2 methods for getting specified format

=head3 $date_string = ymd($delimiter)

It is as same as ymd in DateTime.
When you omit $delimiter, "-" is used.

 $d->ymd; # 2007-01-01

=head3 $time_string = hms($delimiter)

It is as same as hms in DateTime.
When you omit $delimiter, ":" is used.

 $d->hms; # 10:00:00

=head3 $formatted_datetime_string = strftime($format)

see L<strftime>

You can use name in L<Allowed Date and Time Notation>>(constant value -- you need to use C<Wiz::DateTime::Formatter>).
When you omit $format, the format set by c<set_format> is used as $format(default is C<GENERAL>).

=head3 $formatted_datetime_string = to_string($format);

It is as same as strftime.

=head3 $offset_string = offset_string($format);

It returns offset string.
If you omit $format, it returns the offset string like "+0900".

If you want other format, you can specify the format as sprintf format.

 $offset_string = offset_string("%s02d:02d"); # +09:00

=cut

sub to_string {
    my($self, $format) = @_;
    $format ||= $self->strftime_format;
    return ref $self->_dt ? ref $format eq 'CODE' ? $format->($self) :
                            $self->_dt->strftime($format)            :
                            '';
}

sub strftime {
    return shift()->to_string(@_);
}

=head2 methods for operation/calculation

These sort of methods except C<delta> changes the object itself and returns itself.

=head3 add(year => $y, month => $m, day => $d, $hour => $h, second => $s,..., end_of_month => $option)

You can use the following keys:

 year
 month
 day
 hour
 minute
 second
 nanosecond
 weekday
 end_fo_month

end_of_month takes the following 3.

=over 4

=item limit (default)

 1/31 + 1 month = 2/28
 1/27 + 1 month = 2/27

=item preserve

 2/28 + 1 month = 3/31
 2/27 + 1 month = 3/27

=item wrap

 1/31 + 1 month = 3/03
 1/28 + 1 month = 2/28

=back

Default endo_of_month can be changed by C<set_end_of_month> method.

=cut

sub add {
    my ($self, @args) = @_;

    if(ref $args[0] and $args[0]->is_unit) {
        $self->_overload_add_self($args[0]);
    }else {
        my %args = @args;
        $self->_to_dt_args(\%args);
        $self->_dt->add(%args);
    }
    return $self;
}

sub _add { # add but return new object
    my ($self, @args) = @_;
    my $adt = $self->clone;

    if(ref $args[0] and $args[0]->is_unit) {
        $adt->_overload_add_self($args[0]);
    }else {
        my %args = @args;
        $self->_to_dt_args(\%args);
        $adt->_dt->add(%args);
    }
    return $adt;
}


=head3 subtract($datetime_object)

And you can use as same keys as you can use for add.

=cut

sub subtract {
    my $self = shift;
    $self->delta(shift) if ref $_[0] eq __PACKAGE__;
    my @args = @_;

    if(ref $args[0] and $args[0]->is_unit) {
        $self->add($args[0] * -1);
    } else {
        my %args = @args;
        $self->_to_dt_args(\%args);
        $self->_dt->subtract(%args);
    }
    return $self;
}

=head3 add_weekday($n)

when you want to get object after/before some weekdays.

 $d->add_weekday(1);  # as same as next_weekday
 $d->add_weekday(-1); # as same as last_weekday
 $d->add_weekday(5);
 $d->add_weekday(-5);

=head3 round($term)

When $d is '2007-02-03 04:05:06':

 $d->round('year');         # 2007-01-01 00:00:00
 $d->round('month');        # 2007-02-01 00:00:00
 $d->round('day');          # 2007-02-03 00:00:00
 $d->round('hour');         # 2007-02-03 00:00:00
 $d->round('minuite');      # 2007-02-03 04:00:00
 $d->round('second');       # 2007-02-03 04:05:00
 $d->round('nanosecond');   # 2007-02-03 04:05:06 ...

=head3 end($term);

When $d is '2007-02-03 04:05:06':

 $d->end('month');          # 2007-12-31 23:59:59
 $d->end('day');            # 2007-02-28 23:59:59
 $d->end('hour');           # 2007-02-03 23:59:59
 $d->end('minute');         # 2007-02-03 04:59:59
 $d->end('second');         # 2007-02-03 04:05:59

=head3 $d_delta = delta($d)

It returns L<Wiz::DateTime::Delta> object
which has term between two objects.

Wiz::DateTime::Delta object has some methods.

 my $d1 = DateTime->new('2007-02-02');
 my $d2 = DateTime->new('2006-01-01');
 my $delta = $d1->delta($d2); it is as same as $d1 - $d2

=over 4

=item year

 $delta->year;  # 1

=item month

 $delt->month; # 25

=item day

 $delta->day;   # 397

=item hour

 $dlta->hour;  # 9528

=item minute

 $dlta->minute; # 571680

=item second

 $dlta->second; # 34300800

=back

seee L<Wiz::DateTime::Delta>, more detail.


=head2 methods for validation

This type of methods can take nothing, object or string as argument and returns boolean value(1/0).

for example:

 $d->is_holiday;
 $d->is_holiday($dt);
 $d->is_holiday('2007-01-01');

=head3 $bool = is_today

It judges given DateTime object/date string/itself is today or not.

=head3 $bool = is_holiday

It judges a given DateTime object/date string/itself is holiday or not.

 $bool = $d->is_holiday;
 $bool = $d->is_holiday;

=head3 $bool = is_date_type($date_type)

It judgees a given DateTime object/date string/itself is specified date type or not.

 $bool = $d->is_date_type('holiday')

date type is defined in L<Date Definition Rule>.
for example, the following rule:

   ymd:
     '*-10-06':
       is_holiday: 0
       is_birthday: 1
       name: my birthday

And $d is '2007-10-06' and $d2 is '2007-10-08'

 $d->is_date_type("birthday"); # true
 $d->is_date_type("birthday", $d2); # false

If you want to specify date definition,
you can write as the following.

 $d->is_date_type("holiday", "cn");
 $d->is_date_type("holiday", $d2, "cn");

As default, C<prior_date_definition> is used.

=head3 $bool = is_weekday

It judges given DateTime object/date string/itself is weekday or not.

=head3 $bool = is_leap_year

It judges given DateTime object/date string/itself is leap year or not.

=head3 $bool = is_leap_month

It judges given DateTime object/date string/itself is leap month or not.

=head3 $bool = between($d1, $d2)

It checks object is in $d1 and $d2(including $d1 and $d2).
You can use date and time string instead of object.

 my $bool = $d->between('2000-10-06', '2007-10-06');

=head2 Methods to get date information

=head3 $number_of_day_of_week = day_of_week

It returns day of the week.
(Monday .. Sunday) = (1 .. 7)

=head3 $year = year

It returns year.

=head3 $month = month

It returns month.

=head3 $day = day

It returns day.

=head3 $hour = hour

It returns hour.

=head3 $minute = minute

It returns minutes.

=head3 $second = second

It returns seconds.

=head3 $microsecond = microsecond

It returns microseconds.

=head3 $nanosecond = nanosecond

It returns nanoseconds.

=head3 $ecpoch = epoch

It returns epoch time.

=head3 $age = age($d);

An object is regarded as birthdate and
it checks object's age upto $d.

If $d is omitted, current time is used.

 if ($d->age > 19) {
     # $d is over 19 years old
 }

If you want one's Xth year, use asian_age instead.

=head3 $age = asian_age($d);

It is similar to C<age>. Just add 1 year to the result of C<age>.

=head3 $dt = birthdate_range($age, $age2)

$age2 is optional.

It returns new 2 object which is the range of birthdate for gven age(s).
This object is rounded/ended by day.

=head3 $dt = asian_birthdate_range($asian_age, $asian_age2)

It is similar to C<birthdate>. Given age must be one's Xth year.

=head1 OPERATOR OVERLOAD

It is for operation of date unit.
If you want to add years, months or seconds, use C<add> or C<subtract> instead.

=head2 +, -

right value can take following.

 number
 DateTime::Duration object
 Wiz::DateTime object (subtract only)
 DateTime object (subtract only)

for example;

 $d = new Wiz::DateTime->new(date => '2007-01-01')

 $d += DateTime::Duration(years => 1); # 2008-01-01
 $d -= 2 * DAY; # 2006-12-30
 $d += 1 * DAY; # 2006-12-31
 
 my $duration = $d - DateTime->new(year => 2007, month => 1, day => 2);

=head2 ==, eq, >(gt), <(lt), <=>(cmp)

right value can take the following.

 Wiz::DateTime object (subtract only)
 DateTime object (subtract only)

=cut

use overload 
    '""'  => \&to_string,
    'bool'=> sub { shift; },
    '>'   => \&_overload_gt,
    '<'   => \&_overload_lt,
    '<=>' => \&_overload_cmp,
    'cmp' => \&_overload_cmp,
    'eq'  => \&_overload_eq,
    '=='  => \&_overload_eq,
    '+'   => \&_overload_add,
    '-'   => \&_overload_subtract,
    '+='  => \&_overload_add_self,
    '-='  => \&_overload_subtract_self,
    ;

=head1 Allowed Date and Time Notation

The following notations are allowed.
Their names can be used for the argument of C<parse>, C<set_parse_format> and C<set_format>.
When you use their names as the argument of C<set_format>, the notation added "*" is used.

The following examples are bollowed from TripleTail::DateTime.

=head2 GENERAL

Their formats can take offset like "+0900";

  * YYYY-MM-DD HH:MM:SS
    YYYY-MM-DD
   
    YYYY/M/D H:M:S
    YYYY-M-D
    
    YYYY/MM/DD HH.MM.SS
    YYYY@MM@DD
    YYYYMMDDHHMMSS

    HH:MM:SS
    H:M:S
    HH:MM
    H:M
    HH.MM.SS
    H.M.S
    HH.MM
    H.M

The last 8 formats are only for time. Year, month and day is set as '1970-01-01'.

=head2 GENERAL_DETAIL

This is only formatter.

   YYYY-MM-DD HH:MM:SS.msec TZ
   (2007-01-01 10:15:11.0 Asia/Tokyo)

TZ may be offset(for example, +0900).

=head2 TIME

   HH:MM:SS
   (10:15:11)

=head2 TIME_DETAIL

   HH:MM:SS.msec
   (10:15:11.0)

=head2 DATE

 * Wdy Mon DD HH:MM:SS TIMEZONE YYYY
   (Fri Feb 17 11:24:41 JST 2006)

=head2 ACCESS_LOG

 * DD/Mon/YYYY:HH:MM:SS +TTTT
   (17/Feb/2006:11:24:41 +0900)

=head2 ERROR_LOG

 * Wdy Mon DD HH:MM:SS YYYY
   (Fri Feb 17 11:24:41 2006)

=head2 APACHE_DIRINDEX

 * DD-Mon-YYYY HH:MM:SS
   (17-02-2007 11:24:41 2006)

=head2 MYSQL

 * YYYY-MM-DD HH:MM:SS

=head2 DB2

 * YYYY-MM-DD-HH.MM.SS
   YYYY-MM-DD HH.MM.SS
   YYYY-MM-DD HH.MM.SS.sss

=head2 RFC822

 * Wdy, DD-Mon-YY HH:MM:SS TIMEZONE
   (Fri, 17-Feb-06 11:24:41 +0900)
 
   Wdy, DD-Mon-YYYY HH:MM:SS TIMEZONE
   (Fri, 17-Feb-2006 11:24:41 +0900)

=head2 RFC850

 * Wdy, DD-Mon-YY HH:MM:SS TIMEZONE
   (Fri, 17-Feb-06 11:24:41 JST)
 
   Wdy, DD-Mon-YYYY HH:MM:SS TIMEZONE
   (Fri, 17-Feb-2006 11:24:41 JST)

=head2 W3C

 * YYYY-MM-DDTHH:MM:SS.sTzd
   (2006-02-17T11:40:10.45+09:00)
 
   YYYY-MM-DDTHH:MM:SSTzd
   (2006-02-17T11:40:10+09:00)
 
   YYYY-MM-DDTHH:MMTzd
   (2006-02-17T11:40+09:00)
 
   YYYY-MM-DD
   YYYY-MM

=head2 TAI64N

 * @40000000474ec9e20eeb4260
   (= 2007-11-29 23:16:56)

=head2 ANY

It is special name for parsing datetime string.
If you use this to parse, all format in the above can be parsed.
Of course it is slow because test many patterns.

=head1 Date Definition Rule

you can write 2 way to write holiday rule.
holiday rule structure is following hash ref.

   {
     'calendar' =>
     {
       'gregorian' =>
       {
        # month-day(MM-DD)
        month_day =>
        {
         '01-01' => {
                     is_holiday => 1,
                     name       => ['new year day']
                    },
        },
        # day of week(YYYY-MM-WDAY_NO)
        #  WDAY_NO 1 .. 7(Mon .. Sun)
        #  * is any
        weekday =>
        {
         '*-*-0'  => {
                      is_holiday => 1,
                      name       => ['Sun.'],
                     },
         '*-*-7'  => {
                      is_holiday => 1,
                      name       => ['Sat.'],
                     },
        },
        # Year Month Day(YYYY-MM-DD)
        #  * is any
        ymd => {
                '*-10-06'  => {
                               is_holiday => 0,
                               name       => ['my birthday'],
                              },
               },
       },
     },
     substitute_holiday        => 'substitute holiday name as "furikae kyujitsu"'
     enable_substitute_holiday => 1, # not yet implement
    }


YAML Style

 ---
 calendar:
   gregorian:
     md:
       01-01:
         is_holiday: 1
         name: new year day
     wday:
       '*-*-0':
         is_holiday: 1
         name: Sun.
       '*-*-6':
         is_holiday: 1
         name: Sat.
     ymd:
       '*-10-06':
         is_holiday: 0
         name: my birthday
 substitute_holiday: substitute holiday name as "furikae kyujitsu"
 enable_substitute_holiday: 1

For more detail, see Wiz::DateTime::Definition.

=head1 TODO

=head1 SEE ALSO

L<Wiz::DateTime::Definition>
L<Wiz::DateTime::Delta>
L<Wiz::DateTime::Unit>

=head1 AUTHOR

Kato Atsushi, C<< <kato@adways.net> >>

=head1 COPYRIGHT & LICENSE

Copyright 2008 The Wiz Project. All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice,
this list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright
notice, this list of conditions and the following disclaimer in the
documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE WIZ PROJECT ``AS IS'' AND ANY
EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED.  IN NO EVENT SHALL THE WIZ PROJECT OR CONTRIBUTORS BE
LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER
IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OROTHERWISE)
ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
THE POSSIBILITY OF SUCH DAMAGE.

The views and conclusions contained in the software and documentation are
those of the authors and should not be interpreted as representing official
policies, either expressed or implied, of the Wiz Project.

Additionally, the followings are recommended for the developers
to modify/improve/extend Wiz. Please send modified code/patch to mail list,
wiz-perl@googlegroups.com.
The source you sent will be merged into Wiz package.
We welcome anyone who cooperates with us in developing this software.

We'll invite you to this project's member.

=cut

BEGIN {
    my @datetime_methods = qw/year month day hour minute second
                     microsecond nanosecond epoch ymd hms
                     day_of_week wday dow
                     is_leap_year is_leap_month is_leap_second
                     set_time_zone set offset
                    /;
    no strict "refs";
    foreach my $method (@datetime_methods) {
        if (not defined &{$method}) {
            *{$method} = sub {
                my ($self, @args) = @_;
                return $self->_dt->$method(@args);
            };
        }
    }

    my @datetime_set_methods = qw/year month day hour minute second nanosecond/;
    foreach my $method (@datetime_set_methods) {
        if (not defined &{'set_' . $method}) {
            *{"set_" . $method} = sub {
                my ($self, $value) = @_;
                $self->_dt->set($method => $value);
                return $self;
            };
        }
    }
}

{
    my @adt_keys = qw(year month day hour minute second nanosecond microsecond);

    sub _to_dt_args {
        my ($self, $args) = @_;
        my %new_args;
        $new_args{end_of_month} ||= $self->get_end_of_month;
        foreach my $key (@adt_keys) {
            $new_args{$key . 's'} = $args->{$key} if exists $args->{$key};
        }
        %$args = %new_args;
        return $args;
    }
}

sub age {
    my ($self, $d) = @_;
    my $age;
    my $code; # = $self->age_counter();
    if (defined $code and ref $code eq 'CODE') {
        $age = $code->($self, $d);
    } else {
        my $d1 = $self->clone;
        my $d2 = @_ == 2 ? $d->clone : $self->now;
        $d1->round('day');
        $d2->round('day');
        $age = ($d2 - $d1)->year;
        # if $age < 0, do something ??
    }
    return $age;
}

sub asian_age {
    my ($self, $d) = @_;
    return $self->age($d) + 1;
}

sub birthdate_range {
    my ($self, $age, $age2) = @_;

    if (@_ == 3 and $age > $age2) {
        ($age2, $age) = ($age, $age2);
    }

    my $max_dt = $self - $age * Wiz::DateTime::Unit::YEAR;
    my $min_dt = $self - ((@_ == 3 ? $age2 : $age) + 1) * Wiz::DateTime::Unit::YEAR;

    my $is_leap = ($self->month == 2 and $self->day == 29) ? 1 : 0;

    # it is only Japanese law?
    foreach ($min_dt, $max_dt) {
        if ($is_leap and not $_->is_leap_year) {
            $_->set(month => 2, day => 28);
        } else {
            $_->set(month => $self->month, day => $self->day);
        }
    }
    $min_dt->add(day => 1);
    $min_dt->round('day');
    $max_dt->end('day');

    return $min_dt, $max_dt;
}

sub asian_birthdate_range {
    my $self = shift;
    return $self->birthdate_range(map $_ - 1, @_);
}

sub last_day_of_month {
    my ($self) = @_;
    my $adt    = $self->new();
    my $dt = $self->_datetime_last_day_of_month;
    $adt->_dt($dt);
    return $adt;
}

sub set_last_day_of_month {
    my ($self) = @_;
    $self->_dt($self->_datetime_last_day_of_month);
    return $self;
}

sub _datetime_last_day_of_month {
    my ($self) = @_;
    my $dt = $self->_dt;
    return DateTime->last_day_of_month(map {$_ => $dt->$_} (qw/year month time_zone/));
}

sub time_zone {
    my ($self) = @_;
    return 'local' if not blessed $self or not blessed $self->_dt;
    return $self->_dt->time_zone->name;
}

sub _time_zone {
    my ($self) = @_;
    return LOCAL if not blessed $self or not blessed $self->_dt;
    return $self->_dt->time_zone
}

sub parse {
    my $self = shift;
    $self = $self->new() if not blessed $self;
    my ($type, $string) = @_ == 1 ? (undef, @_) : (@_);

    my $args = $self->_parse($type, $string);
    Carp::croak "$string cannot be parsed by " . $type  if not $args;
    if (defined $args->{epoch}) {
        # for TAI64N
        $self->set_epoch($args->{epoch});
        $self->set(nanosecond => $args->{nanosecond});
    } elsif($args) {
        $self->_dt($self->_datetime_new(%$args));
    }
    return $self;
}

sub _parse {
    my($self, $type, $string) = @_ == 2 ? (shift, undef, shift) : (@_);
    my $format = PARSER()->{uc($type ?  $type : $self->parse_format)};
    Carp::croak "unknown format: " . defined $type ? $type : 'undef'  unless $format;
    foreach my $regexpcode (@$format) {
        if (my $args = $regexpcode->($string)) {
            return $args;
        }
    }
    return;
}

sub nth_day_of_week {
    my($self, $nth, $day_of_week) = @_;
    if (@_ == 1) {
        my $day = $self->day;
        my $week = $day == 1  ? 0 :
                   $day >= 29 ? 4 : int(($day - 1) / 7);
        return $week + 1;
    } else {
        my $dt = $self->_nth_day_of_week($self->_dt->clone, $nth, $day_of_week);
        my $adt = $self->clone;
        $adt->_dt($dt);
        return $adt
    }
}

sub set_nth_day_of_week {
    my($self, $nth, $day_of_week) = @_;
    $self->_dt($self->_nth_day_of_week($self->_dt, $nth, $day_of_week));
    return $self;
}

sub _nth_day_of_week {
    my($self, $dt, $nth, $day_of_week) = @_;
    $dt->truncate(to => 'month');
    for (1 .. 7) {
        last if $dt->day_of_week == $day_of_week;
        $dt->add(days => 1);
    }
    $dt += DateTime::Duration->new(days => ($nth - 1) * 7);
    if ($dt->month != $self->month) {
        Carp::croak "$nth th week doesn't exist in the month.";
    }
    return $dt;
}

sub add_weekday {
    my ($self, $days) = @_;

    my $unit  = $days < 0 ? -1 : 1;
    my $abs_days = abs $days;
    while ($abs_days-- > 0) {
        $self->_dt->add(days => $unit);
        $abs_days++ if $self->is_holiday;
    }
    return $self;
}

sub _add_weekday { # add but returns the new object
    my ($self, $days) = @_;
    my $adt = $self->clone;

    my $unit  = $days < 0 ? -1 : 1;
    my $abs_days = abs $days;
    while ($abs_days-- > 0) {
        $adt->_dt->add(days => $unit);
        $abs_days++ if $adt->is_holiday;
    }
    return $adt;
}

sub round {
    my ($self, $unit) = @_;
    $self->_dt->truncate(to => $unit);
    return $self;
}

{
    my $_YEAR   = _YEAR   * 2 -1;
    my $_MONTH  = _MONTH  * 2 -1;
    my $_DAY    = _DAY    * 2 -1;
    my $_HOUR   = _HOUR   * 2 -1;
    my $_MINUTE = _MINUTE * 2 -1;

    sub end {
        my ($self, $unit) = @_;
        my $flg =
            $unit eq 'year'   ?  $_YEAR   :
            $unit eq 'month'  ?  $_MONTH  :
            $unit eq 'day'    ?  $_DAY    :
            $unit eq 'hour'   ?  $_HOUR   :
            $unit eq 'minute' ?  $_MINUTE :
            undef;

        # month is needed to be set before day is set.
        $flg & _YEAR  and $self->set(month => 12);
        $flg & _MONTH and $self->_dt($self->_datetime_last_day_of_month);

        my %arg;
        $flg & _DAY    and $arg{hour}   = 23;
        $flg & _HOUR   and $arg{minute} = 59;
        $flg & _MINUTE and $arg{second} = 59;

        $self->set(%arg);
        return $self;
    }
}

sub delta {
    my ($self, $dt) = @_;
    return Wiz::DateTime::Delta->new($self, $dt);
}

sub is_today {
    my ($self, $dt_str) = @_;
    my $adt = defined $dt_str ? ref $dt_str ? $dt_str->clone : $self->new($dt_str)
                              : $self->clone;
    $adt->round('day');

    return $adt->_dt eq $self->today->_dt ? 1 : 0;
}

# sub set_locale {}

sub _overload_gt {
    my ($self, $adt) = @_;
    Carp::croak "not object" unless ref $adt;
    return $self->_dt > $adt->_dt;
}

sub _overload_lt {
    my ($self, $adt) = @_;
    Carp::croak "not object" unless ref $adt;
    return $self->_dt < $adt->_dt;
}

sub _overload_cmp {
    my ($self, $adt) = @_;

    Carp::croak "not object" if not blessed $adt;
    my ($dt1, $dt2) = ($self->_dt, $adt->_dt);
    return $dt1 == $dt2 ? 0 : $dt1 > $dt2
                        ? 1 : -1;
}

sub _overload_eq {
    my ($self, $adt) = @_;

    Carp::croak "not object" if not blessed $adt;
    return $self->_dt == $adt->_dt;
}

sub _overload_add_self {
    my ($self, $v) = @_;
    $self->_overload_add($v, "add");
}

sub _overload_subtract_self {
    my ($self, $unit) = @_;
    $self->_overload_subtract($unit, "add");
}

sub _overload_add {
    my ($self, $unit, $method) = @_;
    $method ||= '_add';
    my $method_weekday = $method . '_weekday';

    my $adt = $self;
    my $reftype = Scalar::Util::reftype $unit;
    my @units = (defined $reftype and $reftype eq 'ARRAY') ? @$unit : $unit;

  UNIT_LOOP:
    foreach my $unit (@units) {
        if (my $unit_name =  _unit_name($unit)) {
            foreach my $n ('Month', 'Year') {
                if ($unit_name eq __PACKAGE__ . '::Unit::' . $n) {
                    $adt = $self->$method(lc($n) => $$unit);
                    next UNIT_LOOP;
                }
            }
            if ($unit_name eq __PACKAGE__ . '::Unit::Weekday') {
                $adt = $self->$method_weekday($$unit);
            }
        } else {
            $adt = $self->$method(second => $unit);
        }
    }
    return $adt;
}

sub _overload_subtract {
    my ($self, $unit, $method) = @_;

    if (ref $unit eq __PACKAGE__) {
        return $self->delta($unit, $method);
    } else {
        $unit *= -1;
        return $self->_overload_add($unit, $method);
    }
}

sub _unit_name {
    my ($unit) = @_;
    my $unit_name = ref $unit;
    my $unit_class_prefix = __PACKAGE__ . '::Unit::';
    if (defined $unit and $unit_name =~ /^$unit_class_prefix/) {
        return $unit_name;
    } elsif ($unit =~ /^-?\d+$/) {
        return undef;
    } else {
        Carp::croak "need number or " . __PACKAGE__ . "::Unit::* object. got :" . $unit;
    }
}

sub set_date_definition {
    my $self = shift;

    if (defined $_[0] and ($_[0] eq 'yml' or $_[0] eq 'yaml')) {
        # parse yaml file
        my $yml_file = $_[1];
        $self->{_date_definition} = [{$yml_file => YAML::Syck::LoadFile($yml_file)}];
        $self->set_prior_date_definition($self->{_date_definition}->[0]);
    } elsif (defined $_[0] and ref $_[0] eq 'HASH') {
        # hash structure
        Carp::croak "need hash name" unless $_[1];
        $self->{_date_definition} = [{$_[1] => shift}];
        $self->set_prior_date_definition($self->{_date_definition}->[0]);
    } else {
        # definition name(s)
        my @_date_definition;
        push @_date_definition, (ref $_[0] ? @{$_[0]} : @_);

        if (@_date_definition) {
            my @prior_date_defs;
            my @date_definition;
            foreach my $def (@_date_definition) {
                next if not $def;
                my @defs = split /\+/, $def;
                if ( $def =~ /\+/) {
                    push @prior_date_defs, @defs;
                }
                push @date_definition, @defs;
            }
            $self->{_date_definition} = [@date_definition];
            if (@prior_date_defs){
                $self->set_prior_date_definition(\@prior_date_defs);
            } elsif (@date_definition) {
                $self->set_prior_date_definition([$date_definition[0]]);
            }
        }
    }
    return $self->{_date_definition};
}

sub date_definition {
    my ($self) = @_;
    return wantarray ? @{$self->{_date_definition}} : [@{$self->{_date_definition}}];
}

sub between {
    my ($self, $d1, $d2) = @_;
    # Carp::croak "former object must be lesser than later object" if $d2 > $d1;
    return $d1 <= $self and $self <= $d2 ? 1 : 0;
}

sub get_end_of_month {
    my ($self) = @_;
    return $self->{_end_of_month};
}

sub set_end_of_month {
    my ($self, $value) = @_;
    return @_ == 2 ? $self->{_end_of_month} = $value: $self->{_end_of_month};
}

sub offset_string {
    my ($self, $format) = @_;
    $format ||= '%s%02d%02d';
    my $offset = $self->offset / 60 / 60;
    my ($sign, $n1, $n2) = (($offset < 0 ? '-' : '+'), $offset, 0);
    return sprintf $format, $sign, $n1, $n2;
}

sub is_holiday {
    my ($self, $dt_str) = @_;
    my $adt;

    if (not defined $dt_str) {
        $adt = $self;
    } elsif (ref $dt_str) { # dt
        $adt = $dt_str;
    } else { # scalar
        $adt = $self->new($dt_str, scalar $self->prior_date_definition);
    }

    my $date_data = Wiz::DateTime::Definition->date_data($adt, scalar $adt->prior_date_definition);
    return $date_data->{is_holiday} || 0;
}

sub is_weekday {
    my ($self) = @_;
    return ! $self->is_holiday || 0;
}

sub set_prior_date_definition {
    my ($self, @defs) = @_;
    @defs = @{$defs[0]} if ref $defs[0] eq 'ARRAY';
    $self->{_prior_date_defs} = \@defs;
}

sub prior_date_definition {
    my ($self) = @_;
    return wantarray ? @{$self->{_prior_date_defs}} : $self->{_prior_date_defs};
}

sub is_date_type {
    my ($self, $type, @dd_names) = @_;
    my $date;

    @dd_names = @{$dd_names[0]} if ref $dd_names[0] eq 'ARRAY';
    $date = shift @dd_names     if ref $dd_names[0];

    @dd_names = $self->prior_date_definition  if not @dd_names;

    if (not @dd_names) {
        Carp::croak "is_date_type method require date definition(s) or set_date_definition before using the method.";
    }

    my $test_dt = $date || $self;
    my $data_type = Wiz::DateTime::Definition->date_data($test_dt, @dd_names);
    return $data_type->{'is_' . $type} || 0;
}

1; # End of Wiz::DateTime
