#!/usr/bin/perl

use strict;
use warnings;

use lib qw(../../lib);

use Wiz::Test qw(no_plan);

use Wiz::Constant qw(:all);
use Wiz::DB qw(alias);
use Wiz::DB::Constant qw(:all);
use Wiz::DB::SQL::Constant qw(:all);
use Wiz::DB::Connection;
use Wiz::DB::DataIO;
use Wiz::DB::PreparedStatement;
use Wiz::DB::ResultSet;

use Data::Dumper;

chtestdir;

my %mysql_param = (
    type    => DB_TYPE_MYSQL,
    db      => 'test',
    user    => 'root',
    log     => {
        stderr          => TRUE,
        stack_dump      => TRUE,
        level           => 'warn',
    },
);

sub main {
    my $conn = create_connection();
    create_data($conn);
    join_test($conn);
    return 0;
}

sub join_test {
    my $conn = shift;

    to_tables_normal($conn);
    two_tables($conn);
    four_tables($conn);
}

sub to_tables_normal {
    my $conn = shift;

    my $hoge = new Wiz::DB::DataIO($conn, 'hoge');
    my $fuga = new Wiz::DB::DataIO($conn, 'fuga');
    $hoge->join(INNER_JOIN, [ $hoge => 'fuga_id' ], [ fuga => 'id' ]);

    is $hoge->select_dump, 
        q|SELECT * FROM hoge INNER JOIN fuga ON hoge.fuga_id=fuga.id|;

    $hoge->join(INNER_JOIN, [ $hoge => 'fuga_id' ], $fuga);
    is $hoge->select_dump, 
        q|SELECT * FROM hoge INNER JOIN fuga ON hoge.fuga_id=fuga.id|;

    $hoge->clear;

    $hoge->join(DIRECT_JOIN, "INNER JOIN (SELECT * FROM hoge ON foo.id = hoge.foo_id) f ON f.id = hoge.id");
    is $hoge->select_dump, q|SELECT * FROM hoge INNER JOIN (SELECT * FROM hoge ON foo.id = hoge.foo_id) f ON f.id = hoge.id|;
}

sub two_tables {
    my $conn = shift;

    my $hoge = new Wiz::DB::DataIO($conn, 'hoge');
    my $fuga = new Wiz::DB::DataIO($conn, 'fuga');

    $hoge->join(INNER_JOIN, [ $hoge => 'fuga_id' ], [ $fuga => 'id' ]);
    is $hoge->select_dump,
        q|SELECT * FROM hoge INNER JOIN fuga ON hoge.fuga_id=fuga.id|,
        q|join(INNER_JOIN, [ $hoge => 'fuga_id' ], [ $fuga => 'id' ])|;

    my $rs = $hoge->select(fields => {hoge => 'id', fuga => ['id', 'name']});
    is $rs->next, 1, 'next';
    is_deeply 
        [ $rs->get('hoge_id'), $rs->get('fuga_id'), $rs->get('fuga_name') ],
        [qw(1 1 fuga1)], 'get';

    $hoge->alias('h');
    $fuga->alias('f');
    $hoge->join(INNER_JOIN, [ $hoge => 'fuga_id' ], [ $fuga => 'id' ]);
    is $hoge->select_dump,
        q|SELECT * FROM hoge h INNER JOIN fuga f ON h.fuga_id=f.id|,
        q|join(INNER_JOIN, [ $hoge => 'fuga_id' ], [ $fuga => 'id' ]) with alias|;

    $rs = $hoge->select(fields => {h => 'id', f => ['id', 'name']});
    is $rs->next, 1, 'next';
    is_deeply 
        [ $rs->get('h_id'), $rs->get('f_id'), $rs->get('f_name') ],
        [qw(1 1 fuga1)], 'get';

    $hoge->join(INNER_JOIN,
        [ $hoge => 'fuga_id' ],
        [ $fuga => 'id' ],
        {
            hoge    => 'a',
        },
    );
    is $hoge->select_dump,
        q|SELECT * FROM hoge a INNER JOIN fuga f ON a.fuga_id=f.id|,
        q|join(INNER_JOIN, [ $hoge => 'fuga_id' ], [ $fuga => 'id' ]) with alias|;
    $rs = $hoge->select(fields => { a => 'id', f => ['id', 'name']});
    is $rs->next, 1, 'next';
    is_deeply 
        [ $rs->get('a_id'), $rs->get('f_id'), $rs->get('f_name') ],
        [qw(1 1 fuga1)], 'get';
}

sub four_tables {
    my $conn = shift;

    my $hoge = new Wiz::DB::DataIO($conn, hoge => 'h');
    my $fuga = new Wiz::DB::DataIO($conn, fuga => 'f');
    my $bar = new Wiz::DB::DataIO($conn, bar => 'b');
    my $xxx = new Wiz::DB::DataIO($conn, xxx => 'x');

    $hoge->join(
        [INNER_JOIN, [ $hoge => 'fuga_id' ], $fuga ],
        [INNER_JOIN, [ $hoge => 'bar_id' ], $bar ],
        [INNER_JOIN, '-and',
            [ [ $hoge => 'xxx_id' ], [ $xxx => 'id' ] ],
            [ 'x.name' => IS_NOT_NULL ],
        ],
    );
    is $hoge->select_dump,
        q|SELECT * FROM ((hoge h INNER JOIN fuga f ON h.fuga_id=f.id) INNER JOIN bar b ON h.bar_id=b.id) INNER JOIN xxx x ON h.xxx_id=x.id AND x.name IS NOT NULL|,
        q|four_tables join|;

    is_deeply [ $hoge->select(fields =>
         {
       h => [qw/id name/],
       f => [qw/id name/],
       b => [qw/id name/],
       x => [qw/id name/],
         }
        ) ],
        [
            {
                'b_id' => '1',
                'f_id' => '1',
                'x_id' => '1',
                'h_id' => '1',
                'h_name' => 'hoge1',
                'f_name' => 'fuga1',
                'x_name' => 'xxx1',
                'b_name' => 'bar1'
            },
            {
                'b_id' => '2',
                'f_id' => '2',
                'x_id' => '2',
                'h_id' => '2',
                'h_name' => 'hoge2',
                'f_name' => 'fuga2',
                'x_name' => 'xxx2',
                'b_name' => 'bar2'
            },
            {
                'b_id' => '3',
                'f_id' => '3',
                'x_id' => '3',
                'h_id' => '3',
                'h_name' => 'hoge3',
                'f_name' => 'fuga3',
                'x_name' => 'xxx3',
                'b_name' => 'bar3'
            },
        ],
        q|four_tables data - all search|;

    my $rs = $hoge->select(fields => {
    h => [qw/id name/],
    f => 'id',
    }, where => { 'h.name' => [ 'like', '%2' ] });
    $rs->next;
    is_deeply $rs->data,
        {
            'b_id' => '2',
            'f_id' => '2',
            'x_id' => '2',
            'h_id' => '2',
            'h_name' => 'hoge2',
            'f_name' => 'fuga2',
            'x_name' => 'xxx2',
            'b_name' => 'bar2'
        },
        q|four_tables data - like search|;
}

sub create_connection {
    return new Wiz::DB::Connection(%mysql_param)
}

sub create_data {
    my $conn = shift;

    for (qw(hoge fuga bar xxx)) {
        $conn->table_exists($_) and $conn->execute_only("DROP TABLE $_");
    }

    my $data = new Wiz::DB::DataIO($conn, 'hoge');
    $conn->execute_only('CREATE TABLE hoge (id INT PRIMARY KEY AUTO_INCREMENT, name VARCHAR(32), fuga_id INT, bar_id int, xxx_id int, lastmodify TIMESTAMP)');
    for (1..3) {
        $data->set(name => "hoge$_", fuga_id => $_, bar_id => $_, xxx_id => $_);
        $data->insert;
    }
    $data->clear;
    $data->set(name => 'hoge');

    $data = new Wiz::DB::DataIO($conn, 'fuga');
    $conn->execute_only('CREATE TABLE fuga (id INT PRIMARY KEY AUTO_INCREMENT, name VARCHAR(32), hoge_id INT, lastmodify TIMESTAMP)');
    for (1..3) {
        $data->set(name => "fuga$_", hoge_id => $_);
        $data->insert;
    }
    $data->clear;
    $data->set(name => 'fuga');

    $data = new Wiz::DB::DataIO($conn, 'bar');
    $conn->execute_only('CREATE TABLE bar (id INT PRIMARY KEY AUTO_INCREMENT, name VARCHAR(32), lastmodify TIMESTAMP)');
    for (1..3) {
        $data->set(name => "bar$_");
        $data->insert;
    }

    $data = new Wiz::DB::DataIO($conn, 'xxx');
    $conn->execute_only('CREATE TABLE xxx (id INT PRIMARY KEY AUTO_INCREMENT, name VARCHAR(32), lastmodify TIMESTAMP)');
    for (1..3) {
        $data->set(name => "xxx$_");
        $data->insert;
    }

    $data->set(name => undef);
    $data->insert;

    $conn->commit;
}

exit main;
#skip_confirm(2) and exit main;
