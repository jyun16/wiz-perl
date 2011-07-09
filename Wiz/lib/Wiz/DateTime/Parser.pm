package Wiz::DateTime::Parser;

use strict;
use warnings;
use base qw/Exporter/;

use Time::TAI64 ();
# use Wiz::DateTime;


our @EXPORT = qw/PARSER/;

my %month2num  = Wiz::DateTime::_MONTH2NUM();
my $stz2tz     = Wiz::DateTime::_STZ2TZ();
my $stz2offset = Wiz::DateTime::_STZ2OFFSET();

sub _dthash {
    my($name, @value) = @_;
    my %dthash;
    @dthash{@$name} = @value;

    foreach my $u (qw/year month day hour minute second microsecond nanosecond/) {
        $dthash{$u} ||= 0;
        $dthash{$u} += 0;
    }
    $dthash{year}      ||= 1970;
    $dthash{month}     ||= 1;
    $dthash{day}       ||= 1;
    $dthash{time_zone} ||= 'local';
    return \%dthash;
}


my $PARSER;

use constant PARSER => $PARSER =
    {
     GENERAL =>
     [
      sub {
          if (my @dt = $_[0] =~ qr{^(\d{4})([\/\-])(\d{1,2})\2(\d{1,2})(?:[\s-](\d{1,2})([\.:])(\d{1,2})(?:\6(\d{1,2}))?)?([+-]\d+)?$}) {
              return _dthash [qw/year month day hour minute second time_zone/] => @dt[0, 2 .. 4, 6, 7, 8];
          }
      },
      sub {
          if (my @dt = $_[0] =~ qr{^(\d{4})([\/\-\@])(\d{1,2})(?:\2(\d{1,2}))?$}) {
              return _dthash [qw/year month day/] => @dt[0, 2, 3];
          }
      },
      sub {
          if (my @dt = $_[0] =~ qr{^(\d{4})(\d{2})(\d{2})$}) {
              return _dthash [qw/year month day/] => @dt;
          }
      },
      sub {
          if (my @dt = $_[0] =~ qr{^(\d{1,2})[\:\.](\d{1,2})(?:[\:\.](\d{1,2}))?$}) {
              return _dthash [qw/hour minute second/] => @dt;
          }
      }

     ],
     W3C =>
     [
      sub {
          my ($string) = @_;
          if (my @dt = $string =~ qr{^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2})(?:\:(\d{2}))?(?:\.(\d+))?(.+)?$}) {
              $dt[7] = defined $dt[7] ? $dt[7] eq "Z"  ? '+00:00'  :
              $dt[7] =~ m|([+-]\d{2}):\d{2}|           ? $1 . '00' :
              ''                                                   :
              '';
              return _dthash [qw/year month day hour minute second microsecond time_zone/] => @dt;
          }
      },
      sub {
          if (my @dt = $_[0] =~ qr{^(\d{4})-(\d{2})-(\d{2})$}) {
              return _dthash [qw/year month day/] => @dt;
          }
      },
      sub {
          if (my @dt = $_[0] =~ qr{^(\d{4})-(\d{2})$}) {
              return _dthash [qw/year month/] => @dt;
          }
      },
     ],
     DATE =>
     [
      sub {
          my ($string) = @_;
          if (my @dt = $string =~ qr{^\w{3} (\w{3}) (\d{2}) (\d{2}):(\d{2}):(\d{2}) (\w+) (\d{4})$}) {
              $dt[0] = $month2num{lc $dt[0]};
              $dt[5] = $stz2tz->{lc $dt[5]};
              return _dthash [qw/month day hour minute second time_zone year/] => @dt;
          }
      },
     ],
     ACCESS_LOG =>
     [
      sub {
          my ($string) = @_;
          if (my @dt = $string =~ qr{^(\d{2})/(\w{3})/(\d{4}):(\d{2}):(\d{2}):(\d{2}) ([+-]\d{4})$}) {
              $dt[1] = $month2num{lc $dt[1]};
              return _dthash [qw/day month year hour minute second time_zone/] => @dt;
          }
      },
     ],
     ERROR_LOG =>
     [
      sub {
          my ($string) = @_;
          if (my @dt = $string =~ qr{^\w{3} (\w{3}) (\d{2}) (\d{2}):(\d{2}):(\d{2}) (\d{4})$}) {
              $dt[0] = $month2num{lc $dt[0]};
              return _dthash [qw/month day hour minute second year/] => @dt;
          }
      },
     ],
     APACHE_DIRINDEX =>
     [
      sub {
          if (my @dt = $_[0] =~ qr{^(\d{2})-(\w{3})-(\d{4}) (\d{2}):(\d{2}):(\d{2})$}) {
              $dt[1] = $month2num{lc $dt[1]};
              return _dthash [qw/day month year hour minute second/] => @dt;
          }
      }
     ],
     RFC822 =>
     [
      # Fri, 17-Feb-2006 11:24:41 +0900
      sub {
          my ($string) = @_;
          if (my @dt = $string =~ qr{^\w{3}, (\d{2}) (\w{3}) (\d{4}|\d{2}) (\d{2}):(\d{2}):(\d{2})\s*(\w{3}|[+-]\d{4})$}) {
                $dt[1] = $month2num{lc $dt[1]};
                if ($dt[6] =~ /^[+-]/) {
                    my $offset = $dt[6];
                    if ($dt[2] < 100) { substr($dt[2], 0, 0) = substr((localtime time + $offset)[5] + 1900, 0, 2); }
                }
                else { $dt[6] = $stz2tz->{lc $dt[6]}; }
                return _dthash [qw/day month year hour minute second time_zone/] => @dt;
          }
      },
      sub {
          my ($string) = @_;
          if (my @dt = $string =~ qr{^\w{3}, (\d{2})-(\w{3})-(\d{2,4}) (\d{2}):(\d{2}):(\d{2})\s*([+-]\d{4})$}) {
                $dt[1] = $month2num{lc $dt[1]};
                if ($dt[6] =~ /^[+-]/) {
                    my $offset = $dt[6];
                    if ($dt[2] < 100) { substr($dt[2], 0, 0) = substr((localtime time + $offset)[5] + 1900, 0, 2); }
                }
                else { $dt[6] = $stz2tz->{lc $dt[6]}; }
                return _dthash [qw/day month year hour minute second time_zone/] => @dt;
          }
      },
     ],
     RFC850 =>
     [
      # Fri, 17-Feb-2006 11:24:41 JST
      sub {
          my ($string) = @_;
          if (my @dt = $string =~ qr{^\w{3}, (\d{2})-(\w{3})-(\d{2,4}) (\d{2}):(\d{2}):(\d{2}) (\w+)$}) {
              $dt[1] = $month2num{lc $dt[1]};
              my $offset = $stz2offset->{lc $dt[6]} || 0;
              $dt[6]     = $stz2tz->{lc $dt[6]};
              if ($dt[2] < 100) {
                  substr($dt[2], 0, 0) = substr((localtime time + $offset)[5] + 1900, 0, 2);
              }
              return _dthash [qw/day month year hour minute second time_zone/] => @dt;
          }
      },
     ],
     HTTP =>
     [
      sub {
          my ($string) = @_;
          if (my @dt = $string =~ qr{^\w{3}, (\d{2}) (\w{3}) (\d{4}|\d{2}) (\d{2}):(\d{2}):(\d{2}) (\w{3})$}) {
              $dt[1] = $month2num{lc $dt[1]};
              $dt[6]     = $stz2tz->{lc $dt[6]};
              return _dthash [qw/day month year hour minute second time_zone/] => @dt;
          }
      },
     ],
     ATOM =>
     [
      sub {
          if (my @dt = $_[0] =~ qr{^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})Z$}) {
              return _dthash [qw/year month day hour minute second/] => @dt;
          }
      },
     ],
     TAI64N =>
     [
      sub {
          my ($string) = @_;
          if (my $nanoepoch = Time::TAI64::tai64nunix($string)) {
              my ($epoch, $nsec) = split /\./, $nanoepoch;
              return {epoch => $epoch, nanosecond => $nsec};
          }
      },
     ],
     MYSQL =>
     [
      sub {
          if (my @dt = $_[0] =~ qr{^(\d{4})-(\d{2})-(\d{2}) (\d{2}):(\d{2}):(\d{2})$}) {
              return _dthash [qw/year month day hour minute second/] => @dt;
          }
      }
     ],
     DB2 =>
     [
      sub {
          if (my @dt = $_[0] =~ qr{^(\d{4})-(\d{2})-(\d{2}) (\d{2}).(\d{2}).(\d{2})(?:\.(\d+))?$}) {
              return _dthash [qw/year month day hour minute second microsecond/] => @dt;
          }
      }
     ],
     TIME =>
     [
      sub {
          if (my @dt = $_[0] =~ qr{^(\d{2}):(\d{2}):(\d{2})$}) {
              return _dthash [qw/hour minute second/] => @dt;
          }
      },
     ],
     TIME_DETAIL =>
     [
      sub {
          if (my @dt = $_[0] =~ qr{^(\d{2}):(\d{2}):(\d{2})\.(\d+)$}) {
              return _dthash [qw/hour minute second microsecond/] => @dt; 
          }
      },
     ],
     TRADITIONAL =>
     [
      sub {
          if (my @dt = $_[0] =~ qr{^(\w+) +(\d{1,2}) *, *(\d+)$}) {
              $dt[0] = $month2num{lc $dt[0]};
              return _dthash [qw/month day year/] => @dt;
          }
      },
     ],
     MILITARY =>
     [
      sub {
          if (my @dt = $_[0] =~ qr{^(\d{1,2}) +(\w+) +(\d+)$}) {
              $dt[1] = $month2num{lc $dt[1]};
              return _dthash [qw/day month year/] => @dt;
          }
      },
     ],
     TWITTER =>
     [
      sub {
          my ($string) = @_;
          if (my @dt = $string =~ qr{^(\w{3}) (\w{3}) (\d{2}) (\d{2}):(\d{2}):(\d{2}) ([+-]\d{4}) (\d{4})$}) {
              $dt[1] = $month2num{lc $dt[1]};
              shift @dt;
              return _dthash [qw/month day hour minute second time_zone year/] => @dt;
          }
      },
     ],
    };

$PARSER->{ANY} = [ map @{$PARSER->{$_}}, keys %$PARSER ];


=head1 NAME

Wiz::DateTime::Parser - Parser for Wiz::DateTime

=head1 VERSION

version 1.0

=cut

our $VERSION = '1.0';

=head1 SYNOPSIS

See L<Wiz::DateTime> module.

=head1 DESCRIPTION

It is praser subroutine collection.

=head1 SUPPORTED FORMAT

=head2 GENERAL

=head2 W3C

=head2 DATE

=head2 ACCESS_LOG

=head2 ERROR_LOG

=head2 APACHE_DIRINDEX

=head2 RFC822

=head2 RFC850

=head2 TAI64N

=head2 DB2

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

1;
