#!/usr/bin/perl

use strict;
use warnings;

use lib qw(../../lib);

use Wiz::Test qw(no_plan);
use Wiz::Constant qw(:common);
use Wiz::DB::Constant qw(:all);
use Wiz::DB::Cluster;

$| = 1;

chtestdir;

my $cache_test = TRUE;

my %mysql_param = (
    type                => DB_TYPE_MYSQL,
    db                  => 'test',
    user                => 'root',
    pooling             => TRUE,
    log => {
        stderr => 1,
    },
    master  => [
        {
            host            => '127.0.0.1',
            min_idle        => 4,
        },
    ],
    slave   => [
        {
            host            => '127.0.0.1',
            min_idle        => 2,
        },
        {
            host            => '127.0.0.1',
            min_idle        => 2,
        },
    ],
    cache   => {
        type    => 'Memcached::Fast',
        conf    => {
            servers => [qw(
                127.0.0.1:11211
            )],
        },
    },
);

sub main {
    my $cluster = new Wiz::DB::Cluster(%mysql_param);

    is_defined $cluster->get_slave;
    is_defined $cluster->get_slave;
    is_defined $cluster->get_slave;

    if ($cache_test) {
        is_defined $cluster->cache;
        my $c = $cluster->cache;
        $c->set(hoge => 'HOGE');
        is $c->get('hoge'), 'HOGE';
    }

    return 0;
};

skip_confirm(2) and exit main;
