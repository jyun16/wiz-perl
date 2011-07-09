#!/usr/bin/perl

use strict;
use warnings;

use lib qw(../../lib);

use Wiz::Test qw(no_plan);
use Wiz::Constant qw(:common);
use Wiz::DB::Constant qw(:all);
use Wiz::DB::Connection;
use Wiz::DB::Cluster::Controller;

$| = 1;

chtestdir;

use Data::Dumper;

my $cache_test = TRUE;

my %mysql_param01 = (
    db                  => 'test',
    user                => 'root',
    type                => DB_TYPE_MYSQL,
    priority_flag       => ENABLE,
    read_priority_flag  => ENABLE,
    pooling             => TRUE,
    log => {
        stderr  => 1,
        path    => 'logs/cluster01.log',
    },
    master  => [
        {
            min_idle        => 4,
            priority        => 10,
            read_priority   => 10,
        },
    ],
    slave   => [
        {
            min_idle        => 2,
            priority        => 10,
            log => {
                stderr  => 1,
                path    => 'logs/cluster01-slave.log',
            },
        },
        {
            user            => 'root',
            min_idle        => 2,
            priority        => 1,
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

my %mysql_param02 = (
    db                  => 'test',
    user                => 'root',
    type                => DB_TYPE_MYSQL,
    priority_flag       => ENABLE,
    read_priority_flag  => ENABLE,
    pooling             => FALSE,
    log => {
        stderr  => 1,
        path    => 'logs/cluster02.log',
    },
    master  => 
        {
            min_idle        => 4,
        },
    slave   => [
        {
            min_idle        => 2,
        },
        {
            min_idle        => 2,
        },
    ],
    cache   => {
        type    => 'Memcached::Fast',
        conf    => {
            servers => [qw(
                127.0.0.1:12345
            )],
        },
    },
);

my %mysql_param = (
    db          => 'test',
    user        => 'HOGEHOGE',
    stack_dump  => TRUE,
    clusters    => {
        cluster01   => \%mysql_param01,
        cluster02   => \%mysql_param02,
    },
);

my %mysql_param_by_file = (
    type        => DB_TYPE_MYSQL,
    db          => 'test',
    user        => 'root',
    log => {
        stderr  => 1,
        path    => 'logs/cluster_controller.log',
    },
    clusters    => {
        cluster01   => 'conf/cluster01.pdat',
        cluster02   => 'conf/cluster02.pdat',
    },
);

my %mysql_param_simple = (
    type    => 'mysql',
    db      => 'test',
    user    => 'root',
    log     => {
        stack_dump  => 1,
        stderr  => 1,
        path    => 'logs/db.log',
        level   => 'warn',
    },
);

my %mysql_param_with_group = (
    type            => DB_TYPE_MYSQL,
    db              => 'test',
    user            => 'root',
    priority_flag   => ENABLE,
    log => {
        stderr  => 1,
        path    => 'logs/cluster_controller.log',
    },
    clusters    => {
        footstamp01    => {
            priority    => 10,
            _conf       => 'conf/footstamp01.pdat',
        },
        footstamp02    => {
            priority    => 5,
            _conf       => 'conf/footstamp02.pdat',
        },
        article01      => 'conf/article01.pdat',
        article02      => 'conf/article02.pdat',
    },
    group      => {
       footstamp  => [qw(footstamp01 footstamp02)],
       article => [qw(article01 article02)],
    },
);

my %mysql_param_with_group2 = (
    type            => DB_TYPE_MYSQL,
    db              => 'test',
    user            => 'root',
    priority_flag   => ENABLE,
    log => {
        stderr  => 1,
        path    => 'logs/cluster_controller.log',
    },
    clusters    => [qw(
        conf/footstamp.pdat
    )],
    group      => {
       footstamp  => [qw(footstamp01 footstamp02)],
       article => [qw(article01 article02)],
    },
);

sub main {
    my $cc = new Wiz::DB::Cluster::Controller(%mysql_param);
    get_master_test($cc);
    get_slave_test($cc);

    if ($cache_test) {
        is_defined $cc->cache('cluster01'), q|cache('cluster01')|;
        is_defined $cc->cache('cluster02'), q|cache('cluster02')|;
    }

    $cc = new Wiz::DB::Cluster::Controller(%mysql_param_by_file);
    get_master_test($cc);
    get_slave_test($cc);

    $cc = new Wiz::DB::Cluster::Controller(_conf => 'conf/cluster.pdat');
    get_master_test($cc);
    get_slave_test($cc);

    $cc = new Wiz::DB::Cluster::Controller(%mysql_param_simple);
    $cc->get_master;
    $cc->get_slave;

    cluster_group_test();

    return 0;
};

sub get_master_test {
    my $cc = shift;

    is_defined $cc->get_master('cluster01'), q|get_master('cluster01')|;
    is_defined $cc->get_master('cluster02'), q|get_master('cluster02')|;
    $cc->get_master('cluster01')->execute("select * from hoge");
}

sub get_slave_test {
    my $cc = shift;

    is_defined $cc->get_slave('cluster01'), q|get_slave('cluster01')|;
    is_defined $cc->get_slave('cluster02'), q|get_slave('cluster02')|;
}

sub cluster_group_test {
    my $cc = new Wiz::DB::Cluster::Controller(%mysql_param_with_group);
    my $m_footstamp = $cc->get_master_in_group('footstamp');
    is_defined $m_footstamp, q|$cc->get_master_in_group('footstamp')|;
    my $s_footstamp = $cc->get_master_in_group('footstamp');
    is_defined $s_footstamp, q|$cc->get_slave_in_group('article')|;

    $cc = new Wiz::DB::Cluster::Controller(%mysql_param_with_group2);
    $m_footstamp = $cc->get_master_in_group('footstamp');
    is_defined $m_footstamp, q|$cc->get_master_in_group('footstamp') pattern 2|;
    $s_footstamp = $cc->get_master_in_group('footstamp');
    is_defined $s_footstamp, q|$cc->get_slave_in_group('article') pattern 2|;
}

skip_confirm(2) and exit main;

#exit main;

__END__

CREATE TABLE hoge (id int primary key auto_increment);
