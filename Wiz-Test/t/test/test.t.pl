#!/usr/bin/perl

use lib qw(../../lib ./t/test ./lib);
use strict;
use warnings;
use Wiz::Test qw(no_plan);
use Cwd qw/realpath cwd/;

chtestdir;

$Wiz::Test::_DIAG_IN_LIKE_TEST = 0;

my $cwd = cwd . '/';
my @inc = map realpath($cwd . $_), ("./lib", "../lib", "../../lib");

has_array \@INC, \@inc, '@INC';

is_empty '', 'empty';
_is_test_ng sub {is_empty undef, "empty"}, "fail: is_empty";
_is_test_ng sub {is_empty "hoge", "empty"}, "fail: is_empty";

not_empty undef, "not empty";
not_empty "hoge", "not empty";
_is_test_ng sub {not_empty "", "empty"}, "fail: not_empty";

is_defined '', 'defined';
is_defined 'hoge', 'defined';
_is_test_ng sub {is_defined undef, "defined"}, "fail: is_defined";

is_undef undef, 'undefined';
_is_test_ng sub {is_undef '', "not defined"}, "fail: is_undef";
_is_test_ng sub {is_undef 'hoge', "not defined"}, "fail: is_undef";

has_array [1,2,3], [1,3], '[1,2,3] includes [1,3]';
has_array [1,2,3], [3]  , '[1,2,3] includes [3]';
_is_test_ng sub {has_array [1,2,3], [0, 1], "[1,2,3] not include [0]"}, "fail: has_array";
_is_test_ng sub {has_array [1,3], [1, 3, 5, 8], "[1,3] not include [5, 8]"}, "fail: has_array";

not_has_array [1,2,3], [0], '[1,2,3] not include [0]';
not_has_array [1,2,3], [4]  , '[1,2,3] not include [4]';
_is_test_ng sub {not_has_array [1,2,3], [0, 1], "[1,2,3] includes [1]"}, "fail: not_has_array 1";
_is_test_ng sub {not_has_array [1,3], [1, 3, 5, 8], "[1,3] includes [1, 3]"}, "fail: not_has_array 2";

is_die sub {die "hoge"}, 'die';
_is_test_ng sub {is_die(sub {"hoge"}, 'die')}, 'fail: is_die';

like_die_msg sub {die "hoge"}, 'hoge',  'die';
_is_test_ng sub {like_die_msg(sub {die "hoge"}, 'hage', 'die')}, 'fail: like_die_msg';

file_equals "files/equal", "files/equal", "equal";
_is_test_ng sub {file_equals("files/equal", "files/not_equal", "equal")}, "fail: file_equals";

file_contains "files/equal", qr/^b\n/m, 'file_contains';
_is_test_ng sub {file_contains "files/equal", qr/^z$/, 'file_contains';}, "fail: file_contains";

file_contains_at_line "files/equal", 0, qr/^a$/m, 'file_contains_at_line';
file_contains_at_line "files/equal", 2, qr/^c$/m, 'file_contains_at_line';
_is_test_ng sub {file_contains_at_line "files/equal", 1, qr/^a$/, 'file_contains_at_line';}, "fail: file_contains_at_line";

file_contents "files/equal", join("\n", "a" .. "g", ""), 'file_contents';
_is_test_ng  sub {file_contents "files/equal", join("\n", "a" .. "z"), 'file_contents';}, "fail: file_contains";

file_contents_at_line "files/equal", 0, 'a', 'file_contents';
_is_test_ng  sub {file_contents_at_line "files/equal", 1, "a", 'file_contents_at_line';}, "fail: file_contains_at_line";

eq_hash_keys {a => 1, b => 1, c => 2}, {a => 100, c => 20, b => 5}, 'eq_hash_keys';
_is_test_ng sub {eq_hash_keys {a => 1, b => 1, c => 2, d => 3}, {a => 100, c => 20, b => 5, z => 100}, 'eq_hash_keys';}, "fail: eq_hash_keys";

has_hash {a => 1, b => 1, c => 2}, {a => 1, c => 2}, 'has_hash';
_is_test_ng sub {has_hash {a => 1, b => 1, c => 2}, {a => 1, c => 2, d => 3}, 'has_hash';}, "fail: has_hash";

has_hash_keys {a => 1, b => 1, c => 2}, {a => 3, c => 34}, 'has_hash_keys';
_is_test_ng sub {has_hash_keys {a => 1, b => 1, c => 2}, {a => 3, c => 4, d => 5}, 'has_hash_keys';}, "fail: has_hash_keys";

has_structure {
    a   => 1,
    b   => 1,
    c   => 2,
    d   => [1,
        {
            a   => 1, 
            b   => 2, 
        },
        3,
    ],
}, {
    a   => 1,
    c   => 2,
    d   => [
        1,
        {
            a   => 1,
        },
    ],
},'has_structure';

_is_test_ng sub {
    has_structure {
        a   => 1,
        b   => 1,
        c   => 2,
        d   => [1,
            {
                a   => 1, 
                b   => 2, 
            },
            3,
        ],
    }, {
        a   => 1,
        c   => 2,
        d   => [
            2,
            {
                a   => 1,
            },
        ],
    },
},'fail: has_structure';

_is_test_ng sub {
    has_structure {
        a   => 1,
        b   => 1,
        c   => 2,
        d   => [1,2,3,4],
    }, {
        a   => 1,
        c   => 2,
        d   => [5],
    },
}, 'fail: has_structure';

_is_test_ng sub {
    has_structure {
        a   => 1,
        b   => 1,
        c   => 2,
        d   => [1,2,3,4],
    }, {
        a   => 1,
        c   => 2,
        d   => 1,
    },
}, 'fail: has_structure';

not_has_structure {
    a   => 1,
    b   => 1,
    c   => 2,
    d   => [1,
        {
            a   => 1, 
            b   => 2, 
        },
        3,
    ],
}, {
    d   => [
        {
            a   => 4,
        },
    ],
},'not_has_structure';

_is_test_ng sub {
    not_has_structure {
        a   => 1,
        b   => 1,
        c   => 2,
        d   => [1,
            {
                a   => 1, 
                b   => 2, 
            },
            3,
        ],
    }, {
        d   => [
            {
                a   => 1,
            },
        ],
    },
}, 'fail: not_has_structure';

has_hash_keys {
    hoge    => 'HOGE',
    fuga    => 'FUGA',
    foo     => {
        bar => 'BAR',
    },
}, {
    hoge    => 1,
    foo => {
        bar => 1,
    },
}, 'has_hash_keys';

_is_test_ng sub {
    has_hash_keys {
        hoge    => 'HOGE',
        fuga    => 'FUGA',
        foo     => {
            bar => 'BAR',
        },
    }, {
        hoge    => 1,
        foo => {
            bar     => 1,
            bobobo  => 1,
        },
    },
}, 'fail: has_hash_keys';

not_has_hash_keys {
    hoge    => 'HOGE',
    fuga    => 'FUGA',
    foo     => {
        bar => 'BAR',
    },
}, {
    foo => {
        xxx => 1,
    },
}, 'not_has_hash_keys';


_is_test_ng sub {
    not_has_hash_keys {
        hoge    => 'HOGE',
        fuga    => 'FUGA',
        foo     => {
            bar => 'BAR',
        },
    }, {
        foo => {
            bar => 1,
        },
    },
}, 'fail: not_has_hash_keys';
