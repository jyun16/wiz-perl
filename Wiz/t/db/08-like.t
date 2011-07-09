#!/usr/bin/perl

use strict;
use warnings;

no warnings 'prototype';

use lib qw(../../lib);

use Wiz::Test qw(no_plan);
use Wiz::Constant qw(:common);
use Wiz::ReturnCode qw(:all);
use Wiz::DB::Constant qw(:all);
use Wiz::DB::Connection;
use Wiz::Log qw(:all);

use Wiz::DB qw(like_sub prelike);
use Wiz::DB::SQL::Constant qw(:like);
use Wiz::DB::SQL::Where::MySQL;

use Data::Dumper;

chtestdir;

$| = 1;

my %conf = (
    table   => 'wiz_db_test_table',
);

my %mysql_param = (
    type    => DB_TYPE_MYSQL,
    db      => 'test',
    user    => 'root',
    log     => {
        stderr          => TRUE,
        stack_dump      => TRUE,
    },
);

sub main {
    my $conn = new Wiz::DB::Connection(%mysql_param);
    create_table($conn);
    search($conn);
    return 0;
}

sub search {
    my $conn = shift;

    my $w = new Wiz::DB::SQL::Where::MySQL;
    $w->set(-and => [
        [ 'like', 'name', prelike(q|hoge%|) ]
    ]);
    my $rs = $conn->execute(qq|select * from $conf{table} | . $w->to_exstring);
    $rs->next;
    is $rs->get('name'), q|hoge%fuga|;
    $rs->next;
    is $rs->get('name'), q|hoge%'fuga|;
    is $rs->next, 0;

    $w->clear;
    $w->set(-and => [
        [ 'like', 'name', prelike(q|hoge%'|) ]
    ]);
    $rs = $conn->execute(qq|select * from $conf{table} | . $w->to_exstring);
    $rs->next;
    is $rs->get('name'), q|hoge%'fuga|;
    is $rs->next, 0;

    $w->clear;
    $w->set({
        name => [ 'like', prelike(q|hoge%'|) ]
    });
    $rs = $conn->execute(qq|select * from $conf{table} | . $w->to_exstring);
    $rs->next;
    is $rs->get('name'), q|hoge%'fuga|;
    is $rs->next, 0;

    $w->clear;
    $w->set({
        name => [ 'like', like_sub(PRE_LIKE)->(q|hoge%'|) ]
    });
    is $w->to_exstring, q|WHERE name like 'hoge\\\\%\'%'|;
}

sub create_table {
    my $conn = shift;

    if ($conn->table_exists($conf{table})) {
        is($conn->execute_only("DROP TABLE $conf{table}"), 0, q|drop table|);
    }

    is_defined($conn->execute_only(<<"EOS"), q|create table|);
CREATE TABLE $conf{table} (id INT AUTO_INCREMENT PRIMARY KEY, name VARCHAR(32), data TEXT, timestamp TIMESTAMP) TYPE=InnoDB
EOS

    $conn->execute_only(qq|INSERT INTO $conf{table} (name) VALUES ('| . q|hogefuga| . q|')|);
    $conn->execute_only(qq|INSERT INTO $conf{table} (name) VALUES ('| . q|hoge\'fuga| . q|')|);
    $conn->execute_only(qq|INSERT INTO $conf{table} (name) VALUES ('| . q|hoge%fuga| . q|')|);
    $conn->execute_only(qq|INSERT INTO $conf{table} (name) VALUES ('| . q|hoge%\'fuga| . q|')|);
}

#skip_confirm(2) and exit main;

exit main;
