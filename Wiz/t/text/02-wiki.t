#!/usr/bin/perl

use lib qw(../lib);

use Data::Dumper;
use Wiz::Test qw(no_plan);
use Wiz::Text::Wiki;

sub main {
    my $wiki = new Wiz::Text::Wiki(data => get_data());
    warn $wiki->html;
    return 0;
}

sub get_data {
    my $ret;
    while (<DATA>) {
        $ret .= $_;
    }
    return $ret;
}

exit main;

__DATA__

*title1
**title2
***title3
****title4
*****title5

----

[[http://www.google.com|Google|_blank]]

http://www.google.com

'bold\' - \'string\'s'

<b><size 10><color red>red</color></size></b>

>>>
PRE1
	PRE1-1
PRE2
PRE3
<<<

}}}
BLOCK1
	BLOCK1-1
BLOCK2
BLOCK3
{{{

. UL1
.. UL1-1
. UL2
. UL3

,OL1
,,OL1-1
,OL2
,OL3

DL>>>
ITEM1
	EXPLAIN1-1
	EXPLAIN1-2
	EXPLAIN1-3
ITEM2
	EXPLAIN2-1
	EXPLAIN2-2
	EXPLAIN2-3
<<<

CODE-PERL>>>
use strict;

use Any::Moose;
use File::BOM qw(open_bom);
use Data::Dumper;

use Wiz::Web::Util::AutoLink qw(auto_link);

has 'data' => (is => 'rw');
has 'mode' => (is => 'rw');
has 'nest_mode' => (is => 'rw');

no warnings 'uninitialized';

sub BUILD {
    my $self = shift;
    my ($args) = @_;
    $args->{file} and $self->file($args->{file});
    return $self;
}
<<<

