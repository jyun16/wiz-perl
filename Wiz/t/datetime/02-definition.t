#!/usr/bin/perl

use lib qw(../../lib ./lib ../lib ./t/datetime/lib ./datetime/lib);
use DateTime;
use Wiz::DateTime;
use Wiz::DateTime::Formatter qw/:all/;
use DateTimeTest qw/no_plan/;
use DateTime::TimeZone::Local;
use Wiz::DateTime::Unit qw/:all/;

chtestdir;

run_compare evaldt => 'output';

__END__

=== set_date_definition
--- evaldt : $d->set_date_definition('jp', 'standard');
--- output : ['jp', 'standard']

=== set_date_definition2
--- evaldt : $d->set_date_definition(['standard', 'jp']);
--- output : ['standard', 'jp']

=== set_date_definition3
--- evaldt : $d->set_date_definition(['standard', 'jp']); scalar $d->set_date_definition();
--- output : ['standard', 'jp']

=== set_date_definition4
--- evaldt : $d->set_date_definition('jp', 'standard'); scalar $d->set_date_definition();
--- output : ['jp', 'standard']

=== set_date_definition5
--- evaldt : $d->set_date_definition('jp', 'standard'); my @dd = $d->date_definition(); \@dd;
--- output : ['jp', 'standard']

=== set_date_definition5
--- evaldt : $d->set_date_definition(["jp+standard"]); my @dd = $d->clone->date_definition(); \@dd;
--- output : ['jp', 'standard']

=== set_date_definition6
--- evaldt : my $d = Wiz::DateTime->new("2008-01-01", ["jp", "standard"]);  my @dd = $d->date_definition(); \@dd;
--- output : ['jp', 'standard']

=== prior_date_definition
--- evaldt : my $d = Wiz::DateTime->new("2008-01-01", ["jp+standard"]);   $d->prior_date_definition;
--- output : ['jp', 'standard']

=== prior_date_definition
--- evaldt : my $d = Wiz::DateTime->new("2008-01-01", ["jp", "standard"]);   $d->prior_date_definition;
--- output : ['jp']

=== is_date_type 1/1
--- evaldt : my $d = Wiz::DateTime->new("2008-01-01", ["jp", "standard"]);   $d->is_date_type('holiday');
--- output : $_ = 1;

=== is_date_type 1/2
--- evaldt : my $d = Wiz::DateTime->new("2008-01-02", ["jp", "standard"]);   $d->is_date_type('holiday');
--- output : $_ =0;

=== is_date_type 1/2 no date def
--- evaldt : eval {my $d = Wiz::DateTime->new("2008-01-02"); $d2 = $d->clone;  $d->is_date_type('holiday', $d2);}; $@ ? 1 : 0;
--- output : $_ = 1;

=== is_date_type 1/1
--- evaldt : my $d = Wiz::DateTime->new("2008-01-01");   $d->is_date_type('holiday', ["jp", "standard"]);
--- output : $_ = 1;

=== is_date_type 1/2
--- evaldt : my $d = Wiz::DateTime->new("2008-01-02");   $d->is_date_type('holiday', ["jp", "standard"]);
--- output : $_ = 0;

=== is_date_type 1/2 no date def
--- evaldt : my $d = Wiz::DateTime->new("2008-01-02"); $d2 = $d->clone;  $d->is_date_type('holiday', $d2, ["jp", "standard"]);
--- output : $_ = 0;

=== is_date_type 1/1 hash definition
--- evaldt
my $d = Wiz::DateTime->new("2008-01-01");
$d->set_date_definition
    (
     {
      calendar =>
      {
       gregorian =>
       {
        month_day => {
                      '0101' => {is_holiday => 1, name => ['gantan']},
                     }
       }
      }
     } => 'hoge');
$d2 = $d->clone;
$d->is_date_type('holiday',$d2);
--- output : $_ = 1

=== is_date_type 1/2 hash definition
--- evaldt
my $d = Wiz::DateTime->new("2008-01-02");
$d->set_date_definition
    (
     {
      calendar =>
      {
       gregorian =>
       {
        month_day => {
                      '0101' => {is_holiday => 1, name => ['gantan']},
                     }
       }
      }
     } => 'hoge');
$d2 = $d->clone;
$d->is_date_type('holiday',$d2);
--- output : $_ = 0

