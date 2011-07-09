#!/usr/bin/perl

use strict;
use warnings;

use lib qw(../../lib);

use Wiz::Test qw(no_plan);
use Wiz::Constant qw(:common);
use Wiz::ReturnCode qw(:all);
use Wiz::DB::Constant qw(:all);
use Wiz::DB::Connection;
use Wiz::Log qw(:all);

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
        path            => 'logs/db.log',
        level           => 'warn',
    },
    cache   => {
        type    => 'Memcached::Fast',
        conf    => {
            servers => [qw(127.0.0.1:11211)],
        },
    },
);

my %pg_param = (
    type    => DB_TYPE_POSTGRESQL,
    db      => 'test',
    user    => 'test',
    passwd  => 'hoge',
    log     => {
        stderr          => TRUE,
        stack_dump      => TRUE,
        path            => 'logs/db.log',
        level           => 'warn',
    },
);

sub main {
    mysql_test(new Wiz::DB::Connection(%mysql_param));
#    pg_test(new Wiz::DB::Connection(%pg_param));
    return 0;
}

sub pg_test {
    my ($conn) = shift;
    return_code_is($conn, undef) and die $conn->message;
#    $conn->execute_only("DROP TABLE $conf{table}");
#    $conn->execute_only(<<"EOS");
#CREATE FUNCTION func_update_last_modified() RETURNS OPAQUE AS '
#BEGIn
#    NEW.last_modified := ''now'';
#    return NEW;
#ENd;
#' LANGUAGE 'plpgsql' VOLATILE;
#EOS

    is_defined($conn->execute_only(<<"EOS"), q|create table|);
CREATE TABLE $conf{table} (
    id SERIAL PRIMARY KEY,
    name VARCHAR(32),
    data TEXT,
    created_time TIMESTAMP DEFAULT 'now',
    last_modified TIMESTAMP DEFAULT 'now'
)
EOS

    is_defined($conn->execute_only(<<"EOS"), q|create table|);
CREATE TRIGGER trg_update_last_modifled_$conf{table}
BEFORE UPDATE ON $conf{table}
FOR EACH ROW EXECUTE PROCEDURE func_update_last_modified()
EOS

    is($conn->execute_only(qq|INSERT INTO $conf{table} (name) VALUES ('x')|), 1, q|insert|);
    my $rs = $conn->execute(qq|SELECT * FROM $conf{table}|);
    ok($rs->next, q|$rs->next|);
    is($rs->get('name'), 'x', q|$rs->get('name')|);
    $conn->commit;
}

sub mysql_test {
    my ($conn) = shift;
    return_code_is($conn, undef) and die $conn->message;
    if ($conn->table_exists($conf{table})) {
        is($conn->execute_only("DROP TABLE $conf{table} IF EXISTS $conf{table}"), 0, q|drop table|);
    }
    is_defined($conn->execute_only(<<"EOS"), q|create table|);
CREATE TABLE $conf{table} (id INT AUTO_INCREMENT PRIMARY KEY, name VARCHAR(32), data TEXT, timestamp TIMESTAMP) TYPE=InnoDB
EOS
    is($conn->execute_only(qq|INSERT INTO $conf{table} (name) VALUES ('x')|), 1, q|insert|);
    my $rs = $conn->execute(qq|SELECT * FROM $conf{table}|);
    ok($rs->next, q|$rs->next|);
    is($rs->get('name'), 'x', q|$rs->get('name')|);
}

skip_confirm(2) and exit main;
