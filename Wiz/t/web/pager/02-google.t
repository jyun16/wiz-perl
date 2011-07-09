#!/usr/bin/perl

use lib qw(../../../lib);

use Wiz::Test qw(no_plan);
use Wiz::Constant qw(:common);
use Wiz::Web::Pager::Google;

chtestdir;

sub main {
    my $pager = new Wiz::Web::Pager::Google(
        now_page    => 1,
        total_number  => 30, 
    );

    is $pager->tag, <<'EOS';
1
&nbsp;<a href="JavaScript:jumpPage(2);">2</a>
&nbsp;<a href="JavaScript:jumpPage(3);">3</a>
&nbsp;<a href="JavaScript:jumpPage(2);">&gt;next&nbsp;</a>
EOS

    $pager->now_page(1);
    $pager->total_number(11);
    is $pager->tag, <<'EOS';
1
&nbsp;<a href="JavaScript:jumpPage(2);">2</a>
&nbsp;<a href="JavaScript:jumpPage(2);">&gt;next&nbsp;</a>
EOS

    $pager->now_page(12);
    $pager->total_number(120);
    is $pager->tag, <<'EOS';
<a href="JavaScript:jumpPage(11);">prev&nbsp;&lt;</a>
<a href="JavaScript:jumpPage(1);">1</a>
&nbsp;<a href="JavaScript:jumpPage(2);">2</a>
&nbsp;<a href="JavaScript:jumpPage(3);">3</a>
&nbsp;<a href="JavaScript:jumpPage(4);">4</a>
&nbsp;<a href="JavaScript:jumpPage(5);">5</a>
&nbsp;<a href="JavaScript:jumpPage(6);">6</a>
&nbsp;<a href="JavaScript:jumpPage(7);">7</a>
&nbsp;<a href="JavaScript:jumpPage(8);">8</a>
&nbsp;<a href="JavaScript:jumpPage(9);">9</a>
&nbsp;<a href="JavaScript:jumpPage(10);">10</a>
<a href="JavaScript:jumpPage(11);">11</a>
12
EOS

    $pager->now_page(5);
    $pager->total_number(120);
    is $pager->tag, <<'EOS';
<a href="JavaScript:jumpPage(4);">prev&nbsp;&lt;</a>
<a href="JavaScript:jumpPage(1);">1</a>
&nbsp;<a href="JavaScript:jumpPage(2);">2</a>
&nbsp;<a href="JavaScript:jumpPage(3);">3</a>
&nbsp;<a href="JavaScript:jumpPage(4);">4</a>
&nbsp;5
&nbsp;<a href="JavaScript:jumpPage(6);">6</a>
&nbsp;<a href="JavaScript:jumpPage(7);">7</a>
&nbsp;<a href="JavaScript:jumpPage(8);">8</a>
&nbsp;<a href="JavaScript:jumpPage(9);">9</a>
&nbsp;<a href="JavaScript:jumpPage(10);">10</a>
<a href="JavaScript:jumpPage(11);">11</a>
<a href="JavaScript:jumpPage(12);">12</a>
<a href="JavaScript:jumpPage(6);">&gt;next&nbsp;</a>
EOS

    $pager->now_page(9);
    $pager->total_number(100);
    is $pager->tag, <<'EOS';
<a href="JavaScript:jumpPage(8);">prev&nbsp;&lt;</a>
<a href="JavaScript:jumpPage(1);">1</a>
&nbsp;<a href="JavaScript:jumpPage(2);">2</a>
&nbsp;<a href="JavaScript:jumpPage(3);">3</a>
&nbsp;<a href="JavaScript:jumpPage(4);">4</a>
&nbsp;<a href="JavaScript:jumpPage(5);">5</a>
&nbsp;<a href="JavaScript:jumpPage(6);">6</a>
&nbsp;<a href="JavaScript:jumpPage(7);">7</a>
&nbsp;<a href="JavaScript:jumpPage(8);">8</a>
&nbsp;9
&nbsp;<a href="JavaScript:jumpPage(10);">10</a>
<a href="JavaScript:jumpPage(10);">&gt;next&nbsp;</a>
EOS

    $pager->now_page(10);
    $pager->total_number(100);
    is $pager->tag, <<'EOS';
<a href="JavaScript:jumpPage(9);">prev&nbsp;&lt;</a>
<a href="JavaScript:jumpPage(1);">1</a>
&nbsp;<a href="JavaScript:jumpPage(2);">2</a>
&nbsp;<a href="JavaScript:jumpPage(3);">3</a>
&nbsp;<a href="JavaScript:jumpPage(4);">4</a>
&nbsp;<a href="JavaScript:jumpPage(5);">5</a>
&nbsp;<a href="JavaScript:jumpPage(6);">6</a>
&nbsp;<a href="JavaScript:jumpPage(7);">7</a>
&nbsp;<a href="JavaScript:jumpPage(8);">8</a>
&nbsp;<a href="JavaScript:jumpPage(9);">9</a>
&nbsp;10
EOS

    $pager->now_page(10);
    $pager->total_number(300);
    is $pager->tag, <<'EOS';
<a href="JavaScript:jumpPage(9);">prev&nbsp;&lt;</a>
<a href="JavaScript:jumpPage(1);">1</a>
&nbsp;<a href="JavaScript:jumpPage(2);">2</a>
&nbsp;<a href="JavaScript:jumpPage(3);">3</a>
&nbsp;<a href="JavaScript:jumpPage(4);">4</a>
&nbsp;<a href="JavaScript:jumpPage(5);">5</a>
&nbsp;<a href="JavaScript:jumpPage(6);">6</a>
&nbsp;<a href="JavaScript:jumpPage(7);">7</a>
&nbsp;<a href="JavaScript:jumpPage(8);">8</a>
&nbsp;<a href="JavaScript:jumpPage(9);">9</a>
&nbsp;10
<a href="JavaScript:jumpPage(11);">11</a>
<a href="JavaScript:jumpPage(12);">12</a>
<a href="JavaScript:jumpPage(13);">13</a>
<a href="JavaScript:jumpPage(14);">14</a>
<a href="JavaScript:jumpPage(15);">15</a>
<a href="JavaScript:jumpPage(16);">16</a>
<a href="JavaScript:jumpPage(17);">17</a>
<a href="JavaScript:jumpPage(18);">18</a>
<a href="JavaScript:jumpPage(19);">19</a>
<a href="JavaScript:jumpPage(11);">&gt;next&nbsp;</a>
EOS

    $pager->now_page(11);
    $pager->total_number(300);
    is $pager->tag, <<'EOS';
<a href="JavaScript:jumpPage(10);">prev&nbsp;&lt;</a>
<a href="JavaScript:jumpPage(1);">1</a>
&nbsp;<a href="JavaScript:jumpPage(2);">2</a>
&nbsp;<a href="JavaScript:jumpPage(3);">3</a>
&nbsp;<a href="JavaScript:jumpPage(4);">4</a>
&nbsp;<a href="JavaScript:jumpPage(5);">5</a>
&nbsp;<a href="JavaScript:jumpPage(6);">6</a>
&nbsp;<a href="JavaScript:jumpPage(7);">7</a>
&nbsp;<a href="JavaScript:jumpPage(8);">8</a>
&nbsp;<a href="JavaScript:jumpPage(9);">9</a>
&nbsp;<a href="JavaScript:jumpPage(10);">10</a>
11
<a href="JavaScript:jumpPage(12);">12</a>
<a href="JavaScript:jumpPage(13);">13</a>
<a href="JavaScript:jumpPage(14);">14</a>
<a href="JavaScript:jumpPage(15);">15</a>
<a href="JavaScript:jumpPage(16);">16</a>
<a href="JavaScript:jumpPage(17);">17</a>
<a href="JavaScript:jumpPage(18);">18</a>
<a href="JavaScript:jumpPage(19);">19</a>
<a href="JavaScript:jumpPage(20);">20</a>
<a href="JavaScript:jumpPage(12);">&gt;next&nbsp;</a>
EOS
    
    $pager->now_page(12);
    $pager->total_number(300);
    is $pager->tag, <<'EOS';
<a href="JavaScript:jumpPage(11);">prev&nbsp;&lt;</a>
<a href="JavaScript:jumpPage(2);">2</a>
&nbsp;<a href="JavaScript:jumpPage(3);">3</a>
&nbsp;<a href="JavaScript:jumpPage(4);">4</a>
&nbsp;<a href="JavaScript:jumpPage(5);">5</a>
&nbsp;<a href="JavaScript:jumpPage(6);">6</a>
&nbsp;<a href="JavaScript:jumpPage(7);">7</a>
&nbsp;<a href="JavaScript:jumpPage(8);">8</a>
&nbsp;<a href="JavaScript:jumpPage(9);">9</a>
&nbsp;<a href="JavaScript:jumpPage(10);">10</a>
<a href="JavaScript:jumpPage(11);">11</a>
12
<a href="JavaScript:jumpPage(13);">13</a>
<a href="JavaScript:jumpPage(14);">14</a>
<a href="JavaScript:jumpPage(15);">15</a>
<a href="JavaScript:jumpPage(16);">16</a>
<a href="JavaScript:jumpPage(17);">17</a>
<a href="JavaScript:jumpPage(18);">18</a>
<a href="JavaScript:jumpPage(19);">19</a>
<a href="JavaScript:jumpPage(20);">20</a>
<a href="JavaScript:jumpPage(21);">21</a>
<a href="JavaScript:jumpPage(13);">&gt;next&nbsp;</a>
EOS

    return 0;
}

exit main;
