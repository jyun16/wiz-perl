package Wiz::Web::Calendar::Base;

use strict;
use warnings;
use Template;

=head1 NAME

Wiz::Web::Calendar::Base - base class for Wiz::Web::Calendar::*

=head1 VERSION

version 1.0

=cut

our $VERSION = '1.0';

=head1 SYNOPSIS

 use base qw(Wiz::Web::Calendar::Base);
 
 sub _box_template {
     return <<_TMPL_;
 ... TT Template ...
 _TMPL_
 }
 
 sub _vertical_template {
     return <<_TMPL_;
 ... TT Template ...
 _TMPL_
 }

=head1 DESCRIPTION

This module provides base methods for creating calendar class.
Simply, just write subroutine to return template.

The following methods are useful methods to create complecate
clendar class.

=head1 CONSTRUCTOR

=head2 new

New's arguments are the following.

 dest_url           => '',
 form_name          => 'form',
 method             => 'post',
 js_function_name   => 'move_month',
 added_js           => [],
 year               => 1970,
 month              => 1,
 day                => undef,
 wday_start         => 1,
 range              => [],
 lang               => 'en',
 date_definition    => 'standard',
 current_month_only => 0,
 calendar_attribute =>
 {
     id    => 'calendar',
     class => 'calendar',
 }

=head1 METHODS

=head2 tag

It retunrs tag.

=head2 js

It should be implemented in sub class.
see L<Wiz::Web::Base>.

=head2 hidden

=head2 date_hash

It reutns hash ref contained many date.
For example;

 {
    20070101 => {
       holiday => 1,
       ...
    },
    20070102 => {
       holiday => 0,
       ...
    },
    ...
 }

=head2 date_hash_sorted_list

It reutns array ref of hash ref.
It is the sorted date_hash.

 [
    { # 20070101's data
       holiday => 1,
       ...
    },
    { # 20070102's data
       holiday => 0,
       ...
    },
    ...
 ]

=head2 date_range

When constructor option 'range' is set,
This method returns array ref of date_hash.

=head2 wday_list

It returns (7, 1 .. 6) normaly.
When you set wday_start true, it returns (1 .. 7).

=head2 wday_label

It returns wday label hash like the following.

 {
  1 => 'Mon',
  2 => 'Tue',
  3 => 'Wed',
  4 => 'Thu',
  5 => 'Fri',
  6 => 'Sat',
  7 => 'Sun',
 }

=head2 wday_label_list

It returns the follwoing list;

 (qw/Sun Mon Tue Wed Thu Fri Sat/)

When you set wday_start true, it returns;

 (qw/Mon Tue Wed Thu Fri Sat Sun/)

=head2 style

It returns standard style for calendar.

=cut

use base qw(Wiz::Web::Base);
use Wiz::DateTime;
use Wiz::DateTime::Unit qw/:all/;

use POSIX;

use Wiz qw(get_hash_args);

my $FILTER =
    {
     dest_url => sub {
         my($key, $dt, $value) = @_;
         $value =~ s{\$ymd}{$dt->ymd}ge;
         $value =~ s{\$y}{sprintf '%02d', $dt->year}ge;
         $value =~ s{\$m}{sprintf '%02d', $dt->month}ge;
         $value =~ s{\$d}{sprintf '%02d', $dt->day}ge;
         return $value;
     },
    };

my %LANG_LABEL =
    (
     en => {
            wday => {
                     1 => 'Mon',
                     2 => 'Tue',
                     3 => 'Wed',
                     4 => 'Thu',
                     5 => 'Fri',
                     6 => 'Sat',
                     7 => 'Sun',
                    }
           },
    );

__PACKAGE__->_set_default(
    {
        year               => 1970,
        month              => 1,
        wday_start         => 0,
        range              => [],
        lang               => 'en',
        day                => undef,
        date_definition    => 'STANDARD',
        current_month_only => 0,
        date               => undef,
        month_dest_url     => undef,
        class              => {
                               div      => 'calendar',
                               table    => 'calendar',
                               prev     => 'prev',
                               next     => 'next',
                               holiday  => 'holiday',
                               selected => 'selected',
                              },
    }
);

sub hidden {
    my $self = shift;
    # return qq|<input type="hidden" name="$self->{now_page_param_name}">|;
}

sub tag {
    my $self = shift;
    my %passed_arg = %{get_hash_args(@_)};
    my $tag;
    my $t = Template->new(POST_CHOMP => 1, OUTPUT => \$tag);

    @passed_arg{qw/box vertical/} = $passed_arg{box}      ? (1, 0) :
                                    $passed_arg{vertical} ? (0, 1) :
                                                            (1, 0) ;

    my %arg = (
               year          => $self->year,
               month         => sprintf( "%02d", $self->month),
               class         => $self->class,
               wday_list     => [$self->wday_list],
               wday_label    => $self->wday_label,
              );

    $arg{$_}        = $passed_arg{$_} foreach keys %passed_arg;
    $arg{date_list} = $self->date_hash_sorted_list;

    if (my $url = $self->month_dest_url) {
        my $dt = Wiz::DateTime->new(year  => $self->year,
                                       month => $self->month,
                                       day   => 1,
                                      );
        $arg{month_dest_url} =
            {
             pre  => $self->_filter('dest_url', ($dt - MONTH), $url),
             this => $self->_filter('dest_url', $dt,           $url),
             next => $self->_filter('dest_url', ($dt + MONTH), $url),
            };
    }
    my $template = $arg{box} ? $self->_box_template     :
                                   $self->_vertical_template;

    $t->process(\$template, \%arg);
    return $tag;
}

sub date_hash {
    my $self = shift;
    return $self->_date_hash([$self->year, $self->month, $self->day]);
}

sub date_range {
    my $self = shift;
    my ($start, $end) = @{$self->{range}};
    my $dt_start = Wiz::DateTime->new($start . '-1');
    my $dt_end   = Wiz::DateTime->new($end . '-1');
    my @list;
    Carp::croak "$dt_start > $dt_end" if $dt_start > $dt_end;

    my ($y, $m, $d) = $self->date ? split /-/, $self->date: ();

    my $end_ym = $dt_end->to_string("%Y%m");
    while (my $ym = $dt_start->to_string("%Y%m") <= $end_ym) {
        if (defined $self->date) {
            sprintf("%04d%02d", $y, $m) eq $ym ? $self->day($d) : $self->day(undef);
        }
        push @list, $self->_date_hash([$dt_start->year, $dt_start->month]);
        $dt_start += MONTH;
    }
    return \@list;
}

sub date_hash_sorted_list {
    my $self = shift;
    my $date_hash = $self->date_hash;

    return [map $date_hash->{$_}, (sort {$a <=> $b} keys %$date_hash) ];
}

sub wday_list {
    my $self = shift;
    $self->wday_start ? (1 .. 7) : (7, 1 .. 6);
}

sub wday_label {
    my $self = shift;
    return $LANG_LABEL{$self->lang}->{wday};
}

sub wday_label_list {
    my $self = shift;
    return @{$LANG_LABEL{$self->lang}{wday}}{$self->wday_list};
}

sub _date_hash {
    my ($self, $ymd, $attribute) = @_;
    $attribute->{dest_url} = $self->dest_url if defined $self->dest_url;

    my ($y, $m, $d) = @$ymd;
    my $dt = Wiz::DateTime->new(year  => $y,
                                   month => $m,
                                   day   => 1,
                                   date_definition => [$self->date_definition],
                                  ) or Carp::croak "$y-$m";
    my $day_of_week = $dt->day_of_week;
    my $last_day    = $dt->last_day_of_month;

    my %date;
    my $month_year = sprintf "%04d-%02d", $y, $m;
    my @wday_list = $self->wday_list;
    until ($day_of_week == $wday_list[0]) {
        $dt -= DAY;
        $day_of_week = $dt->day_of_week;
    }
    my ($PREV_MONTH, $IN_MONTH, $NEXT_MONTH) = (1, 2, 4);
    my $status   = 1;
    my $last_flg = 0;
  CAL:
    foreach (1 .. 6) {
        foreach my $wday (@wday_list) {
            my ($y, $m, $d) = split "-", $dt->ymd;
            my $ymd = join "", $y, $m, $d;
            if ($d == 1) {
                if ($status & $IN_MONTH) {
                    last CAL if $wday == $wday_list[0];
                    $last_flg = 1;
                }
                $status <<= 1;
            }
            if ($status & ($PREV_MONTH | $NEXT_MONTH)) {
                if (not $self->current_month_only) {
                    $date{$ymd}= $self->_date_data($dt, $attribute);
                    my $p_or_n = ($status & $PREV_MONTH ? 'prev' : 'next');
                    $date{$ymd}->{$p_or_n . '_month'} = 1;
                    push @{$date{$ymd}->{class}}, $self->class->{$p_or_n};
                }
            } else {
                $date{$ymd}= $self->_date_data($dt, $attribute);
            }
            $dt += DAY;
        }
        last if $last_flg;
    }
    return \%date;
}

sub style {
    my $self = shift;
    my $class = $self->class;
    return <<"_STYLE_";
<style>
$class->{table} td{
   align:right;
}
$class->{table} th {
   align:center;
}
.$class->{prev} {
   color:gray;
   font-size:60%;
}
.$class->{holiday} {
   color:red;
}
.$class->{next} {
   color:gray;
   font-size:60%;
}
.selected {
  background-color:yellow;
}
</style>
_STYLE_

}
# ----[ private ]-----------------------------------------------------

sub _filter {
    my ($self, $key, $dt, $value) = @_;
    return $FILTER->{$key}->($self, $dt, $value);
}

sub _date_data {
    my ($self, $dt, $attribute) = @_;
    my $class = $self->class;
    my %attr;
    foreach my $key (keys %$attribute) {
        $attr{$key} = $self->_filter($key, $dt, $attribute->{$key})
            if defined $attribute->{$key};
    }
    my @class;
    my ($y, $m, $d) = split /-/, $dt->ymd;
    my $selected_day = $self->day || 0;
    if ($selected_day == $d) {
        $attr{selected} = 1;
        push @class, $class->{selected};
    }
    if ($dt->is_holiday) {
        push @class, $class->{holiday};
    }
    return {
            year    => $y,
            month   => $m,
            day     => $d,
            holiday => $dt->is_holiday,
            wday    => $dt->day_of_week,
            class   => \@class,
            %attr,
           };
}

# ----[ static ]------------------------------------------------------

# ----[ private static ]----------------------------------------------

=head1 AUTHOR

Kato Atsushi C<< <kato@adways.net> >>

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

1;

__END__

