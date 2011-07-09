#!/usr/bin/perl

use lib qw(../../lib);

use Wiz::Test qw(no_plan);
use Wiz::Constant qw(:common);
use Wiz::Web::AutoForm::Controller;
use Wiz::Validator::Constant qw(:error);

chtestdir;

use Data::Dumper;

my $config_dir = 'conf/autoform';

sub main {
    my $afc = new Wiz::Web::AutoForm::Controller($config_dir);
    multivalue_test($afc);
    value_test($afc);
    validation_test($afc);
    return 0;
}

sub multivalue_test {
    my $afc = shift;

    my $af = $afc->autoform('ja', {
    }, { message => undef, language => 'ja' });
    is $af->value('zip_code'), '', q|$af->value('zip_code')|;
    is $af->value('phone_number'), '', q|$af->value('phone_number')|;

    $af = $afc->autoform('ja', {
        zip_code        => '111-0032',
        phone_number    => '03-1111-2222',
    }, { message => undef, language => 'ja' });
    is $af->value('zip_code'), '111-0032', q|$af->value('zip_code')|;
    is $af->tag('zip_code'),
        q|<input type="text" name="zip_code_1" value="111" maxlength="3" size="3">-<input type="text" name="zip_code_2" value="0032" maxlength="4" size="4">|,
        q|$af->tag('zip_code')|;
    is $af->value('phone_number'), '03-1111-2222',
        q|$af->value('phone_number')|;
    is $af->tag('phone_number'), 
        q|<input type="text" name="phone_number_1" value="03" maxlength="5" size="5">-<input type="text" name="phone_number_2" value="1111" maxlength="5" size="5">-<input type="text" name="phone_number_3" value="2222" maxlength="5" size="5">|,
        q|$af->tag('phone_number')|;

    $af = $afc->autoform('ja', {
        zip_code_1      => '111',
        zip_code_2      => '0032',
        phone_number_1  => '03',
        phone_number_2  => '1111',
        phone_number_3  => '2222',
    }, { message => undef, language => 'ja' });

    is $af->value('zip_code'), '111-0032', q|$af->value('zip_code')|;
    is $af->tag('zip_code'),
        q|<input type="text" name="zip_code_1" value="111" maxlength="3" size="3">-<input type="text" name="zip_code_2" value="0032" maxlength="4" size="4">|,
        q|$af->tag('zip_code')|;
    is $af->value('phone_number'), '03-1111-2222',
        q|$af->value('phone_number')|;
    is $af->tag('phone_number'), 
        q|<input type="text" name="phone_number_1" value="03" maxlength="5" size="5">-<input type="text" name="phone_number_2" value="1111" maxlength="5" size="5">-<input type="text" name="phone_number_3" value="2222" maxlength="5" size="5">|,
        q|$af->tag('phone_number')|;
}

sub value_test {
    my $afc = shift;
    my $af = $afc->autoform('ja',
        {
            hobby   => "\t1\t2\t3",
        },
        { message => undef, language => 'ja' },
    );

    is_deeply $af->tag('hobby'), [
        '<input type="checkbox" name="hobby" value="1" checked>音楽鑑賞',
        '<input type="checkbox" name="hobby" value="2" checked>映画鑑賞',
        '<input type="checkbox" name="hobby" value="3" checked>楽器演奏',
        '<input type="checkbox" name="hobby" value="4">読書',
        '<input type="checkbox" name="hobby" value="5">スポーツ・体力作り',
        '<input type="checkbox" name="hobby" value="6">スポーツ観戦',
        '<input type="checkbox" name="hobby" value="7">ファッション',
        '<input type="checkbox" name="hobby" value="8">美容',
        '<input type="checkbox" name="hobby" value="9">ダイエット',
        '<input type="checkbox" name="hobby" value="10">買い物',
        '<input type="checkbox" name="hobby" value="11">ドライブ',
        '<input type="checkbox" name="hobby" value="12">街歩き',
        '<input type="checkbox" name="hobby" value="13">旅行',
        '<input type="checkbox" name="hobby" value="14">ペット',
        '<input type="checkbox" name="hobby" value="15">習い事',
        '<input type="checkbox" name="hobby" value="16">語学',
        '<input type="checkbox" name="hobby" value="17">漫画',
        '<input type="checkbox" name="hobby" value="18">ゲーム',
        '<input type="checkbox" name="hobby" value="19">テレビ',
        '<input type="checkbox" name="hobby" value="20">インターネット',
        '<input type="checkbox" name="hobby" value="21">アウトドア',
        '<input type="checkbox" name="hobby" value="22">写真撮影',
        '<input type="checkbox" name="hobby" value="23">舞台鑑賞',
        '<input type="checkbox" name="hobby" value="24">美術鑑賞',
        '<input type="checkbox" name="hobby" value="25">美術制作',
        '<input type="checkbox" name="hobby" value="26">手芸・工作',
        '<input type="checkbox" name="hobby" value="27">料理',
        '<input type="checkbox" name="hobby" value="28">お菓子作り',
        '<input type="checkbox" name="hobby" value="29">園芸・ガーデニング',
        '<input type="checkbox" name="hobby" value="30">日曜大工',
        '<input type="checkbox" name="hobby" value="31">グルメ',
        '<input type="checkbox" name="hobby" value="32">お酒',
        '<input type="checkbox" name="hobby" value="33">カラオケ',
        '<input type="checkbox" name="hobby" value="34">ギャンブル',
        '<input type="checkbox" name="hobby" value="35">その他',
    ], q|$af->tag('hobby')|;

    is_deeply $af->value_label('hobby'), [
        '音楽鑑賞',
        '映画鑑賞',
        '楽器演奏',
    ], q|$af->value_label('hobby')|;
}

sub validation_test {
    my $afc = shift;
    my $af = $afc->autoform('ja',
        {
            ta  => 'あいうえおかにくえよあ',
        },
        { message => undef, language => 'ja' },
    );
    $af->check_params;
    is $af->has_error, 1, q|$af->has_error|;
    is $af->error('ta'), 402, q|$af->error('ta')|;
}

exit main;
