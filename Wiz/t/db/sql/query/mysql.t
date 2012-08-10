#!/usr/bin/perl

use strict;
use warnings;

use lib qw(../../../../lib);

use Wiz::Test qw(no_plan);
use Wiz::Constant qw(:common);

use Wiz::DB qw(like_sub);
use Wiz::DB::Constant qw(:common);
use Wiz::DB::Connection qw(:all);
use Wiz::DB::SQL::Constant qw(:common :like);
use Wiz::DB::SQL::Where;
use Wiz::DB::SQL::Where::MySQL;
use Wiz::DB::SQL::Query qw(union);
use Wiz::DB::SQL::Query::MySQL qw(:all);

use Data::Dumper;

chtestdir;

$| = 1;

my %conf = (
    table   => 'wiz_db_test_table',
    tables  => {
        h   => 'hoge',
        f   => 'fuga',
        b   => 'bar',
    },
);

my $query = new Wiz::DB::SQL::Query(type => DB_TYPE_MYSQL, table => $conf{table});

sub main {
    count_test();
    select_test();
    insert_test();
    update_test();
    delete_test();
    sub_query_from_test();
    join_test();
    union_test();
#    skip_confirm(2) and execute_on_mysql();
#    kwic_test();
#    match_against_test();
    return 0;
}

sub count_test {
    $query->clear;

    is $query->count(-limit => [ 0, 10 ], -order => [qw(hoge)]),
        qq|SELECT COUNT(*) AS count FROM $conf{table}|,
        'count';

    $query->clear;
    is $query->count(fields => 'hoge', where => { id => 'xxx' }), 
        qq|SELECT COUNT(hoge) AS count FROM $conf{table} WHERE id=?|,
        q|count(fields => 'hoge', where => { id => 'xxx' })|;

    $query->clear;
    is $query->count({ fields => 'hoge', where => { id => 'xxx' } }), 
        qq|SELECT COUNT(hoge) AS count FROM $conf{table} WHERE id=?|,
        q|count({ fields => 'hoge', where => { id => 'xxx' } })|;

    $query->clear;
    is $query->count(fields => 'hoge', where => new Wiz::DB::SQL::Where::MySQL({ id => 'xxx' })), 
        qq|SELECT COUNT(hoge) AS count FROM $conf{table} WHERE id=?|,
        q|count(fields => 'hoge', where => new Wiz::DB::SQL::Where::MySQL({ id => 'xxx' }))|;

    is_deeply $query->values, [qw(xxx)], q|values|;

    $query->clear;
    is $query->count({ id => 'xxx' }), 
        qq|SELECT COUNT(*) AS count FROM $conf{table} WHERE id=?|,
        q|count(id => 'xxx')|;

    $query->clear;
    is $query->count(new Wiz::DB::SQL::Where::MySQL({ id => 'xxx' })), 
        qq|SELECT COUNT(*) AS count FROM $conf{table} WHERE id=?|,
        q|count(new Wiz::DB::SQL::Where::MySQL({ id => 'xxx' }))|;

    $query->clear;
    is $query->count([ -and => [[qw(!= hoge HOGE)]]]),
        qq|SELECT COUNT(*) AS count FROM $conf{table} WHERE hoge!=?|,
        q|count([ -and => [[qw(!= hoge HOGE)]]])|;

    is_deeply $query->values, [qw(HOGE)], q|values|;

    $query->clear;
    is $query->count([ -and => [['not like', 'hoge', 'HOGE']]]),
        qq|SELECT COUNT(*) AS count FROM $conf{table} WHERE hoge not like ?|,
        q|count([ -and => [['not like', 'hoge', 'HOGE']]])|;

    $query->clear;
    is $query->count_dump([ -and => [['not like', 'hoge', 'HOGE']]]),
        qq|SELECT COUNT(*) AS count FROM wiz_db_test_table WHERE hoge not like 'HOGE'|,
        q|count_dump([ -and => [['not like', 'hoge', 'HOGE']]])|;

    is_deeply $query->values, [qw(HOGE)], q|values|;
}

sub select_test {
    $query->clear;
    is $query->select, qq|SELECT * FROM $conf{table}|, q|select|;

    $query->clear;
    is $query->select(fields => 'hoge', where => { id => 'xxx' }), 
        qq|SELECT hoge FROM $conf{table} WHERE id=?|,
        q|select(fields => 'hoge', where => { id => 'xxx' })|;
    is_deeply $query->values, [qw(xxx)], q|values|;

    $query->clear;
    is $query->select_dump(fields => 'hoge', where => { id => 'xxx' }), 
        qq|SELECT hoge FROM $conf{table} WHERE id='xxx'|,
        q|select_dump(fields => 'hoge', where => { id => 'xxx' })|;
    is_deeply $query->values, [qw(xxx)], q|values|;

    $query->clear;
    is $query->select(fields => ['hoge', 'fuga'], where => { id => 'xxx' }), 
        qq|SELECT hoge,fuga FROM $conf{table} WHERE id=?|,
        q|select(hoge, fuga)|;
    is_deeply $query->values, [qw(xxx)], q|values|;

    $query->clear;
    is $query->select([ -and => [[qw(!= hoge HOGE)]]]),
        qq|SELECT * FROM $conf{table} WHERE hoge!=?|,
        q|select([ -and => [[qw(!= hoge HOGE)|;
    is_deeply $query->values, [qw(HOGE)], q|values|;

    $query->clear;
    $query->distinct(TRUE);
    is $query->select(fields => ['id', 'name']),
        qq|SELECT DISTINCT id,name FROM $conf{table}|,
        q|distinct - select(fields => ['id', 'name'])|;

    $query->clear;
    is $query->select({
        hoge    => ['!=', 'HOGE'],
        fuga    => 'FUGA',
        foo     => IS_NULL,
        bar     => IS_NOT_NULL,
    }),
    qq|SELECT * FROM $conf{table} WHERE bar IS NOT NULL AND foo IS NULL AND fuga=? AND hoge!=?|,
    q|select - and is_null|;
    is_deeply $query->values, [qw(FUGA HOGE)], q|values|;

    $query->clear;
    is $query->select_dump({
        '-and'    => [
            '-or' => [
                [ 'url', IS_NULL ],
                '-and'  => [
                    [ 'LIKE', name => like_sub(LIKE)->("FUGA") ],
                    '-in' => { rating => [1..4] },
                ],
            ],
        ],
    }), q|SELECT * FROM wiz_db_test_table WHERE (url IS NULL OR (name LIKE '%FUGA%' AND (rating IN('1','2','3','4'))))|;
}

sub insert_test {
    $query->clear;

    is $query->insert(data => { hoge => 'HOGE', fuga => 'FUGA' }),
        qq|INSERT INTO $conf{table} (fuga,hoge) VALUES (?,?)|,
        q|insert(data => { hoge => 'HOGE', fuga => 'FUGA' })|;

    is $query->insert(data => [ hoge => 'HOGE', fuga => 'FUGA' ]),
        qq|INSERT INTO $conf{table} (hoge,fuga) VALUES (?,?)|,
        q|insert(data => { hoge => 'HOGE', fuga => 'FUGA' })|;

    is $query->insert(hoge => 'HOGE', fuga => 'FUGA'),
        qq|INSERT INTO $conf{table} (fuga,hoge) VALUES (?,?)|,
        q|insert(hoge => 'HOGE', fuga => 'FUGA')|;

    is_deeply $query->values, [qw(FUGA HOGE)], q|values|;

    $query->clear;
    $query->set(foo => 'FOO');
    $query->set(bar => 'BAR');

    is $query->insert, qq|INSERT INTO $conf{table} (foo,bar) VALUES (?,?)|, q|insert|;
    is_deeply $query->values, [qw(FOO BAR)], q|values|;

    is $query->insert_dump, qq|INSERT INTO $conf{table} (foo,bar) VALUES ('FOO','BAR')|,
        q|insert_dump|;

    is $query->insert([ hoge => 'HOGE', fuga => 'FUGA' ]),
        qq|INSERT INTO $conf{table} (fuga,hoge) VALUES (?,?)|,
        q|insert([ hoge => 'HOGE', fuga => 'FUGA' ])|;
    is_deeply $query->values, [qw(FUGA HOGE)], q|values|;

    my $hoge = 'HOGE';
    is $query->insert(data => { hoge => \$hoge, fuga => 'FUGA' }),
        qq|INSERT INTO $conf{table} (fuga,hoge) VALUES (?,HOGE)|;
    is $query->insert_dump(data => { hoge => \$hoge, fuga => 'FUGA' }),
        qq|INSERT INTO $conf{table} (fuga,hoge) VALUES ('FUGA','HOGE')|;
}

sub update_test {
    $query->clear;

    is $query->update(data => { 'hoge' => 'HOGE', fuga => 'FUGA' }, where => { id => 1 }),
        qq|UPDATE $conf{table} SET fuga=?,hoge=? WHERE id=?|,
        q|update(data => { 'hoge' => 'HOGE', fuga => 'FUGA' }, where => { id => 1 })|;
    is_deeply $query->values, [qw(FUGA HOGE 1)], q|values|;

    is $query->update(data => [ 'hoge' => 'HOGE', fuga => 'FUGA' ], where => { id => 1 }),
        qq|UPDATE $conf{table} SET hoge=?,fuga=? WHERE id=?|,
        q|update(data => [ 'hoge' => 'HOGE', fuga => 'FUGA' ], where => { id => 1 })|;
    is_deeply $query->values, [qw(HOGE FUGA 1)], q|values|;

    $query->clear;
    $query->set(foo => 'FOO');
    $query->set(bar => 'BAR');
    is $query->update(id => 1),
        qq|UPDATE $conf{table} SET foo=?,bar=? WHERE id=?|, q|update(id => 1)|;

    is $query->update_dump(id => 1),
        qq|UPDATE $conf{table} SET foo='FOO',bar='BAR' WHERE id='1'|, q|update_dump(id => 1)|;

    is_deeply $query->values, [qw(FOO BAR 1)], q|values|;

    $query->clear;

    $query->set('hoge' => 'HOGE', fuga => \'FUGA');
    is $query->update, q|UPDATE wiz_db_test_table SET fuga=FUGA,hoge=?|;
    is $query->update_dump, q|UPDATE wiz_db_test_table SET fuga=FUGA,hoge='HOGE'|;
    is_deeply $query->values, [qw(HOGE)];
}

sub delete_test {
    $query->clear;

    is $query->delete(where => { id => 'xxx' }),
        qq|DELETE FROM $conf{table} WHERE id=?|,
        q|delete(where => { id => 'xxx' })|;

    is $query->delete({ id => 'xxx' }),
        qq|DELETE FROM $conf{table} WHERE id=?|,
        q|delete({ id => 'xxx' })|;
    is_deeply $query->values, [qw(xxx)], q|values|;

    is $query->delete({ -in => { id => [1,2] }, id => 'hoge' }),
        qq|DELETE FROM $conf{table} WHERE id IN(?,?) AND id=?|,
        q|delete({ -in => { id => [1,2] }, id => 'hoge' })|;
    is_deeply $query->values, [1,2,'hoge'], q|values|;

    is $query->delete(id => 'xxx'),
        qq|DELETE FROM $conf{table} WHERE id=?|,
        q|delete(id => 'xxx')|;
    is_deeply $query->values, [qw(xxx)], q|values|;

    is $query->delete(new Wiz::DB::SQL::Where({ id => 'xxx' })),
        qq|DELETE FROM $conf{table} WHERE id=?|,
        q|delete(new Wiz::DB::SQL::Where({ id => 'xxx') })|;
    is_deeply $query->values, [qw(xxx)], q|values|;

    is $query->force_delete(image => "hoge"),
        q|DELETE FROM wiz_db_test_table WHERE image=?|;
    is_deeply $query->values, [qw(hoge)], q|values|;
}

sub sub_query_from_test {
    $query->clear;

    my $sub_query = new Wiz::DB::SQL::Query(type => DB_TYPE_MYSQL, table => $conf{tables}{h});
    $sub_query->where(new Wiz::DB::SQL::Where({ id => 1 }));

    $query->sub_query($sub_query);
    is $query->sub_query, qq|(SELECT * FROM $conf{tables}{h} WHERE id=?)|,
        q|sub_query 1|;
    $query->sub_query($sub_query, 'a');
    is $query->sub_query, qq|(SELECT * FROM $conf{tables}{h} WHERE id=?) a|,
        q|sub_query 2|;
    is $query->select, qq|SELECT * FROM (SELECT * FROM $conf{tables}{h} WHERE id=?) a|,
        q|sub_query 3|;
    $query->fields(qw(id name));
    is $query->select, qq|SELECT id,name FROM (SELECT * FROM $conf{tables}{h} WHERE id=?) a|,
        q|sub_query 4|;
}

sub join_test {
    cross_join_test();
    any_join_test();
}

sub cross_join_test {
    $query->clear;

    $query->join(CROSS_JOIN, hoge => 'fuga');
    is $query->select, qq|SELECT * FROM hoge CROSS JOIN fuga|,
        q|join(CROSS_JOIN, hoge => 'fuga')|;

    $query->join([ CROSS_JOIN, hoge => 'fuga' ]);
    is $query->select, qq|SELECT * FROM hoge CROSS JOIN fuga|,
        q|join([ CROSS_JOIN, hoge => 'fuga' ])|;

    $query->join(
        [ CROSS_JOIN, hoge => 'fuga' ],
        { hoge    => 'h', fuga    => 'f', },
    );
    is $query->select, qq|SELECT * FROM hoge h CROSS JOIN fuga f|,
        q|join([ CROSS_JOIN, hoge => 'fuga' ], { hoge => 'h', fuga => 'f' })|;

    $query->join([ CROSS_JOIN, hoge => [ 'fuga', 'foo' ] ]);
    is $query->select, qq|SELECT * FROM hoge CROSS JOIN fuga CROSS JOIN foo|,
        q|join([ CROSS_JOIN, hoge => [ 'fuga', 'foo' ] ])|;
}

sub any_join_test {
    $query->clear;

    $query->join(INNER_JOIN, 'hoge.fuga_id' => 'fuga.id');
    is $query->select, qq|SELECT * FROM hoge INNER JOIN fuga ON hoge.fuga_id=fuga.id|,
        q|join(INNER_JOIN, 'hoge.fuga_id' => 'fuga.id')|;

    $query->join([ INNER_JOIN, 'hoge.fuga_id' => 'fuga.id' ], { hoge => 'h', fuga => 'f', }),
    is $query->select, qq|SELECT * FROM hoge h INNER JOIN fuga f ON h.fuga_id=f.id|,
        q|join(INNER_JOIN, 'hoge.fuga_id' => 'fuga.id', { hoge => 'h', fuga => 'f', })|;

    $query->join(
        [ INNER_JOIN, 'hoge.fuga_id' => 'fuga.id' ],
        [ LEFT_JOIN, 'hoge.bar_id' => 'bar.id' ],
        [ RIGHT_JOIN, 'hoge.xxx_id' => 'xxx.id' ],
    );
    is $query->select,
        q|SELECT * FROM ((hoge INNER JOIN fuga ON hoge.fuga_id=fuga.id) LEFT JOIN bar ON hoge.bar_id=bar.id) RIGHT JOIN xxx ON hoge.xxx_id=xxx.id|,
        q|join x 3|;

    $query->join(
        [ INNER_JOIN, 'hoge.fuga_id' => 'fuga.id' ],
        [ LEFT_JOIN, 'hoge.bar_id' => 'bar.id' ],
        [ RIGHT_JOIN, 'hoge.xxx_id' => 'xxx.id' ],
        {
            hoge    => 'h',
            fuga    => 'f',
            bar     => 'b',
            xxx     => 'x',
        },
    );
    is $query->select,
        q|SELECT * FROM ((hoge h INNER JOIN fuga f ON h.fuga_id=f.id) LEFT JOIN bar b ON h.bar_id=b.id) RIGHT JOIN xxx x ON h.xxx_id=x.id|,
        q|join x 3 with alias|;

    $query->join(
        [ INNER_JOIN, '-and', 
            [ 'hoge.fuga_id' => 'fuga.id' ],
            [ 'hoge.name' => IS_NULL ],
            [ '!=', 'fuga.name' => \"a'aa" ],
        ],
    );
    is $query->select,
        q|SELECT * FROM hoge INNER JOIN fuga ON hoge.fuga_id=fuga.id AND hoge.name IS NULL AND fuga.name!='a\'aa'|,
        q|join - and, IS_NULL, !=|;

    $query->join(
        [ INNER_JOIN, '-and', 
            [ 'hoge.fuga_id' => 'fuga.id' ],
            [ '!=', 'hoge.name' => 'fuga.name' ],
        ],
    );
    is $query->select,
        q|SELECT * FROM hoge INNER JOIN fuga ON hoge.fuga_id=fuga.id AND hoge.name!=fuga.name|,
        q|join - and|;

    $query->join(
        [ INNER_JOIN, [ '-and', 
            [ 'hoge.fuga_id' => 'fuga.id' ],
            [ '!=', 'hoge.name' => 'fuga.name' ],
        ]],
    );
    is $query->select,
        q|SELECT * FROM hoge INNER JOIN fuga ON hoge.fuga_id=fuga.id AND hoge.name!=fuga.name|,
        q|join - and|;

    $query->join(
        [ INNER_JOIN, '-and', 
            [ 'hoge.fuga_id' => 'fuga.id' ],
            [ '!=', 'hoge.name' => 'fuga.name' ],
        ],
        {
            hoge    => 'h',
            fuga    => 'f',
        },
    );
    is $query->select,
        q|SELECT * FROM hoge h INNER JOIN fuga f ON h.fuga_id=f.id AND h.name!=f.name|,
        q|join - and with alias|;

    $query->join(
        [ INNER_JOIN, '-and', 
            [ 'hoge.fuga_id' => 'fuga.id' ],
            [ '!=', 'hoge.name' => 'fuga.name' ],
            [ '-or',
                [ 'hoge.age' => 'fuga.age' ],
                [ '!=', 'hoge.type' => 'fuga.type' ],
            ],
        ],
    );
    is $query->select,
        q|SELECT * FROM hoge INNER JOIN fuga ON hoge.fuga_id=fuga.id AND hoge.name!=fuga.name AND (hoge.age=fuga.age OR hoge.type!=fuga.type)|,
        q|join - and & or|;

    $query->join(
        [ INNER_JOIN, '-and', 
            [ 'hoge.fuga_id' => 'fuga.id' ],
            [ '!=', 'hoge.name' => 'fuga.name' ],
            [ '-or',
                [ 'hoge.age' => 'fuga.age' ],
                [ '!=', 'hoge.type' => 'fuga.type' ],
            ],
        ],
        {
            hoge    => 'h',
            fuga    => 'f',
        },
    );
    is $query->select,
        q|SELECT * FROM hoge h INNER JOIN fuga f ON h.fuga_id=f.id AND h.name!=f.name AND (h.age=f.age OR h.type!=f.type)|,
        q|join - and & or with alias|;

    $query->join(
        [ INNER_JOIN, '-and', 
            [ 'hoge.fuga_id' => 'fuga.id' ],
        ],
        [ LEFT_JOIN, 'hoge.bar_id' => 'bar.id' ],
        {
            hoge    => 'h',
            fuga    => 'f',
            bar     => 'b',
        },
    );
    is $query->select,
        q|SELECT * FROM (hoge h INNER JOIN fuga f ON h.fuga_id=f.id) LEFT JOIN bar b ON h.bar_id=b.id|,
        q|mluti join - and with alias|;

    $query->join(
        [ INNER_JOIN, '-and', 
            [ 'hoge.fuga_id' => 'fuga.id' ],
            [ '!=', 'hoge.name' => 'fuga.name' ],
            [ '-or',
                [ 'hoge.age' => 'fuga.age' ],
                [ 'not like', 'hoge.type' => \'fuga.type' ],
            ],
        ],
        [ LEFT_JOIN, 'hoge.bar_id' => 'bar.id' ],
        {
            hoge    => 'h',
            fuga    => 'f',
            bar     => 'b',
        },
    );
    is $query->select,
        q|SELECT * FROM (hoge h INNER JOIN fuga f ON h.fuga_id=f.id AND h.name!=f.name AND (h.age=f.age OR h.type not like 'fuga.type')) LEFT JOIN bar b ON h.bar_id=b.id|,
        q|mluti join - and & or with alias|;
}

sub union_test {
    my $w1 = new Wiz::DB::SQL::Where::MySQL([ -and => [[ 'like', 'name', '%hoge%' ]]]);
    my $q1 = new Wiz::DB::SQL::Query::MySQL(table => 'hoge', fields => [qw(id)], where => $w1);
    my $q2 = new Wiz::DB::SQL::Query::MySQL(table => 'fuga', fields => [qw(id)], where => $w1);;
    my $w2 = new Wiz::DB::SQL::Where::MySQL({ id => 2 });

    is union($q1, $q2, $w2),
        q|(SELECT id FROM hoge WHERE name like '%hoge%') UNION (SELECT id FROM fuga WHERE name like '%hoge%') WHERE id='2'|, q|union($q1, $q2, $w2)|;
}

sub execute_on_mysql {
    no warnings qw(uninitialized);

    my $conn = new Wiz::DB::Connection(
        type        => 'mysql',
        db          => 'test',
        user        => 'root',
        auto_commit => 0,
    );

    if ($conn->table_exists($conf{table})) {
        $conn->execute_only("DROP TABLE $conf{table}");
    }
    $conn->execute_only("CREATE TABLE $conf{table} (id INT AUTO_INCREMENT PRIMARY KEY, name VARCHAR(32), data TEXT, timestamp TIMESTAMP)");

    my $query = new Wiz::DB::SQL::Query(table => $conf{table}, type => DB_TYPE_MYSQL);
    my ($name, $data) = ('HOGE', q|HOGE DATA 'XXXXXXXXXXXXXXXXX'|);

    for (1..3) {
        $query->set(name => $name . $_); $query->set(data => $data . $_);
        is($conn->execute_only($query->insert, $query->values), 1, "insert $_");
    }

    my $rs = $conn->execute($query->select); 
    is_deeply($rs->field_names, [qw(id name data timestamp)], 'field_names');

    for (1..3) {
        $rs->next;
        is($rs->get('id') . $rs->get('name') . $rs->get('data'), "$_$name$_$data$_", "select $_");
    }

    $rs = $conn->execute($query->select("id=1")); 
    $rs->next;
    is($rs->get('id'), 1, "select id=1");

    $query->clear;
    $rs = $conn->execute($query->select(new Wiz::DB::SQL::Where::MySQL([ 'id' => 1, 'id' => 2 ])), $query->values); 
    $rs->next;
    is($rs->get('id') . $rs->get('name') . $rs->get('data'), (sprintf '1%s1%s1', $name, $data), "select 1");
    $rs->next;
    is($rs->get('id') . $rs->get('name') . $rs->get('data'), (sprintf '2%s2%s2', $name, $data), "select 2");
    ok(!$rs->next, 'next fail');
}

sub kwic_test {
    my $q = new Wiz::DB::SQL::Query::MySQL(
        table => 'hoge',
        fields => [kwic('description', 60, 1, 1, '', '...', 'hoge', "<span id='keyword'>", "</span>")]
    );
    is $q->select_dump, q|SELECT kwic(description,60,1,1,"","...","hoge","<span id=\'keyword\'>","</span>") FROM hoge|;
}

sub match_against_test {
    my $query = new Wiz::DB::SQL::Query(type => DB_TYPE_MYSQL, table => $conf{table});
    is $query->select(
        -match_against  => [ 'description', 'like' ],
    ), q|SELECT * FROM wiz_db_test_table WHERE MATCH(description) AGAINST(?)|;
    is_deeply $query->values, ['like'];
}

exit main;
