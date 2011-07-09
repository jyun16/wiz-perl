#!/usr/bin/perl

use strict;
use warnings;

use lib qw(../../lib);

use Data::Dumper;

use Wiz::Test qw(no_plan);
use Wiz::Util::Tree qw(:all);

chtestdir;

sub main {
    search_tree_test();
    dependency_tree_test();
    dependency_sequence_test();
    return 0;
}

sub search_tree_test {
    is_deeply search_tree({
        AAA => {
            AA  => {
                A   => 1,
            },
        },
        BBB => {
            BB  => 1,
        },
    }, 
    'AA',
    ), {
        AA => {
            A   => 1,    
        },
    };
};

sub dependency_tree_test {
    is_deeply dependency_tree({
        a_b   => [qw(
            a b
        )],
        a   => [qw(
            A
        )],
        b   => [qw(
            B
        )],
    }), {
        a_b => {
            a   => {
                A   => {},
            },
            b   => {
                B   => {},
            },
        },
    };
}

sub dependency_sequence_test {
    is_deeply dependency_sequence({
        a_b   => [qw(
            a b
        )],
        a   => [qw(
            A
        )],
        b   => [qw(
            B
        )],
    }), [
        [
            'A',
            'B'
        ],
        [
            'a',
            'b'
        ],
        [
            'a_b'
        ]
    ];
}

exit main;
