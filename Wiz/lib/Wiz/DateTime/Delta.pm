package Wiz::DateTime::Delta;

use strict;
use warnings;

=head1 NAME

Wiz::DateTime::Delta - detla between two Wiz::DateTime object

=head1 VERSION

version 1.0

=cut

our $VERSION = '1.0';

=head1 SYNOPSIS

 use Wiz::DateTime;
 my $d = Wiz::DateTime->new(year => 2006, month => 10, day => 6, time_zone => 'Asia/Tokyo');
 my $d2 = $d->clone;

 $d2 += 365 * 2 * DAY;

 my $delta = $d2 - $d;

 print $delta->year; # 2
 print $delta->day;  # 730

=cut

use base qw(Exporter);

our @EXPORT_SUB = qw();
our @EXPORT_CONST = qw();
our @EXPORT_OK = (@EXPORT_SUB, @EXPORT_CONST);

our %EXPORT_TAGS = (
    'sub'       => \@EXPORT_SUB,
    'const'     => \@EXPORT_CONST,
    'all'       => \@EXPORT_OK,
);


=head1 CONSTRUCTOR

The object of this class is mainly generated when subtract is done with Wiz::DateTime object.
So, you rarely use this constructor.

=head2 $delta = new($d1, $d2)

To create this object, you need 2 Wiz::DateTime object.

 $delta = Wiz::DateTime::Delta->new($d1, $d2);

=head1 METHODS

=head2 $years = year

It returns years from $d1 to $d2.

=head2 $months = month

It returns months from $d1 to $d2.

=head2 $days = day

It returns days from $d1 to $d2.

=head2 $hours = hour

It returns hours from $d1 to $d2.

=head2 $minutes = minute

It returns minutes from $d1 to $d2.

=head2 $seconds = second

It returns seconds from $d1 to $d2.

=head2 $years = year_only

It returns years of the result of $d1->year - $d2->year.

=head2 $months = month_only

It returns months of the result of $d1->month - $d2->month.

=head2 $days = day_only

It returns days of the result of $d1->day - $d2->day.

=head2 $hours = hour_only

It returns hours of the result of $d1->hour - $d2->hour.

=head2 $minutes = minute_only

It returns minutes of the result of $d1->minute - $d2->minute.

=head2 $seconds = second_only

It returns seconds of the result of $d1->second - $d2->second.

=head1 TODO

=head1 SEE ALSO

L<Wiz::DateTime>
L<Wiz::DateTime::Unit>

=head1 AUTHOR

Kato Atsushi, C<< <KTAT@cpan.org> >>

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

use constant UNIT => {
                      # copy from Time::Seconds
                      minute =>         60,
                      hour   =>      3_600,
                      day    =>     86_400,
                      month  =>  2_629_744,
                      year   => 31_556_930,
                     };

BEGIN {
    my @methods = qw/year month day hour minute second/;
    no strict "refs";
    foreach my $method (@methods) {

        if (not defined &{$method}) {
            if (exists UNIT->{$method}) {
                *{$method} = sub {
                    my ($self) = @_;
                    return int(($self->[0]->epoch - $self->[1]->epoch) / UNIT->{$method});
                };
            } else {
                *{$method} = sub {
                    my ($self) = @_;
                    return $self->[0]->epoch - $self->[1]->epoch;
                };
            }
        }

        if (not defined &{$method . '_only'}) {
            *{$method . '_only'} = sub {
                my ($self) = @_;
                return $self->[0]->$method() - $self->[1]->$method;
            };
        }
    }
}

sub new {
    my ($self, $d1, $d2) = @_;
    bless [$d1, $d2], $self;
}

1; # End of Wiz::DateTime

