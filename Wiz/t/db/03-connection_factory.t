#!/usr/bin/perl

use strict;
use warnings;

use lib qw(../../lib);

use Wiz::Test qw(no_plan);
use Wiz::Constant qw(:common);
use Wiz::DB::Constant qw(:all);
use Wiz::DB::ConnectionFactory;

chtestdir;

my %mysql_param = (
    type        => DB_TYPE_MYSQL,
    db          => 'test',
    user        => 'root',
    auto_commit => TRUE,
    log     => {
        stderr  => TRUE,
    },
    pooling     => 1,
    min_idle    => 2,
    max_idle    => 4,
);

sub main {
    my $cf = new Wiz::DB::ConnectionFactory(%mysql_param);

    is(ref $cf->create, 'Wiz::DB::ConnectionPoolObject', q|$cf->create with pooling|); 
    is(ref $cf->create_connection, 'Wiz::DB::Connection', q|$cf->create_connection|);
    is(ref $cf->create_connection_from_pool, 'Wiz::DB::ConnectionPoolObject',
        q|$cf->create_connection_from_pool|);

    $cf->pooling(FALSE);
    is(ref $cf->create, 'Wiz::DB::Connection', q|$cf->create pooling off|); 

    return 0;
}

skip_confirm(2) and exit main;
