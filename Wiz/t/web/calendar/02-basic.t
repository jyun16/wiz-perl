#!/usr/bin/perl

use lib qw(../../lib ./lib ../lib ./t/datetime/lib ./datetime/lib);
use Wiz::Test qw/no_plan/;
use Wiz::Web::Calendar::Basic;

chtestdir;

sub cal {
    my $arg  = shift || {};
    my $arg2 = shift || {};
    my $def = {  year  => 2008,
                 month => 1,
                 date_definition => 'STANDARD',
                 wday_start => 1,
              };
    $arg->{$_} ||= $def->{$_} foreach keys %$def;

    my $code = shift;
    my $c    = Wiz::Web::Calendar::Basic->new($arg);
    return $c->tag($arg2);
}

sub remove_white_space {
    my $var = shift;
    $var =~ s/\n\n*$//sg;
    chomp $var;
    return $var;
}

filters {
    tag    => [qw/eval cal remove_white_space/],
    output => [qw/chomp remove_white_space/],
};

run_compare tag => 'output';

__END__
=== tag
--- tag
--- output
01/2008
<table class="calendar">
<tr><th>Mon</th><th>Tue</th><th>Wed</th><th>Thu</th><th>Fri</th><th class="holiday">Sat</th><th class="holiday">Sun</th></tr>
<tr><td class="prev">31</td><td>1</td><td>2</td><td>3</td><td>4</td><td class="holiday">5</td><td class="holiday">6</td></tr>
<tr><td>7</td><td>8</td><td>9</td><td>10</td><td>11</td><td class="holiday">12</td><td class="holiday">13</td></tr>
<tr><td>14</td><td>15</td><td>16</td><td>17</td><td>18</td><td class="holiday">19</td><td class="holiday">20</td></tr>
<tr><td>21</td><td>22</td><td>23</td><td>24</td><td>25</td><td class="holiday">26</td><td class="holiday">27</td></tr>
<tr><td>28</td><td>29</td><td>30</td><td>31</td><td class="next">1</td><td class="holiday next">2</td><td class="holiday next">3</td></tr>
</table>

=== tag(dest - $ymd)
--- tag
{dest_url => '/$ymd'}
--- output
01/2008
<table class="calendar">
<tr><th>Mon</th><th>Tue</th><th>Wed</th><th>Thu</th><th>Fri</th><th class="holiday">Sat</th><th class="holiday">Sun</th></tr>
<tr><td class="prev"><a href="/2007-12-31">31</a></td><td><a href="/2008-01-01">1</a></td><td><a href="/2008-01-02">2</a></td><td><a href="/2008-01-03">3</a></td><td><a href="/2008-01-04">4</a></td><td class="holiday"><a href="/2008-01-05">5</a></td><td class="holiday"><a href="/2008-01-06">6</a></td></tr>
<tr><td><a href="/2008-01-07">7</a></td><td><a href="/2008-01-08">8</a></td><td><a href="/2008-01-09">9</a></td><td><a href="/2008-01-10">10</a></td><td><a href="/2008-01-11">11</a></td><td class="holiday"><a href="/2008-01-12">12</a></td><td class="holiday"><a href="/2008-01-13">13</a></td></tr>
<tr><td><a href="/2008-01-14">14</a></td><td><a href="/2008-01-15">15</a></td><td><a href="/2008-01-16">16</a></td><td><a href="/2008-01-17">17</a></td><td><a href="/2008-01-18">18</a></td><td class="holiday"><a href="/2008-01-19">19</a></td><td class="holiday"><a href="/2008-01-20">20</a></td></tr>
<tr><td><a href="/2008-01-21">21</a></td><td><a href="/2008-01-22">22</a></td><td><a href="/2008-01-23">23</a></td><td><a href="/2008-01-24">24</a></td><td><a href="/2008-01-25">25</a></td><td class="holiday"><a href="/2008-01-26">26</a></td><td class="holiday"><a href="/2008-01-27">27</a></td></tr>
<tr><td><a href="/2008-01-28">28</a></td><td><a href="/2008-01-29">29</a></td><td><a href="/2008-01-30">30</a></td><td><a href="/2008-01-31">31</a></td><td class="next"><a href="/2008-02-01">1</a></td><td class="holiday next"><a href="/2008-02-02">2</a></td><td class="holiday next"><a href="/2008-02-03">3</a></td></tr>
</table>

=== tag(dest - $y-$m-$d)
--- tag
{dest_url => '/$y-$m-$d'}
--- output
01/2008
<table class="calendar">
<tr><th>Mon</th><th>Tue</th><th>Wed</th><th>Thu</th><th>Fri</th><th class="holiday">Sat</th><th class="holiday">Sun</th></tr>
<tr><td class="prev"><a href="/2007-12-31">31</a></td><td><a href="/2008-01-01">1</a></td><td><a href="/2008-01-02">2</a></td><td><a href="/2008-01-03">3</a></td><td><a href="/2008-01-04">4</a></td><td class="holiday"><a href="/2008-01-05">5</a></td><td class="holiday"><a href="/2008-01-06">6</a></td></tr>
<tr><td><a href="/2008-01-07">7</a></td><td><a href="/2008-01-08">8</a></td><td><a href="/2008-01-09">9</a></td><td><a href="/2008-01-10">10</a></td><td><a href="/2008-01-11">11</a></td><td class="holiday"><a href="/2008-01-12">12</a></td><td class="holiday"><a href="/2008-01-13">13</a></td></tr>
<tr><td><a href="/2008-01-14">14</a></td><td><a href="/2008-01-15">15</a></td><td><a href="/2008-01-16">16</a></td><td><a href="/2008-01-17">17</a></td><td><a href="/2008-01-18">18</a></td><td class="holiday"><a href="/2008-01-19">19</a></td><td class="holiday"><a href="/2008-01-20">20</a></td></tr>
<tr><td><a href="/2008-01-21">21</a></td><td><a href="/2008-01-22">22</a></td><td><a href="/2008-01-23">23</a></td><td><a href="/2008-01-24">24</a></td><td><a href="/2008-01-25">25</a></td><td class="holiday"><a href="/2008-01-26">26</a></td><td class="holiday"><a href="/2008-01-27">27</a></td></tr>
<tr><td><a href="/2008-01-28">28</a></td><td><a href="/2008-01-29">29</a></td><td><a href="/2008-01-30">30</a></td><td><a href="/2008-01-31">31</a></td><td class="next"><a href="/2008-02-01">1</a></td><td class="holiday next"><a href="/2008-02-02">2</a></td><td class="holiday next"><a href="/2008-02-03">3</a></td></tr>
</table>

=== tag(dest_url)
--- tag
{month_dest_url => '/hoge/$y-$m'}
--- output
01/2008
<a href="/hoge/2007-12">&lt;pre</a>
<a href="/hoge/2008-01">this</a>
<a href="/hoge/2008-02">next&gt;</a>
<table class="calendar">
<tr><th>Mon</th><th>Tue</th><th>Wed</th><th>Thu</th><th>Fri</th><th class="holiday">Sat</th><th class="holiday">Sun</th></tr>
<tr><td class="prev">31</td><td>1</td><td>2</td><td>3</td><td>4</td><td class="holiday">5</td><td class="holiday">6</td></tr>
<tr><td>7</td><td>8</td><td>9</td><td>10</td><td>11</td><td class="holiday">12</td><td class="holiday">13</td></tr>
<tr><td>14</td><td>15</td><td>16</td><td>17</td><td>18</td><td class="holiday">19</td><td class="holiday">20</td></tr>
<tr><td>21</td><td>22</td><td>23</td><td>24</td><td>25</td><td class="holiday">26</td><td class="holiday">27</td></tr>
<tr><td>28</td><td>29</td><td>30</td><td>31</td><td class="next">1</td><td class="holiday next">2</td><td class="holiday next">3</td></tr>
</table>

=== tag(vertical - current month_dest)
--- tag
{month_dest_url => '/hoge/$y-$m', current_month_only => 1}, {vertical => 1}
--- output
01/2008
<a href="/hoge/2007-12">&lt;pre</a>
<a href="/hoge/2008-01">this</a>
<a href="/hoge/2008-02">next&gt;</a>
<table class="calendar">
<tr><td>1</td><th>Tue</th></tr>
<tr><td>2</td><th>Wed</th></tr>
<tr><td>3</td><th>Thu</th></tr>
<tr><td>4</td><th>Fri</th></tr>
<tr><td class="holiday">5</td><th class="holiday">Sat</th></tr>
<tr><td class="holiday">6</td><th class="holiday">Sun</th></tr>
<tr><td>7</td><th>Mon</th></tr>
<tr><td>8</td><th>Tue</th></tr>
<tr><td>9</td><th>Wed</th></tr>
<tr><td>10</td><th>Thu</th></tr>
<tr><td>11</td><th>Fri</th></tr>
<tr><td class="holiday">12</td><th class="holiday">Sat</th></tr>
<tr><td class="holiday">13</td><th class="holiday">Sun</th></tr>
<tr><td>14</td><th>Mon</th></tr>
<tr><td>15</td><th>Tue</th></tr>
<tr><td>16</td><th>Wed</th></tr>
<tr><td>17</td><th>Thu</th></tr>
<tr><td>18</td><th>Fri</th></tr>
<tr><td class="holiday">19</td><th class="holiday">Sat</th></tr>
<tr><td class="holiday">20</td><th class="holiday">Sun</th></tr>
<tr><td>21</td><th>Mon</th></tr>
<tr><td>22</td><th>Tue</th></tr>
<tr><td>23</td><th>Wed</th></tr>
<tr><td>24</td><th>Thu</th></tr>
<tr><td>25</td><th>Fri</th></tr>
<tr><td class="holiday">26</td><th class="holiday">Sat</th></tr>
<tr><td class="holiday">27</td><th class="holiday">Sun</th></tr>
<tr><td>28</td><th>Mon</th></tr>
<tr><td>29</td><th>Tue</th></tr>
<tr><td>30</td><th>Wed</th></tr>
<tr><td>31</td><th>Thu</th></tr>
</table>
