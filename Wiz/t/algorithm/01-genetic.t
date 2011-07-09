#!/usr/bin/perl

use lib qw(../lib);

use Wiz::Test qw(no_plan);
use Wiz::Dumper;
use Wiz::Algorithm::Genetic;

sub main {
    my $g = new Wiz::Algorithm::Genetic(
        data => [
            [0],
            [89, 0],
            [134,193, 0],
            [13, 419, 192, 0],
            [49, 149, 941, 231, 0],
            [394, 404, 72, 19, 1412, 0],
            [591, 1416, 492, 8, 495, 9, 0],
            [394, 191, 744, 91, 641, 248, 1941, 0],
            [949, 82, 93, 194, 481, 692, 331, 224, 0],
            [45, 321, 24, 881, 790, 281, 482, 155, 801, 0],
            [294, 362, 128, 88, 774, 650, 3, 124, 89, 10, 0],
        ],
    );
    $g->calc;
    my $res = $g->get_elite;
    warn $g->calc_score($res);
    wd $res;
    return 0;
}

exit main;
