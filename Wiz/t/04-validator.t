#!/usr/bin/perl

use strict;
use warnings;

use lib qw(../lib);

use Wiz::Test qw(no_plan);
use Wiz::Constant qw(:common);
use Wiz::Validator;
use Wiz::Validator::EN;
use Wiz::Validator::JA;
use Wiz::Validator::Constant qw(:all);
use Wiz::Message;

chtestdir;

sub main {
    constructor_test1();
    constructor_test2();
    method_test();
    outer_error_test();
    return 0;
}

sub constructor_test1 {
    my $m = new Wiz::Message(data => {
        en  => {
            validation  => {
                not_number => 'Wiz::Message NOT NUMBER',
            },
        },
    });
    my $v = new Wiz::Validator(message => $m);
    $v->is_number(number => '123c');
    is_deeply $v->messages, {
        number      => 'Wiz::Message NOT NUMBER',
    }, q|$v->messages|;
}

sub constructor_test2 {
    my $v = new Wiz::Validator(message => {
        not_number      => 'HASH NOT NUMBER',
    });
    $v->is_number(number => '123c');
    is_deeply $v->messages, {
        number      => 'HASH NOT NUMBER',
    }, q|$v->messages|;
}

sub method_test {
    my $v = new Wiz::Validator;

    is $v->is_null(null => undef), TRUE, q|is_null(null => undef)|;
    is $v->is_number(number => '123'), TRUE, q|is_number(number => '123c')|;
    is $v->is_number(number => '123c'), FALSE, q|is_number(number => '123c')|;
    is $v->is_alphabet(alphabet => 'abc'), TRUE, q|is_alphabet(alphabet => 'abc')|;
    is $v->is_alphabet(alphabet => 'ab1c'), FALSE, q|is_alphabet(alphabet => 'ab1c')|;

    is $v->not_null(null => 'hoge'), TRUE, q|not_null(null => undef)|;
    is $v->not_null(null => undef), FALSE, q|not_null(null => undef)|;

    is $v->has_error, TRUE, q|has_error|;
    is_deeply $v->errors, {
        number      => NOT_NUMBER,
        alphabet    => NOT_ALPHABET,
        null        => IS_NULL,
    }, q|errors|;

    is $v->error('number'), NOT_NUMBER, q|error('number')|;

    $v->type('ja');

    is $v->is_phone_number(phone => '03-1234-5678'), TRUE,
        q|is_phone_number(phone => '03-1234-5678')|;
    is $v->is_phone_number(phone => '03-12x34-5678'), FALSE,
        q|is_phone_number(phone => '03-12x34-5678')|;

    is $v->is_zip_code(zip_code => '111-1111'), TRUE,
        q|is_zip_code(zip_code => '111-1111')|;
    is $v->is_zip_code(zip_code => '1a1-1111'), FALSE,
        q|is_zip_code(zip_code => '1a1-1111')|;

    is $v->is_valid_date(date => '2019-02-31'), FALSE,
        q|$v->is_valid_date(date => '2019-02-31')|;

    is_deeply $v->messages, {
        null        => 'value is null',
        number      => 'value is not number',
        zip_code    => 'value is not zip code',
        phone       => 'value is not phone number',
        alphabet    => 'value is not alphabet',
        date        => 'value is not valid date',
    }, q|$v->messages|;
}

sub outer_error_test {
    my $v = new Wiz::Validator;
    is $v->is_null(null => '?'), FALSE, q|is_null(null => undef)|;
    $v->outer_error_message(hoge => 'HOGE');
    is $v->error_message('hoge'), 'HOGE', q|$v->error('hoge')|;
}

exit main;
