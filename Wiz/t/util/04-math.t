#!/usr/bin/perl

use strict;
use warnings;

use lib qw(../../lib);

use Wiz::Test qw(no_plan);
use Wiz::Util::Math qw(:all);

chtestdir;

sub main {
    hex2dec_test();
    hex2bin_test();
    hex2str_test();
    dec2hex_test();
    dec2bin_test();
    dec2str_test();
    bin2hex_test();
    bin2dec_test();
    bin2str_test();
    str2hex_test();
    str2dec_test();
    str2decs_test();
    str2bin_test();

    return 0;
}

sub hex2dec_test {
    my $data = 'ff';
    is hex2dec('ff'), 255, q|hex2dec($data)|;
    hex2dec(\$data);
    is($data, 255, q|hex2dec(\$data)|);
}

sub hex2bin_test {
    my $data = 'ff';
    is hex2bin($data), 11111111, q|hex2bin($data)|;
    hex2bin(\$data);
    is $data, 11111111, q|hex2bin(\$data)|;
} 

sub hex2str_test {
    my $data = '4a';
    is hex2str($data), 'J', q|hex2str($data)|;
    hex2str(\$data);
    is $data, 'J', q|hex2str(\$data)|;
}

sub dec2hex_test {
    my $data = 255;
    is dec2hex($data), 'ff', q|dec2hex($data)|;
    dec2hex(\$data);
    is($data, 'ff', q|dec2hex(\$data)|);
}

sub dec2bin_test {
    my $data = 255;
    is dec2bin($data), '11111111', q|dec2bin($data)|;
    dec2bin(\$data);
    is($data, '11111111', q|dec2bin(\$data)|);
}

sub dec2str_test {
    my $data = 74;
    is dec2str($data), 'J', q|dec2str($data)|;
    is(dec2str([$data]), 'J', q|dec2str([$data])|);
    dec2str(\$data);
    is($data, 'J', q|dec2str([$data])|);
}

sub bin2hex_test {
    my $data = '11111111';
    is bin2hex($data), 'ff', q|bin2hex($data)|;
    bin2hex(\$data);
    is($data, 'ff', q|bin2hex(\$data)|);
}

sub bin2dec_test {
    my $data = '11111111';
    is bin2dec($data), 255, q|bin2dec($data)|;
    bin2dec(\$data);
    is($data, 255, q|bin2dec(\$data)|);
}

sub bin2str_test {
    my $data = '01001010';
    is bin2str($data), 'J', q|bin2str($data)|;
    bin2str(\$data);
    is($data, 'J', q|bin2str(\$data)|);
}

sub str2hex_test {
    my $data = 'J';
    is str2hex($data), '4a', q|str2hex($data)|;
    str2hex(\$data);
    is($data, '4a', q|str2hex(\$data)|);
}

sub str2dec_test {
    my $data = 'J';
    is str2dec($data), 74, q|str2dec($data)|;
    str2dec(\$data);
    is($data, 74, q|str2dec(\$data)|);
}

sub str2decs_test {
    my $data = 'JJJ';
    is_deeply str2decs($data), [qw(74 74 74)], q|str2decs($data)|;
}

sub str2bin_test {
    my $data = 'J';
    is str2bin($data), '01001010', q|str2bin($data)|;
    str2bin(\$data);
    is($data, '01001010', q|str2bin(\$data)|);
}

exit main;
