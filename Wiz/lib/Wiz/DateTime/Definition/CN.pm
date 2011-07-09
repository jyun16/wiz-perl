package Wiz::DateTime::Definition::CN;

use strict;
use warnings;

use base qw/Wiz::DateTime::Definition/;
use Calendar::China ();

sub _date_definition {
    return
        {
         calendar =>
         {
          gregorian =>
          {
           month_day =>
           {
            '0101' => { name => ['元旦'  ], is_holiday => 1 },
            '0214' => { name => ['情人节'], is_holiday => 1 },
            '0308' => { name => ['妇女节'], is_holiday => 1 },
            '0312' => { name => ['植树节'], is_holiday => 1 },
            '0401' => { name => ['愚人节'], is_holiday => 1 },
            '0405' => { name => ['清明节'], is_holiday => 1 },
            '0501' => { name => ['劳动节'], is_holiday => 1 },
            '0504' => { name => ['青年节'], is_holiday => 1 },
            '0601' => { name => ['劳动节'], is_holiday => 1 },
            '0701' => { name => ['建党日'], is_holiday => 1 },
            '0801' => { name => ['建军节'], is_holiday => 1 },
            '0910' => { name => ['教师节'], is_holiday => 1 },
            '1001' => { name => ['国庆节'], is_holiday => 1 },
            '1225' => { name => ['圣诞节'], is_holiday => 1 },
           },
           weekday =>
           {
            '*-*-7'  => { name => ['星期六'  ], is_holiday => 1 },
            '*-*-6'  => { name => ['星期天'  ], is_holiday => 1 },
           }
          },
          lunar_cn =>
          {
           month_day =>
           {
            '0101' => {name => ['春节'      ], is_holiday => 1 },
            '0115' => {name => ['元宵节'    ], is_holiday => 1 },
            '0505' => {name => ['端午节'    ], is_holiday => 1 },
            '0707' => {name => ['七夕情人节'], is_holiday => 1 },
            '0815' => {name => ['中秋节'    ], is_holiday => 1 },
            '0909' => {name => ['重阳节'    ], is_holiday => 1 },
            '1208' => {name => ['腊八节'    ], is_holiday => 1 },
            '1222' => {name => ['冬至节'    ], is_holiday => 1 },
            '1230' => {name => ['除夕'      ], is_holiday => 1 },
           },
          },
         },
         substitute_holiday => '转帐假日',
        };
}

sub convert_lunar_cn {
    my ($self, $dt) = @_;
    my $d = Calendar->new_from_Gregorian($dt->month, $dt->day, $dt->year)->convert_to_China;
    $dt->set(map { $_ => $d->$_ } qw/year month day/);
    return $dt;
}

=head1 NAME

Wiz::DateTime::Definition::CN - Date definition for Chinese Calendar

=head1 VERSION

version 1.0

=cut

our $VERSION = '1.0';

=head1 SYNOPSIS

See L<Wiz::DateTime> module.

=head1 DESCRIPTION

In this definition, define Saturday, Sundary and lunar and solar holiday as holiday.

=head1 SEE ALSO

L<Wiz::DateTime>
L<Wiz::DateTime::Definition>

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
