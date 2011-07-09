package Wiz::DateTime::Definition;

use strict;
use warnings;

use Carp ();

=head1 NAME

Wiz::DateTime::Definition - Date definition base class

=head1 VERSION

version 1.0

=cut

our $VERSION = '1.0';

=head1 SYNOPSIS

 package Wiz::DateTime::Definition::JP;
 
 use base qw/Wiz::DateTime::Definition/;
 
 sub _date_definition {
     return
         {
            #....
         };
 }

=head1 DESCRIPTION

It is DateTime definition base class.
If you create new definition, you must inherit this module.

=head1 METHODS

=head2 $date_data = date_data($dt, @date_definition_names);

$date_data is the following structure.

 {
    name                  => ['Sunday'],
    is_holiday            => 1,
    is_substitute_holiday => 1,
    # is_* can be used
 }

=head2 $date_data_detail = date_data_detailed($dt);

If you don't pass date definition name(s).
It returns the following structure.

 {
  name       => {
                 STANDARD => ['Sunday'],
                 JP       => ['日曜日'],
                },
  is_holiday => {
                 STANDARD => 1,
                 JP       => 1,
                }
 }

=head2 ($class_name, $date_definition) = date_definition($date_definition_name);

=head1 SUB CLASSING

This class is base class of Wiz::DateTime::Definition::* modules.
If you want to create new date definition, normally you create C<_date_definition>
in your sub class. For example, Wiz::DateTime::Definition::STANDARD:

 package Wiz::DateTime::Definition::STANDARD;
 
 use strict;
 use warnings;
 
 use base qw/Wiz::DateTime::Definition/;
 
 sub _date_definition {
    return
        {
         calendar =>
         {
          gregorian =>
          {
           weekday =>
           {
            '*-*-7'  => { name => ['Sunday']  , is_holiday => 1 },
            '*-*-6'  => { name => ['Saturday'], is_holiday => 1 },
           },
          },
         },
         substitute_holiday => 'Substitute Holiday',
        };
 }

=head2 HOW TO CHANGE BEHAVIOR

If you want change other behavior. you can override the following methods.

 _rest_month_day
 _rest_weekday
 _rest_ymd

If you want to need other method or replace all the above method,
you can override the following method.

 sub _date_definition_methods {
     return qw/_rest_month_day _rest_weekday _rest_ymd/;
 }

Method names in the C<_date_definition_methods> are executed in order.
So, if you override this method, you can change all behavior of generating date data.

If you want to change substitute holiday behavior, you need to change.

=head2 CONVERT DATETIME OBJECT

If you need to convert datetime object, you can use 'convert_' + calendar_name method.
calendar name is like 'gregorian'. For example Wiz::DateTime::Definition::CN has;

 sub convert_lunar_cn {
     my ($self, $dt) = @_;
     my $d = Calendar->new_from_Gregorian($dt->month, $dt->day, $dt->year)->convert_to_China;
     $dt->set(map { $_ => $d->$_ } qw/year month day/);
     return $dt;
 }

CN module has 'lunar_cn' in C<_date_definition>. The definition in it is checked with converted date.
See CN module for detail.

=head1 DEFINITION RULE

JP module and CN module is complicate example. Take a glance.

=head2 ABSTRACT STRUCTURE

 {
  calendar => {
   # for gregorian calendar
   gregorian => {
    month_day => {
      [MONTH_DAY] => [DAY_DEFINITION]
    },
    weekday => {
      [WEEKDAY] => [DAY_DEFINITION]
    },
    ymd => {
      [YMD] => [DAY_DEFINITION]
    },
   },
   # for example lunar calendar
   [OTHER_CALENDAR_TYPE] => {
     # structure is as same as the above
   }
  },
  substitute_holiday => [SUBSTITUTE_DEFINITION]
 }

=head2 [DAY_DEFINITION]

DAY_DEFINITION is the following;

 {
   name       => ['holiday_name'],
   is_holiday => 1,
   range      => [$begin_year, $end_year, \@except_year]
 }

name is this day's name.
is_holiday means the day is holiday and any is_* key can be used.
range is target year to apply this definition.
If range is set, the definition is applied from $begin_year to $end_year except years in @except_year.
$begin_year or $end_year can be set 0. If $begin_year is 0, the range is any year to $end_year.
If $end_year is 0, the range is $begin_year to any year.

For example;

 {
   name => ["people's holiday"],
   is_holiday => 1,
    range => [1988, 2006, [1992, 1997, 1998, 2003]]
 }

This can be array ref of [DAY_DEFINITION]

 [
  {
    name => ["people's holiday"],
    is_holiday => 1,
    range => [1988, 2006, [1992, 1997, 1998, 2003]]
  },
  {
    name => ['green day'],
    is_holiday => 1,
    range => [2007]
  }
 ]

If same key has multiple definition, use this.

=head2 [SUBSTITUTE_DEFINITION]

It is as nearly same as [DAY_DEFINITION]
except is_* key cannot be used and
cannot use array ref for [SUBSTITUTE_DEFINITION].

 {name => 'substitute holiday', range => [1973]},

If you want to define only name. you can use just scalar value.

 'substitute holiday',

=head2 [MONTH_DAY]

 'MMDD'

MM is month, DD is day.
For example, '0101' is Jan. 1st.

=head2 [WEEKDAY]

 'MM-N-W'

MM is month, 'W' of N-W is day of the week name,
and 'N' is #th number of the day which is specified as 'W'.

For example,

 '01-1-1'

This means First Monday in Jan.

You can use '*' as wild card.
For example, '*-*-6' means every Saturday.

=head2 [YMD]

 'YYYY-MM-DD'

YYYY is year and MM is month and DD is day.
For example, '2007-10-05'.

=head2 [OTHER_CALENDAR_TYPE]

If your holiday is based on not gregorian calendar.
You have to use this and have to implement convert_* method.

For example, CN module has the key 'lunar_cn'.

  lunar_cn => {
    # definition ...
  }

and the following method is implemented.

 sub convert_lunar_cn {
     my ($self, $dt) = @_;
     my $d = Calendar->new_from_Gregorian($dt->month, $dt->day, $dt->year)->convert_to_China;
     $dt->set(map { $_ => $d->$_ } qw/year month day/);
     return $dt;
 }

This method return new Wiz::DateTime object
for Chinese lunar calendar from gregorian calendar object.

=head1 SEE ALSO

L<Wiz::DateTime>
L<Wiz::DateTime::Definition::JP>
L<Wiz::DateTime::Definition::CN>

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


sub date_data {
    my ($self, $dt, @dd_names) = @_;
    Carp::croak "need data definition name(s) or date definition hash" unless @dd_names;

    if (ref $dd_names[0] eq 'HASH') {
        my %def = %{$dd_names[0]};
        return $self->_date_data($dt, %def);
    } else {
        my $dd_name = ref $dd_names[0] ? [@{$dd_names[0]}] : [@dd_names];
        $dt = $dt->clone;
        return $self->_date_data($dt, $dd_name);
    }
}

sub date_data_detailed {
    my ($self, $dt) = @_;
    $dt = $dt->clone;
    my $date_data;
    my $_date_data = {};
    my @date_definitions = $dt->date_definition;

    foreach my $dd_name ( @{$dt->date_definition} ) {
        if(ref $dd_name eq 'HASH') {
            my ($name, $def) = %$dd_name;
            $_date_data->{$name} = $self->_date_data($dt, $name, $def);
            @date_definitions = $name;
        } else {
            $_date_data->{$dd_name} = $self->_date_data($dt, $dd_name)
        }
    }

    foreach my $dd_name ( @date_definitions ) {
        push @{$date_data->{name}->{$dd_name} ||= []},
            @{$_date_data->{$dd_name}->{name} ||= []};
        foreach my $type (grep $_ =~ /^is_/, keys %{$_date_data->{$dd_name}}) {
            $date_data->{$type}->{$dd_name} = $_date_data->{$dd_name}->{$type};
        }
    }
    return $date_data;
}

sub date_definition {
    my ($self, $dd) = @_;
    Carp::croak "need date definition." unless $dd;
    my $class = $dd !~/::/ ? __PACKAGE__ . '::' . uc $dd : $dd;
    unless (exists $::{$class . '::'}) {
        eval "use $class;";
        die $@ if $@;
    }
    my $date_def = $class->_date_definition;
    if (not exists $date_def->{calendar}) {
        Carp::croak "invalid definition: $class";
    }
    return $class, $date_def;
}

sub _date_data{
    my($self, $dt, $dd_name, $_date_def) = @_;
    my $date_data = { name => [] };

    my @dd_names = ref $dd_name eq 'ARRAY' ? @$dd_name : $dd_name;

    foreach my $dd_name (@dd_names) {
        my ($dd_class, $date_def);

        if (not defined $_date_def) {
            ($dd_class, $date_def) = $self->date_definition($dd_name);
        } else {
            $dd_class = __PACKAGE__;
            $date_def = $_date_def;
        }

        foreach my $calendar_type (keys %{$date_def->{calendar}}) {
            my $new_dt;
            if ($dd_class->can(my $convert_method = "convert_" . $calendar_type)) {
                $new_dt = $dd_class->$convert_method($dt => $calendar_type);
            } else {
                $new_dt = $dt->clone;
            }
            foreach my $method ($self->_date_definition_methods) {
                $dd_class->_into_date_data(
                     $new_dt,
                     $date_data,
                     $dd_class->$method($date_def, $calendar_type, $new_dt)
                    );
            }
        }
    }
    return $date_data;
}

sub _date_definition_methods {
    return qw/_rest_month_day _rest_weekday _rest_ymd/;
}

sub _rest_weekday {
    my ($self, $dd, $s, $dt) = @_;
    my $date_data = {};

    my $rest_wday = $dd->{calendar}->{$s}->{weekday};
    if (my $data = $self->has_rest_weekday($rest_wday, $dt)) {
        $self->_into_date_data($dt, $date_data, $data);
    }
    return $date_data;
}

sub _rest_month_day {
    my ($self, $dd, $s, $dt) = @_;
    my $rest_month_day = $dd->{calendar}->{$s}->{month_day};
    my $rest_ymd       = $dd->{calendar}->{$s}->{ymd};
    my $date_data = {};

    my $date   = sprintf "%02d%02d", $dt->month, $dt->day;
    if (my $data = $rest_month_day->{$date}) {
        $self->_into_date_data($dt, $date_data, $data);
    } else {
        my $ldt = $dt->clone->add(day => -1);
        if (
            # if last day is Sunday(7) and last day is holiday,
            # substitute holiday
            $ldt->day_of_week == 7 and
            ($self->has_rest_month_day($rest_month_day, $ldt) or
             $self->has_rest_ymd($rest_ymd, $ldt))
           ) {
            # substitute holiday
            my $data = $self->has_rest_month_day($rest_month_day, $dt)
                || $self->has_rest_ymd($rest_ymd, $dt);
            if (not $data) {
                my $name;
                if (ref $dd->{'substitute_holiday'}) {
                    $name = $dd->{'substitute_holiday'}->{name};
                    return unless $self->_check_in_range($dd->{'substitute_holiday'}, $dt);
                } else {
                    $name = $dd->{'substitute_holiday'};
                }
                $data = {
                         is_holiday            => 1,
                         is_substitute_holiday => 1,
                         name                  => [$name],
                        };
            }
            $self->_into_date_data($dt, $date_data, $data);
        }
    }
    return $date_data;
}

sub _rest_ymd {
    my ($self, $dd, $s, $dt) = @_;
    my $rest_ymd = $dd->{calendar}->{$s}->{ymd};
    my $year   = sprintf "%04d", $dt->year;
    my ($month, $day) = map {sprintf("%02d", $_)} ($dt->month, $dt->day);

    my $date_data = {};
    if (my $data = $rest_ymd->{sprintf("%04d-%02d-%02d", $year, $month, $day)}) {
        $self->_into_date_data($dt, $date_data, $data);
    }
    return $date_data;
}

sub _into_date_data {
    my ($self, $dt, $date_data, $data) = @_;
    if (ref $data eq 'ARRAY') {
        foreach my $d (@$data) {
            $self->_into_date_data($dt, $date_data, $d);
        }
        return;
    }

    return unless $self->_check_in_range($data, $dt);

    $date_data->{name} = [$date_data->{name}] if not ref $date_data->{name} and $date_data->{name};
    $data->{name}      = [$data->{name}]      if not ref $data->{name}      and $data->{name};

    push(@{$date_data->{name} ||= []}, @{$data->{name} || []});
    foreach my $type (grep $_ =~ /^is_/, keys %$data) {
        $date_data->{$type} ||= $data->{$type};
    }

    return;
}


sub has_rest_month_day {
    my ($self, $month_day_def, $dt) = @_;
    if (my $def = $month_day_def->{sprintf "%02d%02d", $dt->month, $dt->day}) {
        my @matched;;
        foreach my $_def (ref $def eq 'ARRAY' ? @$def : $def) {
            next unless $self->_check_in_range($_def, $dt);
            push @matched, $_def;
        }
        return \@matched if @matched;
    }
    return;
}

sub has_rest_ymd {
    my ($self, $ymd_def, $dt) = @_;
    if (my $def = $ymd_def->{sprintf "%04d-%02d-%02d", $dt->year, $dt->month, $dt->day}) {
        my @matched;
        foreach my $_def (ref $def eq 'ARRAY' ? @$def : $def) {
            next unless $self->_check_in_range($_def, $dt);
            push @matched, $_def;
        }
        return \@matched if @matched;
    }
    return;
}

sub has_rest_weekday {
    my ($self, $wday_def, $dt) = @_;
    my $date_data = {};
    my $month = sprintf "%02d", $dt->month;
    my $wday  = $dt->day_of_week;
    my $week  = $dt->nth_day_of_week;

    my @def;
    foreach ("$month-$week-$wday", "*-$week-$wday", "*-*-$wday") {
        push @def, $wday_def->{$_} if exists $wday_def->{$_};
    }
    if (@def) {
        my @matched;
        foreach my $_def (map {ref $_ eq "ARRAY" ? @$_ : $_} @def) {
            next unless $self->_check_in_range($_def, $dt);
            push @matched, $_def;
        }
        return \@matched if @matched;
    }
    return;
}

sub _check_in_range {
    my ($self, $data, $dt) = @_;
    if ($data) {
        if (exists $data->{range}) {
            my ($begin, $end, $exception) = @{$data->{range}};
            my $y = $dt->year;
            if (scalar grep $_ == $y, @{$exception || []}) {
                return;
            }
            if ((defined $begin and $y < $begin) or (defined $end   and $y > $end)) {
                return;
            }
        }
        return 1;
    } else {
        return 0;
    }
}

1;
