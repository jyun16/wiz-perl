#!/usr/bin/perl

use strict;

use lib qw(../../lib);

use Data::Dumper;
use Wiz::Test qw(no_plan);
use Wiz::Util::String::UTF8 qw(:all);

chtestdir;

sub scalar_data {
    my $hoge = 'ほげ';
    utf8_off(\$hoge);
    warn Dumper $hoge;
}

sub nested_data {
    my $hoge = {
        hoge    => 'ほげ',
        fuga    => 'ふが',
        foo     => [
            'ふー',
            {
                bar => 'ばー',
            },
        ],
        'おい' => 'やい',
    };
    warn Dumper utf8_off_recursive $hoge;
    {
        use utf8;
        $hoge = {
            hoge    => 'ほげ',
            fuga    => 'ふが',
            foo     => [
                'ふー',
                {
                    bar => 'ばー',
                },
            ],
            'おい' => 'やい',
        };
        warn Dumper utf8_off_recursive $hoge;
        warn hate_utf8_dumper (
           'ほげ', 'ふが', 'ふぉー', 
        );
    };
}

sub main{
#    scalar_data();
#    nested_data();
}

exit main;
