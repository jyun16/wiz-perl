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
        level           => 'warn',
    },
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
    my $conn = create_connection();
    create_table($conn);

    my $data = new Wiz::DB::DataIO($conn, $conf{table});
    insert_test($data);
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
}

sub delete_test {
    my $data = shift;

    $data->delete(id => 1);
    has_hash($data->retrieve(id => 1), {}, q|$data->delete(id => 1)|);
#    has_hash($data->retrieve(id => 1),
#        {},
#        q|$data->retrieve(id => 1)|);
}

sub create_connection {
    return new Wiz::DB::Connection(%mysql_param)
}

sub create_table {
    my $conn = shift;

    if ($conn->table_exists($conf{table})) {
        $conn->execute_only("DROP TABLE $conf{table}");
    }

    $conn->execute_only(<<"EOS");
CREATE TABLE $conf{table} (id INT AUTO_INCREMENT PRIMARY KEY, name VARCHAR(32), data TEXT, timestamp TIMESTAMP) TYPE=InnoDB
EOS
}

skip_confirm(2) and exit main;
