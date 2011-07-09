#!/usr/bin/perl

use lib qw(../lib);

use Wiz::Test qw(no_plan);
use Wiz::Message;

chtestdir;

my $file_list_path = 'conf/message/file_list.pdat';

sub main {
    normal();
    file_list();
    direct();
    return 0;
}

sub normal {
    my $m = new Wiz::Message(
        base_dir    => './message',
        input_encoding  => 'UTF-8',
        output_encoding => 'UTF-8',
        encoding        => {
            input   => {
                ja  => 'UTF-8',
            },
            output  => {
                ja  => 'UTF-8',
            },
        },
        pre_load        => [qw(default)],
        language          => 'default',
    );

    is $m->get(qw(error not_null)),
        'ヌルポ',
        ,q|get(qw(error not_null))|;

    is $m->get(qw(service regist error first_name not_null)),
        '名前を入力してください',
        q|get(qw(service regist error first_name not_null))|;

    is $m->error(qw(not_null)),
        'ヌルポ',
        ,q|error(qw(not_null))|;

    $m->language('en');

    is $m->get(qw(error not_null)),
        'Null pointer exception',
        ,q|get(qw(error not_null))|;

    is $m->error(qw(not_null)),
        'Null pointer exception',
        ,q|error(qw(not_null))|;

    is $m->get(qw(service regist error first_name not_null)),
        'Please input your first name',
        q|get(qw(service regist error first_name not_null))|;

    is $m->can_use_language(), 'default', q|can_use_language|;
    is $m->can_use_language(qw(us en)), 'en', q|can_use_language(qw(us en))|;
}

sub file_list {
    my $m = new Wiz::Message(
        base_dir    => './message',
        encoding        => {
            input   => { ja  => 'UTF-8', },
            output  => { ja  => 'UTF-8', },
        },
    );
    $m->create_file_list_file($file_list_path);

    my $m2 = new Wiz::Message(
        base_dir        => './message',
        file_list_path  => $file_list_path,
        encoding        => {
            input   => { ja  => 'EUC-JP', },
            output  => { ja  => 'UTF-8', },
        },
    );

    is $m->error(qw(not_null)),
        'ヌルポ',
        ,q|error(qw(not_null)) - use file_list|;
}

sub direct {
    my $m = new Wiz::Message(
        data    => {
            en  => {
                validation    => {
                    hoge    => 'HOGE',
                },
            },
        },
        language    => 'en',
    );

    is $m->get(qw(validation hoge)), 'HOGE', q|get(qw(validation hoge))|;
    is $m->validation('hoge'), 'HOGE', q|validation('hoge')|;
    is $m->validation('xxx'), undef, q|validation('xxx')|;
    is $m->get(undef), undef, q|get(undef)|;
}

exit main;
