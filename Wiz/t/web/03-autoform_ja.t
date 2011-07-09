#!/usr/bin/perl

use lib qw(../../lib);

use Wiz::Test qw(no_plan);
use Wiz::Constant qw(:common);
use Wiz::Web::AutoForm::Controller;
use Wiz::Validator::Constant qw(:error);
use Wiz::Message;

chtestdir;

use Data::Dumper;

my $config_dir = 'conf/autoform';

sub main {
    my $afc = new Wiz::Web::AutoForm::Controller($config_dir);
    gender_test($afc);
    hobby_test($afc);
    return 0;
}

sub gender_test {
    my $afc = shift;
    my $af = $afc->autoform('test', { gender => '1' }, { message => undef, language => 'ja' });

    is $af->tag('gender'), q|<select name="gender"><option value="">選択してください<option value="1" selected>女性<option value="2">男性</select>|, q|$af->tag('gender')|;
    is $af->value('gender'), 1, q|$af->value('gender')|;
    is $af->html_value('gender'), '女性', q|$af->html_value('gender')|;
}

sub hobby_test {
    my $afc = shift;
    my $af = $afc->autoform('test', { hobby => [ 1, 2, 3 ] }, { message => undef, language => 'ja' });

    is_deeply $af->tag("hobby"), [
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
        '<input type="checkbox" name="hobby" value="35">その他'
    ], q|$af->tag("hobby")|;

    is_deeply $af->html_value('hobby'), [
        '音楽鑑賞',
        '映画鑑賞',
        '楽器演奏'
    ], q|$af->label('hobby')|;
}

exit main;
