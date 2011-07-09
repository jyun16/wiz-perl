#!/usr/bin/perl

use lib qw(../../lib);

use Wiz::Test qw(no_plan);
use Wiz::Constant qw(:common);
use Wiz::Web::Sort;

chtestdir;

sub main {
    my $sort = new Wiz::Web::Sort;
    $sort->order(['hoge', 'fuga desc']);
    is_deeply $sort->order, ['hoge', 'fuga desc'];
    is $sort->param, 'hoge,fuga-d';
    return 0;
}

exit main;
