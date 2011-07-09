package Wiz::DateTime::Util;

use strict;
use warnings;


=head1 NAME

Wiz::DateTime::Util - utilities for date and time calculation

=head1 VERSION

version 1.0

=cut

our $VERSION = '1.0';

=head1 SYNOPSIS

 use Wiz::DateTime::Util qw/sec2num/;

 print sec2hour(3600) # 1.0
 print sec2hour(5450, offunit => 0.5)  # 1.5
 print sec2hour(5450, upunit  => 0.25) # 1.75

=head1 DESCRIPTION

It is utilities for date and time calculation.
functions in this package, can be used by Wiz::DateTime package
as object method, class method or function.

=head1 FUNCTIONS

=cut

use DateTime;
use base qw(Exporter);

our @EXPORT_SUB = qw(sec2hour);
our @EXPORT_CONST = qw();
our @EXPORT_OK = (@EXPORT_SUB, @EXPORT_CONST);

our %EXPORT_TAGS = (
    'sub'       => \@EXPORT_SUB,
    'const'     => \@EXPORT_CONST,
    'all'       => \@EXPORT_OK,
);

sub _arg {
    shift;
    my $self = '';
    if (ref $_[0] eq 'Wiz::DateTime') {
        $self = shift;
    } elsif ($_[0] eq 'Wiz::DateTime') {
        $self = Wiz::DateTime->now();
    }
    return $self, @_;
}

=head2 $hour = sec2hour($second, %option)

This convert from second to hour.

 print sec2hour(3600); # 1

option can tabke offunit, upunit and arrange.

offunit is the unit to round-off given value.
upunit is the unit to round-up given value.

 print sec2hour(3600, offunit => '0.00'); # 1.00
 print sec2hour(5450, offunit => 0.5); # 1.5
 print sec2hour(5450, upunit  => 0.25); # 1.75

If you don't want to arrange returned value.

 print sec2hour(3600, offunit => 0.25, arrange => 0); # 1

Note that arrange must be used with offunit or upunit.

When you use it as object/class method and don't give $second,
$sec is automataicaly set as ($dt->epoch - $dt->clone->round('day')->epoch);

 $dt->sec2hour();
 Wiz::DateTime->sec2hour(); # it is as same as Wiz::DateTime->now->sec2hour();

=cut

sub sec2hour {
    my ($self, @args) = __PACKAGE__->_arg(@_);
    my ($sec, %option);

    if ($self and (not @args or $args[0] =~/\D/o)) {
        $sec = ($self->epoch - $self->clone->round('day')->epoch);
        %option = @args;
    } else {
        ($sec, %option) = @args;
    }

    Carp::croak "second is needed." if not $sec;

    my $h = int($sec / 3600);

    if (%option) {
        my $rest_sec = $sec % 3600;
        my $unit = $option{offunit} || $option{upunit} || 1;
        my $n    = int($rest_sec / ($unit * 3600));
        if (defined $option{upunit}) {
            $n++  if $rest_sec % ($unit * 3600);
        } elsif (defined $option{offunit}) {
            # nothing to do
        } else {
            Carp::croak "bad argument: " . join " ", keys %option;
        }
        $h += $n * $unit;
        if (not exists $option{arrange} or $option{arrange} == 1) {
            my $l = $unit =~/\.(\d+)$/ ? length($1) : 0;
            $h = sprintf "%.${l}f", $h;
        }
    }
    return $h;
}

=head1 AUTHOR

Kato Atsushi, C<< <KTAT at cpan.org> >>

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

1; # End of Wiz::DateTime::Util


