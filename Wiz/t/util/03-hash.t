#!/usr/bin/perl

use strict;
use warnings;

use lib qw(../../lib);

use Data::Dumper;
use Wiz::Test qw(no_plan);
use Wiz::Util::Hash qw(:all);

chtestdir;

sub main {
    hash_equals_test();
    hash_keys_test();
    hash_keys_format_test();
    hash_swap_test();
    hash_contains_value_test();
    args2hash_test();
    hash_access_by_list_test();
    ordered_hash_test();
    anchor_alias_test();
    hash_relatively_access_test();
    override_hash_test();
    return 1;
}

sub hash_equals_test {
    my %h1 = (
        hoge    => 'HOGE',
        fuga    => 'FUGA',
    );

    my %h2 = (
        hoge    => 'HOGE',
        fuga    => 'FUGA',
    );

    my %h3 = (
        fuga    => 'FUGA',
    );

    ok(hash_equals(\%h1, \%h2), q|hash_equals(\%h1, \%h2)|);
    ok(!hash_equals(\%h1, \%h3), q|hash_equals(\%h1, \%h3)|);
}

sub hash_keys_test {
    my %h = (
        hoge    => 'HOGE',
        fuga    => 'FUGA',
    );

    is_deeply([ hash_keys(\%h, 'HOGE') ], ['hoge'], q|hash_keys(\%h, 'HOGE')|);
    is_deeply([ hash_keys(\%h, 'NG') ], [], q|hash_keys(\%h, 'NG')|);
}

sub hash_keys_format_test {
    my %h = (
        hoge_fuga    => 'HOGE',
        foo_bar      => 'FUGA',
    );

    use Wiz::Util::String qw(normal2pascal normal2camel);
    is_deeply(hash_keys_format(\&normal2pascal, \%h), { HogeFuga => 'HOGE', FooBar => 'FUGA' }, q|hash_keys_format(\&normal2pascal, \%h)|);
    is_deeply(hash_keys_format(\&normal2camel, \%h), { hogeFuga => 'HOGE', fooBar => 'FUGA' }, q|hash_keys_format(\&normal2camel, \%h)|);
}

sub hash_swap_test {
    my %h = (
        hoge    => 'HOGE',
        fuga    => 'FUGA',
    );

    my $swaped = hash_swap(\%h);
    is_deeply($swaped, { HOGE => 'hoge', FUGA => 'fuga' }, q|hash_swap(\%h)|);
}

sub hash_contains_value_test {
    my %h = (
        hoge    => 'HOGE',
        fuga    => 'FUGA',
    );
    ok(hash_contains_value(\%h, 'HOGE'), q|hash_contains_value(\%h, 'HOGE')|);
    ok(!hash_contains_value(\%h, 'NG'), q|hash_contains_value(\%h, 'NG')|);
}

sub args2hash_test {
    my %h = (
        hoge    => 'HOGE',
        fuga    => 'FUGA',
    );
    my $args1 = args2hash(%h);
    my $args2 = args2hash(\%h);
    my $args3 = args2hash([ %h ]);
    is_deeply($args1, \%h, q|args2hash(%h)|);
    is_deeply($args2, \%h, q|args2hash(\%h)|);
    is_deeply($args3, \%h, q|args2hash([ %h ])|);
}

sub hash_access_by_list_test {
    my $map = {
        validator   => {
            error   => {
                not_null    => 'Not null',
            },
        },
        hoge        => {
            fuga    => 'FUGA',
        },
    };

    is_deeply hash_access_by_list($map, [qw(validator error)]),
        { 
            not_null    => 'Not null',
        },
        'hash_access_by_list($map, [qw(validator error)]';

    is hash_access_by_list($map, [qw(validator error not_null)]),
        'Not null',
        'hash_access_by_list($map, [qw(validator error not_null)])';

    hash_access_by_list($map, [qw(validator foo)], 'FOO');
    hash_access_by_list($map, [qw(hoge fuga)], 'XXX');

    is hash_access_by_list($map, [qw(validator foo)]),
        'FOO',
        'hash_access_by_list($map, [qw(validator foo)])';

    is hash_access_by_list($map, [qw(hoge fuga)]),
        'XXX',
        'hash_access_by_list($map, [qw(hoge fuga)])';

    hash_access_by_list($map, [qw(validator foo)], 'BAR', 1);
    is_deeply hash_access_by_list($map, [qw(validator foo)]),
        [qw(FOO BAR)],
        q|hash_access_by_list($map, [qw(validator foo)], 'FOO', 1|;
}

sub ordered_hash_test {
    my $oh = create_ordered_hash;

    $oh->{hoge} = 'HOGE';
    $oh->{fuga} = 'FUGA';
    $oh->{foo} = 'FOO';
    $oh->{bar} = 'BAR';

    is_deeply([ keys %$oh ], [qw(hoge fuga foo bar)], 'create_ordered_hash');

    delete $oh->{fuga};

    is_deeply([ keys %$oh ], [qw(hoge foo bar)], 'create_ordered_hash delete');

    ok(exists $oh->{foo}, 'create_ordered_hash exists');
    ok(!exists $oh->{fuga}, 'create_ordered_hash not exists');

    my $oh2 = array2ordered_hash(qw(
        hoge HOGE fuga FUGA foo FOO bar BAR
    ));

    is_deeply([ keys %$oh2 ], [qw(hoge fuga foo bar)], 'array2ordered_hash');
}

sub anchor_alias_test {
    my $data1 = hash_anchor_alias {
        '&user1'    => {
            name    => 'USER-1',
        },
        '&user2'    => {
            name    => 'USER-2',
        },
        '&user3'     => {
            '&foo'  => {
                bar => 'BAR',
            },
        },
        users   => [qw(*user1 *user2 *user3)],
        players    => {
            one     => '*user1',
            two     => '*user2',
            three   => '*user3',
            foo     => '*foo',
        },
    };

    is_deeply $data1, {
        user1    => {
            name    => 'USER-1',
        },
        user2    => {
            name    => 'USER-2',
        },
        user3     => {
            foo  => {
                bar => 'BAR',
            },
        },
        users   => [
            {
                name    => 'USER-1',
            },
            {
                name    => 'USER-2',
            },
            {
                foo  => {
                    bar => 'BAR',
                },
            },
        ],
        players    => {
            one     => {
                name    => 'USER-1',
            },
            two     => {
                name    => 'USER-2',
            },
            three     => {
                foo  => {
                    bar => 'BAR',
                },
            },
            foo     => {
                bar     => 'BAR',
            },
        },
    };

    my $data2 = hash_anchor_alias {
        '&list'  => [qw(hoge1 hoge2 hoge3)],
        hash   => {
            key => '*list',
        },
    };

    is_deeply $data2, {
        'hash' => {
            'key' => [
                'hoge1',
                'hoge2',
                'hoge3'
            ]
        },
        'list' => [
            'hoge1',
            'hoge2',
            'hoge3'
        ]
    };

    my $data3 = hash_anchor_alias({
        '&sub'  => sub {
            return 'hoge';
        },
        'sub2' => '*sub',
    });

    is $data3->{sub2}->(), 'hoge';

    my $data4 = hash_anchor_alias {
        '&param_base'            => {
            param1  => 'PARAM1',
            param2  => 'PARAM2',
        },
        '&parent'           => {
            name    => 'PARENT1',
            options => [qw(parent_opt1 parent_opt2)],
            param   => '*param_base',
        },
        '&parent2'  => {
            options => [qw(parent2_opt1 parent2_opt2)],
        },
        '*child:parent2:parent'    => {
            name    => 'OVERRIDDEN',
            '*param:param_base'  => {
                param2  => 'OVERRIDDEN',
            }
        },
    };

    is_deeply $data4,  {
        'parent' => {
            'options' => [
                'parent_opt1',
                'parent_opt2',
            ],
            'name' => 'PARENT1',
            'param' => {
                'param2' => 'PARAM2',
                'param1' => 'PARAM1',
            },
        },
        'parent2' => {
            'options' => [
                'parent2_opt1',
                'parent2_opt2',
            ],
        },
        'param_base' => {
            'param2' => 'PARAM2',
            'param1' => 'PARAM1',
        },
        'child' => {
            'options' => [
                'parent2_opt1',
                'parent2_opt2',
            ],
            'name' => 'OVERRIDDEN',
            'param' => {
                'param2' => 'OVERRIDDEN',
                'param1' => 'PARAM1',
            },
        },
    };
};

sub hash_relatively_access_test {
    my $data = {
        hoge    => {
            fuga    => {
                foo => {
                    bar => 'BAR',
                },
            },
            bon    => {
                abon    => 'ABON!',
            },
        },
    };
    convert_interactive_hash($data);
    is hash_relatively_access($data->{hoge}{fuga}{foo}, '../../bon/abon'), 'ABON!',
        q|hash_relatively_access_test|;
}

sub override_hash_test {
    my $base = {
        aaa => 'AAA',
        bbb => {
            ccc => 'CCC',
            ddd => {
                eee => 'EEE',
            },
        },
    };

    my $sub = {
        aaa => 'XXX',
        bbb => {
            ccc => 'XXX',
            ddd => {},
        },
    };

    is_deeply override_hash($base, $sub), {
        'bbb' => {
            'ccc' => 'XXX',
            'ddd' => {}
        },
        'aaa' => 'XXX'
    };
}

exit main;
