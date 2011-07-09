#!/usr/bin/perl

use lib qw(../../../../lib);

use Wiz::Test qw(no_plan);

use Wiz::DB qw(sanitize sanitize_like prelike);
use Wiz::DB::Constant qw(:common);
use Wiz::DB::SQL::Constant qw(:common);
use Wiz::DB::SQL::Where;
use Wiz::DB::SQL::Where::MySQL;
use Wiz::DB::SQL::Query qw(:query);
use Wiz::DB::SQL::Query::MySQL;

use Data::Dumper;

chtestdir;

sub main {
    simple();
    nest();
    all();
    sub_query();
    fulltext();
    return 0;
}

sub simple {
    simple_and();
    simple_or();
    simple_in();
    simple_between();
}

sub nest {
    nest_and();
    my $w = new Wiz::DB::SQL::Where::MySQL;
    $w->set({
        -or => [
            '-and', [
                [qw(like hoge %HOGE%)],
                [qw(like fuga %FUGA%)],
            ],
            '-and', [
                [qw(like foo %FOO%)],
                [qw(like bar %BAR%)],
            ],
        ]
    });
    is $w->to_string, q|WHERE (hoge like ? AND fuga like ?) OR (foo like ? AND bar like ?)|;
    is $w->to_exstring, q|WHERE (hoge like '%HOGE%' AND fuga like '%FUGA%') OR (foo like '%FOO%' AND bar like '%BAR%')|;
    is_deeply $w->values, [
        '%HOGE%',
        '%FUGA%',
        '%FOO%',
        '%BAR%'
    ];
    $w->clear;
    
    $w->set({
        '-and'    => [
            [ '!=', 'feed_url', '2' ],
        ],
    });
    is $w->to_string, q|WHERE feed_url!=?|;
    is $w->to_exstring, q|WHERE feed_url!='2'|;
    is_deeply $w->values, ['2'];

    $w->set({
        '-and'    => [
            [
                feed_url    => [
                    '!=', '2'
                ],
            ]
        ],
    });
    is $w->to_string, q|WHERE feed_url!=?|;
    is $w->to_exstring, q|WHERE feed_url!='2'|;
    is_deeply $w->values, ['2'];
}

sub all {
    all_pattern1();
    all_pattern2();
    all_pattern3();
}

sub simple_and {
    my $w = new Wiz::DB::SQL::Where::MySQL;

    $w->set(-and => [
        [qw(like meta %meta%)],
        [qw(like hoge %hoge%)],
        ['like', 'fuga', prelike q|fu%'ga|],
        -in => {
            hoge    => [qw(1 2 3)],
        },
    ]);
    is $w->to_string,
        q|WHERE meta like ? AND hoge like ? AND fuga like ? AND (hoge IN(?,?,?))|;
    is_deeply $w->values,
        [qw(%meta% %hoge% fu\%'ga% 1 2 3)];
    is $w->to_exstring,
        q|WHERE meta like '%meta%' AND hoge like '%hoge%' AND fuga like 'fu\\\\%\'ga%' AND (hoge IN('1','2','3'))|;

    $w->set([
        -and    => [
            [qw(hoge HO'GE)],
            [qw(!= fuga FU'GA)],
            ['NOT LIKE', 'foo', q|%FO'O%|],
            ['bar', IS_NULL],
        ],
    ]);
    is $w->to_string,
        q|WHERE hoge=? AND fuga!=? AND foo NOT LIKE ? AND bar IS NULL|,
        q|simple "AND" rule 1|;
    is_deeply $w->values,
        [qw(HO'GE FU'GA %FO'O%)],
        q|simple "AND" rule 1 values|;
    is $w->to_exstring,
        q|WHERE hoge='HO\'GE' AND fuga!='FU\'GA' AND foo NOT LIKE '%FO\'O%' AND bar IS NULL|,
        q|simple "AND" rule 1 ex|;

    $w->set(
        -and    => [
            [qw(hoge HO'GE)],
            [qw(!= fuga FU'GA)],
            ['NOT LIKE', 'foo', q|%FO'O%|],
            ['bar', IS_NULL],
        ],
    );
    is $w->to_string,
        q|WHERE hoge=? AND fuga!=? AND foo NOT LIKE ? AND bar IS NULL|,
        q|simple "AND" rule 2|;
    is_deeply $w->values,
        [qw(HO'GE FU'GA %FO'O%)],
        q|simple "AND" rule 2 values|;
    is $w->to_exstring,
        q|WHERE hoge='HO\'GE' AND fuga!='FU\'GA' AND foo NOT LIKE '%FO\'O%' AND bar IS NULL|,
        q|simple "AND" rule 2 ex|;

    $w->set({
        hoge    => q|HO'GE|,
        fuga    => q|FU'GA|,
    });
    is $w->to_string,
        q|WHERE fuga=? AND hoge=?|,
        q|simple "AND" rule 3|;
    is_deeply $w->values,
        [qw(FU'GA HO'GE)],
        q|simple "AND" rule 3 values|;
    is $w->to_exstring,
        q|WHERE fuga='FU\'GA' AND hoge='HO\'GE'|,
        q|simple "AND" rule 3 ex|;

    $w->set({
        hoge    => ['!=', 'HOGE'],
        fuga    => 'FUGA',
        foo     => IS_NULL,
        bar     => IS_NOT_NULL,
    });
    is $w->to_string,
        q|WHERE bar IS NOT NULL AND foo IS NULL AND fuga=? AND hoge!=?|,
        q|simple "AND" rule 4|;
    is_deeply $w->values,
        [qw(FUGA HOGE)],
        q|simple "AND" rule 4 values|;
    is $w->to_exstring,
        q|WHERE bar IS NOT NULL AND foo IS NULL AND fuga='FUGA' AND hoge!='HOGE'|,
        q|simple "AND" rule 4 ex|;

    $w->set([
        fuga => 1,
        -in => {
            hoge    => [qw(1 2 3)],
        },
    ]);
    is $w->to_string,
        q|WHERE fuga=? OR hoge IN(?,?,?)|;
    is_deeply $w->values,
        [1, 1, 2, 3];
    is $w->to_exstring,
        q|WHERE fuga='1' OR hoge IN('1','2','3')|;

    $w->set({
        fuga => 1,
        -in => {
            hoge    => [qw(1 2 3)],
        },
    });
    is $w->to_string,
        q|WHERE hoge IN(?,?,?) AND fuga=?|;
    is_deeply $w->values,
        [1, 2, 3, 1];
    is $w->to_exstring,
        q|WHERE hoge IN('1','2','3') AND fuga='1'|;

    $w->set({
        -order  => ['hoge'],
        -limit  => [0, 10],
    });
    is $w->to_string, q|ORDER BY hoge LIMIT 0,10|;

    $w->set({
        -order  => [q|ho'ge|],
        -limit  => ['a', 10],
    });
    is $w->to_string, q|ORDER BY ho\'ge|;

    $w->clear;
    $w->set(-and => [
        ['hoge', \'HOGE' ],
        -in => {
            hoge    => [1,2,3,\"NULL"],
        },
    ]);
    is $w->to_string,
        q|WHERE hoge=HOGE AND (hoge IN(?,?,?,NULL))|;
    is_deeply $w->values, [1,2,3];
    is $w->to_exstring,
        q|WHERE hoge=HOGE AND (hoge IN('1','2','3',NULL))|;

    $w->set({
        hoge    => [ 'like', '%'.sanitize_like('ho%ge').'%' ],
    });
    is $w->to_exstring, 
        q|WHERE hoge like '%ho\\\\%ge%'|;
}

sub simple_or {
    my $w = new Wiz::DB::SQL::Where::MySQL;

    $w->set([
        -or    => [
            [qw(hoge HO'GE)],
            [qw(!= fuga FU'GA)],
            ['NOT LIKE', 'foo', q|%FO'O%|],
            ['bar', IS_NULL],
        ],
    ]);
    is $w->to_string,
        q|WHERE hoge=? OR fuga!=? OR foo NOT LIKE ? OR bar IS NULL|,
        q|simple "OR" rule 1|;
    is_deeply $w->values,
        [qw(HO'GE FU'GA %FO'O%)],
        q|simple "OR" rule 1 values|;
    is $w->to_exstring,
        q|WHERE hoge='HO\'GE' OR fuga!='FU\'GA' OR foo NOT LIKE '%FO\'O%' OR bar IS NULL|,
        q|simple "OR" rule 1 ex|;

    $w->set(
        -or    => [
            [qw(hoge HO'GE)],
            [qw(!= fuga FU'GA)],
            ['NOT LIKE', 'foo', q|%FO'O%|],
            ['bar', IS_NULL],
        ],
    );
    is $w->to_string,
        q|WHERE hoge=? OR fuga!=? OR foo NOT LIKE ? OR bar IS NULL|,
        q|simple "OR" rule 2|;
    is_deeply $w->values,
        [qw(HO'GE FU'GA %FO'O%)],
        q|simple "OR" rule 2 values|;
    is $w->to_exstring,
        q|WHERE hoge='HO\'GE' OR fuga!='FU\'GA' OR foo NOT LIKE '%FO\'O%' OR bar IS NULL|,
        q|simple "OR" rule 2 ex|;

    $w->set([
        hoge    => q|HO'GE|,
        fuga    => q|FU'GA|,
    ]);
    is $w->to_string,
        q|WHERE hoge=? OR fuga=?|,
        q|simple "OR" rule 3|;
    is_deeply $w->values,
        [qw(HO'GE FU'GA)],
        q|simple "OR" rule 3 values|;
    is $w->to_exstring,
        q|WHERE hoge='HO\'GE' OR fuga='FU\'GA'|,
        q|simple "OR" rule 3 ex|;

    $w->set([
        hoge    => ['!=', 'HOGE'],
        fuga    => 'FUGA',
        foo     => IS_NULL,
        bar     => IS_NOT_NULL,
    ]);
    is $w->to_string,
        q|WHERE hoge!=? OR fuga=? OR foo IS NULL OR bar IS NOT NULL|,
        q|simple "OR" rule 4|;
    is_deeply $w->values,
        [qw(HOGE FUGA)],
        q|simple "OR" rule 4 values|;
    is $w->to_exstring,
        q|WHERE hoge!='HOGE' OR fuga='FUGA' OR foo IS NULL OR bar IS NOT NULL|,
        q|simple "OR" rule 4 ex|;

    $w->set(
        -or    => [
            [qw(like hoge HO'GE%)],
            ['NOT LIKE', 'fuga', q|%FU'GA%|],
            ['foo', IS_NULL],
        ],
    );
    is $w->to_string,
        q|WHERE hoge like ? OR fuga NOT LIKE ? OR foo IS NULL|,
        q|simple "OR" rule 5|;
    is_deeply $w->values,
        [qw(HO'GE% %FU'GA%)],
        q|simple "OR" rule 5 values|;
    is $w->to_exstring,
        q|WHERE hoge like 'HO\'GE%' OR fuga NOT LIKE '%FU\'GA%' OR foo IS NULL|,
        q|simple "OR" rule 5 ex|;
}

sub simple_in {
    my $w = new Wiz::DB::SQL::Where::MySQL;
    $w->set(
        '-in' => {
            'hoge' => [ 10, 20, "3'0" ],
        },
    );
    is $w->to_string, q|WHERE hoge IN(?,?,?)|, q|IN|;
    is_deeply $w->values, [10,20,"3'0"], q|IN values|;
    is $w->to_exstring, q|WHERE hoge IN('10','20','3\'0')|, q|IN ex|;

    $w->set(
        '-not_in' => {
            'hoge' => [ 10, 20, 30 ],
        },
    );
    is $w->to_string, q|WHERE hoge NOT IN(?,?,?)|, q|NOT IN|;
    is_deeply $w->values, [10,20,30], q|NOT IN values|;
    is $w->to_exstring, q|WHERE hoge NOT IN('10','20','30')|, q|NOT IN ex|;
}

sub simple_between {
    my $w = new Wiz::DB::SQL::Where::MySQL;
    $w->set(
        '-between' => {
            'age' => [ 10, "3'0" ],
        },
    );
    is $w->to_string, q|WHERE age BETWEEN ? AND ?|, q|BETWEEN|;
    is_deeply $w->values, [10,"3'0"], q|BETWEEN values|;
    is $w->to_exstring, q|WHERE age BETWEEN '10' AND '3\'0'|, q|BETWEEN ex|;
}

sub nest_and {
    my $w = new Wiz::DB::SQL::Where::MySQL;
    $w->set(
        -and    => [
            [qw(= hoge HOGE)],
            [qw(!= fuga FUGA)],
            -or    => [
                [qw(= foo FOO)],
                [qw(!= bar BAR)],
                -and    => [
                    [qw(= xxx XXX)],
                    [qw(!= yyy YYY)],
                ],
            ],
            -in => {
                'hoge' => [ 10, 20, 30 ],
            },
        ],
    );
    is $w->to_string,
        q|WHERE hoge=? AND fuga!=? AND (foo=? OR bar!=? OR (xxx=? AND yyy!=?)) AND (hoge IN(?,?,?))|,
        q|nested rule 1|;
    is_deeply $w->values,
        [qw(HOGE FUGA FOO BAR XXX YYY), 10, 20, 30],
        q|nested rule 1 values|;
    is $w->to_exstring,
        q|WHERE hoge='HOGE' AND fuga!='FUGA' AND (foo='FOO' OR bar!='BAR' OR (xxx='XXX' AND yyy!='YYY')) AND (hoge IN('10','20','30'))|,
        q|nested rule 1 ex|;

    $w->set(
        -and    => [
            [qw(hoge HOGE)],
            [qw(!= fuga FUGA)],
            -or    => [
                [qw(foo FOO)],
                [qw(!= bar BAR)],
                -and    => [
                    [qw(xxx XXX)],
                    [qw(!= yyy YYY)],
                ],
            ],
            -in => {
                'hoge' => [ 10, 20, 30 ],
            },
        ],
    );
    is $w->to_string,
        q|WHERE hoge=? AND fuga!=? AND (foo=? OR bar!=? OR (xxx=? AND yyy!=?)) AND (hoge IN(?,?,?))|,
        q|nested rule 2|;
    is_deeply $w->values,
        [qw(HOGE FUGA FOO BAR XXX YYY), 10, 20, 30],
        q|nested rule 2 values|;
    is $w->to_exstring,
        q|WHERE hoge='HOGE' AND fuga!='FUGA' AND (foo='FOO' OR bar!='BAR' OR (xxx='XXX' AND yyy!='YYY')) AND (hoge IN('10','20','30'))|,
        q|nested rule 2|;
}

sub all_pattern1 {
    my $w = new Wiz::DB::SQL::Where::MySQL;

    $w->set_offset_limit(0, 10);

    $w->set_order('hoge DESC', 'fuga');
    $w->append_order_desc('foo');
    $w->append_order('bar');

    $w->set_group(qw(hoge fuga));
    $w->append_group(qw(foo bar));

    is $w->to_string,
        q|GROUP BY hoge,fuga,foo,bar ORDER BY hoge DESC,fuga,foo DESC,bar LIMIT 0,10|,
        q|all pattern 1|;
}

sub all_pattern2 {
    my $w = new Wiz::DB::SQL::Where::MySQL;
    $w->set(
        -and    => [
            [qw(= hoge HOGE)],
            [qw(!= fuga FUGA)],
        ],
    );

    $w->set_offset_limit(0, 10);

    $w->set_order('hoge DESC', 'fuga');
    $w->append_order_desc('foo');
    $w->append_order('bar');

    $w->set_group(qw(hoge fuga));
    $w->append_group(qw(foo bar));

    is $w->to_string,
        q|WHERE hoge=? AND fuga!=? GROUP BY hoge,fuga,foo,bar ORDER BY hoge DESC,fuga,foo DESC,bar LIMIT 0,10|,
        q|all pattern 2|;
    is_deeply $w->values,
        [qw(HOGE FUGA)],
        q|all pattern 2 values|;
    is $w->to_exstring,
        q|WHERE hoge='HOGE' AND fuga!='FUGA' GROUP BY hoge,fuga,foo,bar ORDER BY hoge DESC,fuga,foo DESC,bar LIMIT 0,10|,
        q|all pattern 2 ex|;
}

sub all_pattern3 {
    my $w = new Wiz::DB::SQL::Where::MySQL;
    $w->set(
        -and    => [
            [qw(= hoge HOGE)],
            [qw(!= fuga FUGA)],
        ],
        -limit => [0, 10],
        -order => ['hoge DESC', 'fuga', 'foo DESC', 'bar'],
        -group => [qw(hoge fuga foo bar)],
    );

    is $w->to_string,
        q|WHERE hoge=? AND fuga!=? GROUP BY hoge,fuga,foo,bar ORDER BY hoge DESC,fuga,foo DESC,bar LIMIT 0,10|,
        q|all pattern 3|;
    is_deeply $w->values,
        [qw(HOGE FUGA)],
        q|all pattern 3 values|;
    is $w->to_exstring,
        q|WHERE hoge='HOGE' AND fuga!='FUGA' GROUP BY hoge,fuga,foo,bar ORDER BY hoge DESC,fuga,foo DESC,bar LIMIT 0,10|,
        q|all pattern 3 ex|;
}

sub sub_query {
    my $table = 'sub_query_test_table';

    my $w = new Wiz::DB::SQL::Where::MySQL;
    my $foo = new Wiz::DB::SQL::Query::MySQL(table => 'foo');
    my $bar = new Wiz::DB::SQL::Query::MySQL(table => 'bar');

    $foo->where({ id => 'FOO' });
    $bar->where({ id => 'BAR' });

    $w->set([
        -and    => [
            ['foo', $foo],
            ['!=', 'bar', $bar],
        ],        
    ]);

    is $w->to_exstring,
        qq|WHERE foo=(SELECT * FROM foo WHERE id='FOO') AND bar!=(SELECT * FROM bar WHERE id='BAR')|,
        q|sub_query 1|;
}

sub fulltext {
    my $w = new Wiz::DB::SQL::Where::MySQL;

    $w->set(
        -match_against          => [qw(title body), 'data;base'],
    );
    is $w->to_string, q|WHERE MATCH(title,body) AGAINST(?)|, q|match, against|;
    is_deeply $w->values,
        [qw(data;base)];
    is $w->to_exstring, q|WHERE MATCH(title,body) AGAINST('data\;base')|, q|match, against|;

    $w->set(
        -match_against_boolean  => [qw(title body), 'data;base'],
    );
    is $w->to_string, q|WHERE MATCH(title,body) AGAINST(? IN BOOLEAN MODE)|, q|match, against|;
    is_deeply $w->values,
        [qw(data;base)];
    is $w->to_exstring, q|WHERE MATCH(title,body) AGAINST('data\;base' IN BOOLEAN MODE)|, q|match, against|;
}

exit main;

