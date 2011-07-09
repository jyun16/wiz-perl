package Wiz::DateTime::Formatter;

=head1 NAME

Wiz::DateTime::Formatter - Formatter for calcuration of Wiz::DateTime::Formatter

=head1 VERSION

version 1.0

=cut

our $VERSION = '1.0';

=head1 SYNOPSIS

see L<Wiz::DateTime>.

=head1 DESCRIPTION

If you use this module, the following constants are automatically exported.

You can use the following formats for the argument of C<Wiz::DateTime::to_string> method.
They returns strftime format string or subroutine which returns formatted datetime string.

=head2  GENERAL

=head2  GENERAL_DETAIL

=head2  ERROR_LOG

=head2  APACHE_DIRINDEX

=head2  MYSQL

=head2  DB2

=head2  RFC822

=head2  DATE

=head2  ACCESS_LOG

=head2  RFC850

=head2  W3C

=head2  TAI64N

=head2  TIME

=head2  TIME_DETAIL

=head1 SEE ALSO

L<Wiz::DateTime>

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

use strict;
use warnings;
use base qw/Exporter/;

use Time::TAI64 ();
# use Wiz::DateTime;

our @EXPORT_OK = qw/GENERAL ERROR_LOG APACHE_DIRINDEX MYSQL DB2 RFC850 RFC822 DATE ACCESS_LOG HTTP RSS ATOM W3C TAI64N TIME TIME_DETAIL/;

our %EXPORT_TAGS = (
    'all'       => \@EXPORT_OK,
);


my $tz2stz = Wiz::DateTime::_TZ2STZ;

sub GENERAL {
    '%Y-%m-%d %T';
}

sub GENERAL_DETAIL {
    return sub {
        my ($dt) = @_;
        my $tz   = $dt->time_zone;
        my $msec = $dt->microsecond;
        return $dt->to_string("%Y-%m-%d %T.$msec $tz");
    }
}

sub ERROR_LOG {
    '%a %b %d %T %Y';
}

sub APACHE_DIRINDEX {
    '%d-%b-%Y %T';
}

sub MYSQL {
    '%Y-%m-%d %T';
}

sub DB2 {
    '%Y-%m-%d %H.%M.%S';
}

sub RFC822 {
    '%a, %d-%b-%Y %H:%M:%S %z';
}

sub DATE {
    return sub {
        my ($dt) = @_;
        my $stz = uc $tz2stz->{$dt->time_zone};
        return $dt->to_string('%a %b %d %T ' . $stz . ' %Y');
    }
}

sub ACCESS_LOG {
    return sub {
        my ($dt) = @_;
        return $dt->to_string('%d/%b/%Y:%T ' . $dt->offset_string());
    }
}

sub RFC850 {
    return sub {
        my($dt) = @_;
        return $dt->to_string('%a, %d-%b-%Y %T ' . uc $tz2stz->{$dt->time_zone});
    }
}

sub HTTP {
    return sub {
        my($dt) = @_;
        my $gmt = $dt->clone;
        $gmt->add(second => -1 * $dt->offset);
        return $gmt->to_string('%a, %d %b %Y %T GMT');
    }
}

sub RSS {
    return sub {
        my($dt) = @_;
        return $dt->to_string('%a, %d %b %Y %T ' . $dt->offset_string());
    }
}

sub ATOM {
    return sub {
        my($dt) = @_;
        return $dt->to_string('%Y-%m-%d%TZ');
    }
}

sub W3C {
    return sub {
        my ($dt) = @_;
        return $dt->to_string('%Y-%m-%dT%T' . $dt->offset_string('%s%02d:%02d'));
    };
}

sub TAI64N {
    return sub {
        my ($dt) = @_;
        return Time::TAI64::unixtai64n($dt->epoch, $dt->nanosecond);
    };
}

sub TIME {
    '%T';
}

sub TIME_DETAIL {
    return sub {
        my ($dt) = @_;
        my $msec = $dt->microsecond;
        return $dt->to_string("%T.$msec");
    }
}

1;
