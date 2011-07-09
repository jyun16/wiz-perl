#!/usr/bin/perl

use strict;
use warnings;

use lib qw(../../lib);

use Wiz::Test qw(no_plan);

use Wiz::Constant qw(:all);
use Wiz::DB::Constant qw(:all);
use Wiz::DB::Connection;
use Wiz::DB::DataIO;
use Wiz::DB::PreparedStatement;
use Wiz::DB::ResultSet;

use Data::Dumper;

chtestdir;

my %conf = (
    table   => 'wiz_db_test_table',
);

my %mysql_param = (
    type    => DB_TYPE_POSTGRESQL,
    db      => 'test',
    user    => 'test',
    passwd  => 'hoge',
    log     => {
        stderr          => TRUE,
        stack_dump      => TRUE,
        level           => 'warn',
    },
);

sub main {
    my $conn = create_connection();
    create_table($conn);
    my $data = new Wiz::DB::DataIO($conn, $conf{table});
    insert_test($data);
    count_test($data);
    select_test($data);
    update_test($data);
    delete_test($data);
    $conn->commit;
    return 0;
}

sub insert_test {
    my $data = shift;

    for (0..2) {
        $data->set(name => "hoge $_");
        $data->set(data => "hoge data $_");
        is($data->insert, 1, qq|\$data->insert $_|);
        is($data->insert_dump,
            qq|INSERT INTO $conf{table} (name,data) VALUES ('hoge $_','hoge data $_')|,
            qq|\$data->insert_dump $_|);
    }

    is($data->get_insert_id, 3, q|$data->get_insert_id|);

    my $pstmt = $data->prepared_insert(data => [qw(name data)]);
    is($pstmt->execute_only('fuga', 'FUGA'), 1, q|$pstmt->execute_only("fuga", 'FUGA')|);

    is($data->get_insert_id, 4, q|$data->get_insert_id|);

    $pstmt = $data->prepared_insert(data => [qw(name data)]);
    is($pstmt->execute_only('foo', 'FOO'), 1, q|$pstmt->execute_only("foo", 'FOO')|);

    is($data->get_insert_id, 5, q|$data->get_insert_id|);

    $pstmt = $data->prepared_insert(qw(name data));
    is($pstmt->execute_only('bar', 'BAR'), 1, q|$pstmt->execute_only("bar", 'BAR')|);

    is($data->get_insert_id, 6, q|$data->get_insert_id|);

    has_hash($data->get_insert_data,
        { id => 6, name => 'bar', data => 'BAR'},
        q|$data->get_insert_data|);
}

sub count_test {
    my $data = shift;

    is($data->count, 6, q|\$data->count|);
    is($data->count({ name => 'hoge 0' }), 1, q|$data->count({ name => 'hoge 0' })|);
    is($data->count([ -and => [[qw(like name hoge%)]]]), 3,
        q|$data->count({ name => 'hoge 0' })|);
    is($data->count([ -and => [['not like', 'name', '%2']]]), 5,
        q|$data->count([ -and => [['not like', 'name', '%2']]])|);
}

sub select_test {
    my $data = shift;

    has_hash($data->retrieve(id => 1),
        { id => 1, name => 'hoge 0', data => 'hoge data 0' },
        q|$data->retrieve(id => 1)|);

    my $rs = $data->select(id => 2);
    $rs->next;
    is($rs->get('name'), 'hoge 1', q|$data->select(id => 2)|);

    $rs = $data->select([ -and => [[qw(like name hoge%)]]]);
    $rs->next;
    has_hash($rs->data,
        { id => 1, name => 'hoge 0', data => 'hoge data 0' },
        q|$data->select([ -and => [[qw(like name hoge%)]]]) 1|);
    $rs->next;
    has_hash($rs->data,
        { id => 2, name => 'hoge 1', data => 'hoge data 1' },
        q|$data->select([ -and => [[qw(like name hoge%)]]]) 2|);
    $rs->next;
    has_hash($rs->data,
        { id => 3, name => 'hoge 2', data => 'hoge data 2' },
        q|$data->select([ -and => [[qw(like name hoge%)]]]) 3|);
}

sub update_test {
    my $data = shift;

    $data->set(name => 'xxx');
    $data->set(data => 'XXX');
    is($data->update(id => 1), 1, q|$data->update(id => 1)|);

    has_hash($data->retrieve(id => 1),
        { id => 1, name => 'xxx', data => 'XXX' },
        q|$data->retrieve(id => 1)|);

    my $pstmt = $data->prepared_update(fields => [qw(name data)], where => [qw(id)]);
    is($pstmt->execute_only('yyy', 'YYY', 2), 1, q|$pstmt->execute_only('yyy', 'YYY', 2)|);

    has_hash($data->retrieve(id => 2),
        { id => 2, name => 'yyy', data => 'YYY' },
        q|$data->retrieve(id => 2|);

    $pstmt = $data->prepared_update([qw(name data)], [qw(id)]);
    is($pstmt->execute_only('zzz', 'ZZZ', 3), 1, q|$pstmt->execute_only('zzz', 'ZZZ', 3)|);

    has_hash($data->retrieve(id => 3),
        { id => 3, name => 'zzz', data => 'ZZZ' },
        q|$data->retrieve(id => 3|);
}

sub delete_test {
    my $data = shift;

    $data->delete(id => 1);
    has_hash($data->retrieve(id => 1), {}, q|$data->delete(id => 1)|);
}

sub create_connection {
    return new Wiz::DB::Connection(%mysql_param)
}

# Need TRIGGER.
# 
# CREATE FUNCTION func_update_last_modified() RETURNS OPAQUE AS '
# BEGIn
#     NEW.last_modified := ''now'';
#     return NEW;
# ENd;
# ' LANGUAGE 'plpgsql' VOLATILE;
#
# Hint: `createlang plpgsql DB_NAME` to use trigger.
sub create_table {
    my $conn = shift;
    eval {
        $conn->execute_only("DROP TABLE $conf{table}");
    };
    $conn->execute_only(<<"EOS");
CREATE TABLE $conf{table} (
    id SERIAL PRIMARY KEY,
    number INT,
    name VARCHAR(32),
    data TEXT,
    date_test DATE,
    created_time TIMESTAMP DEFAULT 'now',
    last_modified TIMESTAMP DEFAULT 'now'
)
EOS
    $conn->execute_only(<<"EOS");
CREATE TRIGGER trg_update_last_modifled_$conf{table}
BEFORE UPDATE ON $conf{table}
FOR EACH ROW EXECUTE PROCEDURE func_update_last_modified()
EOS
}

skip_confirm(2) and exit main;
#exit main;
