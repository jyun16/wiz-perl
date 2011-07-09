#!/usr/bin/perl

use strict;

use lib 'lib';

use Wiz::Test qw(no_plan);
use Wiz::Dumper;
use HogeConstant qw(:hoge :fuga);

sub main {
    is_deeply wcm('hoge'), {
        'HOGE_CONST1' => 1,
        'HOGE_CONST2' => 2,
        'HOGE_CONST3' => 3
    };
    is_deeply wiz_constant_map('fuga'), {
        'FUGA_CONST1' => 1,
        'FUGA_CONST2' => 2,
        'FUGA_CONST3' => 3
    };
    is HOGE_CONST1, 1;
    is HOGE_CONST2, 2;
    is HOGE_CONST3, 3;

    is FUGA_CONST1, 1;

    return 0;
}

exit main;
