package Wiz::Web::Calendar::Basic;

use strict;
use warnings;

=head1 NAME

Wiz::Web::Pager::Basic - output simple box/vertical calendar

=head1 VERSION

version 1.0

=cut

our $VERSION = '1.0';

=head1 SYNOPSIS

 my $pager = new Wiz::Web::Calendar::Basic(
     year               => 2008,
     month              => 1,
     wday_start         => 1, # Start from Monday
     current_month_only => 0,
     dest_url           => 'http://localhost:3000/schedule/$y/$m/$d',
 );
 
 $calendar->tag;

 my $pager = new Wiz::Web::Calendar::Basic(
     range              => [2008-01, 2008-12],
     current_month_only => 0,
     dest_url           => 'http://localhost:3000/schedule/$y/$m/$d',
 );
 
 $calendar->tag;

=head2 IN TEMPLATE (ex. TT)

 <head>
 [% calendar.style %]
 </head>
 <body>
     [% calendar.tag %]
 </body>

=head1 DESCRIPTION

It is useful, if you want a simple calendar.
It provides very simple box/vertical calendar.
You can find other complecate calendar, but their usage is
as nealy same as this module.

=cut

use base qw(Wiz::Web::Calendar::Base);

=head1 CONSTRUCTOR

=head2 $cal = new(%option)

It create Wiz::Web::Calendar::Basic object.
%option is the following;

=over 4

=item * year

Year of the calendar.

=item * month

Month of the calendar.

=item * wday_start

This option is for box calendar.
If this is true, calendar is started form Monday.

=item * day

If you want 'selected' class name to add the day,
to give the day as this option.

When you use 'range' option, use 'date' instead.

=item * range

If you want multiple months calendar, use this.

=item * date

If you want 'selected' class name to add the day,
to give the day as this option.

When you use 'year' and 'month' option, use 'day' instead.

=item * lang

It is language of label, for example, year, month, Monday etc.
Currently, only 'en' is supported and 'en' is default.

=item * date_definition

It is Wiz::DateTime option.
You can use any string after 'Wiz::DateTime::Definition::'.
For example, 'JP', 'CN', 'STANDARD' etc.

'STANDARD' is default.

=item * current_month_only

=item * dest_url

This url is path for each day.
$y, $m, $d and $ymd can be used as variable.

=item * month_dest_url

This url is path for prev/this/next month.
$y, $m can be used as variable.

=item * class

  table    => 'calendar',
  prev     => 'prev',
  next     => 'next',
  holiday  => 'holiday',
  selected => 'selected',

=back

=head2 tag

Returns calendar tag.

=head2 style

Returns stylesheet tag.

=cut

my $BOX_TMPL = <<'_TMPL_';
[% month %]/[% year %]
[% IF month_dest_url %]

<a href="[% month_dest_url.pre %]">&lt;pre</a>
<a href="[% month_dest_url.this %]">this</a>
<a href="[% month_dest_url.next %]">next&gt;</a>[% END %]

<table class="[% class.table %]">
<tr>[% FOREACH wday = wday_list %]<th[% IF wday > 5 %]
 class="[% class.holiday %]"[% END %]>[% wday_label.$wday %]</th>[% END %]
</tr>
[% FOREACH date = date_list %]
[% IF ((loop.count % 7) == 1) %]<tr>[% END %]
<td[% IF date.class.size %] class="[% date.class.join(' ') %]"[% END %]
>[% IF date.dest_url %]
<a href="[% date.dest_url%]">[% END %]
[% date.day + 0 %]
[% IF date.dest_url %]</a>[% END %]
</td>[% IF ((loop.count % 7) == 0) %]</tr>
[% END%]
[% END %]</table>
_TMPL_

my $VERTICAL_TMPL = <<'_TMPL_';
[% month %]/[% year %]
[% IF month_dest_url %]

<a href="[% month_dest_url.pre %]">&lt;pre</a>
<a href="[% month_dest_url.this %]">this</a>
<a href="[% month_dest_url.next %]">next&gt;</a>[% END %]

<table class="[% class.table %]">
[% FOREACH date = date_list %]
<tr><td[% IF date.class.size %] class="[% date.class.join(' ') %]"[% END %]
>[% IF date.dest_url %]
<a href="[% date.dest_url%]">[% END %]
[% date.day + 0 %]
[% IF date.dest_url %]</a>[% END %]
</td><th[% IF date.wday > 5 %]
 class="[% class.holiday%]"[% END %]
>[% wday_num = date.wday %][% wday_label.$wday_num %]</th></tr>
[% END %]</table>
_TMPL_

sub _box_template {
    return $BOX_TMPL;
}

sub _vertical_template {
    return $VERTICAL_TMPL;
}

# ----[ private ]-----------------------------------------------------
# ----[ static ]------------------------------------------------------
# ----[ private static ]----------------------------------------------

=head1 AUTHOR

Kato Atsushi, C<< <jyun16@gmail.com> >>

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

