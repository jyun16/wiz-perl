#!/usr/bin/perl

use lib qw(../../lib);

use Wiz::Test qw(no_plan);
use Wiz::Constant qw(:common);
use Wiz::Web::AutoForm::Controller;
use Wiz::Validator::Constant qw(:error);
use Wiz::Message;

chtestdir;

use Data::Dumper;
use Wiz::Web::Pager::Basic;

my $config_dir = 'conf/autoform';

sub main {
#    my $afc = new Wiz::Web::AutoForm::Controller($config_dir);
    my $afc = new Wiz::Web::AutoForm::Controller($config_dir, undef, { pds_pkg => 'AutoFormTest' });
    validation_test($afc);
    tag_test($afc);
    value_test($afc);
    label_test($afc);
    value_label_test($afc);
    filter_test($afc);
    append_options($afc);
    return 0;
}

sub tag_test {
    my $afc = shift;
    my $af = $afc->autoform('register',
        { hoge => 'HOGE', fuga => 'FUGA' },
        { message => undef, language => 'ja' },
    );

    is $af->tag('txt1', '', { attribute => { size => 42 } }),
        qq|<input type="text" name="txt1" value="" maxlength="32" size="42">|,
        q|tag('txt1')|;

    is $af->tag('pw1'),
        qq|<input type="password" name="pw1" value="" maxlength="20" size="20">|,
        q|tag('pw1')|;

    is $af->tag('ta1'),
        qq|<textarea name="ta1" rows="6" cols="80"></textarea>|,
        q|tag('ta1')|;

    is $af->tag('sel1'),
        qq|<select name="sel1"><option value="">SELECT VOID<option value="0">SELECT 0<option value="1">SELECT 1<option value="2" selected>SELECT 2<option value="3">SELECT 3</select>|,
        q|tag('sel1')|;

    is $af->tag('msel1'),
        qq|<select name="msel1" multiple size="5"><option value="" selected>MULTI SELECT VOID<option value="0" selected>MULTI SELECT 0<option value="1" selected>MULTI SELECT 1<option value="2" selected>MULTI SELECT 2<option value="3">MULTI SELECT 3</select>|,
        q|tag('msel1')|;

    is $af->tag('rd1')->[0],
        qq|<input type="radio" name="rd1" value="">RADIO VOID|,
        q|tag('rd1')->[0]|;

    is $af->tag('rd1')->[1],
        qq|<input type="radio" name="rd1" value="0">RADIO 0|,
        q|tag('rd1')->[1]|;

    is $af->tag('rd1')->[2],
        qq|<input type="radio" name="rd1" value="1" id="hoge">RADIO 1|,
        q|tag('rd1')->[2]|;

    is $af->tag('rd1')->[3],
        qq|<input type="radio" name="rd1" value="2" checked>RADIO 2|,
        q|tag('rd1')->[3]|;

    is $af->tag('rd1')->[4],
        qq|<input type="radio" name="rd1" value="3">RADIO 3|,
        q|tag('rd1')->[4]|;

    is $af->tag('rd2')->[0],
        qq|<input type="radio" name="rd2" value="" id="hoge">|,
        q|tag('rd2')->[0]|;

    is $af->tag('rd2')->[1],
        qq|<input type="radio" name="rd2" value="0" id="hoge">|,
        q|tag('rd2')->[1]|;

    is $af->tag('rd2')->[2],
        qq|<input type="radio" name="rd2" value="1" id="hoge">|,
        q|tag('rd2')->[2]|;

    is $af->tag('rd2')->[3],
        qq|<input type="radio" name="rd2" value="2" id="hoge" checked>|,
        q|tag('rd2')->[3]|;

    is $af->tag('rd2')->[4],
        qq|<input type="radio" name="rd2" value="3" id="hoge">|,
        q|tag('rd2')->[4]|;

    is $af->tag('chk1')->[0],
        qq|<input type="checkbox" name="chk1" value="">CHECKBOX VOID|,
        q|tag('chk1')->[0]|;

    is $af->tag('chk1')->[1],
        qq|<input type="checkbox" name="chk1" value="0">CHECKBOX 0|,
        q|tag('chk1')->[1]|;

    is $af->tag('chk1')->[2],
        qq|<input type="checkbox" name="chk1" value="1" id="hoge">CHECKBOX 1|,
        q|tag('chk1')->[2]|;

    is $af->tag('chk1')->[3],
        qq|<input type="checkbox" name="chk1" value="2" checked>CHECKBOX 2|,
        q|tag('chk1')->[3]|;

    is $af->tag('chk1')->[4],
        qq|<input type="checkbox" name="chk1" value="3" checked>CHECKBOX 3|,
        q|tag('chk1')->[4]|;

    is $af->tag('email'),
        qq|<input type="text" name="email" value="" maxlength="255" size="60">|,
        q|tag('email')|;
}

sub value_test {
    my $afc = shift;
    my $af = $afc->autoform('register',
        { txt1 => 'TXT1', msel1 => [1,2,3] },
        { message => undef, language => 'ja' },
    );
    is $af->value('txt1'), 'TXT1', q|value|;
    is_deeply $af->value('msel1'), [1,2,3], q|value - multi|;

    $af->params(
        first_name  => 'FIRSTNAME',
        last_name  => 'LASTNAME',
    );
    is $af->value('name'), 'FIRSTNAMELASTNAME', 'value - join';
}

sub value_label_test {
    my $afc = shift;
    my $af = $afc->autoform('register',
        { txt1 => 'TXT1', msel1 => [1,2,3] },
        { message => undef, language => 'ja' },
    );

    is_deeply $af->value_label('msel1'), [
        'MULTI SELECT 1',
        'MULTI SELECT 2',
        'MULTI SELECT 3'
    ], q|value_label - multi|;
}

sub validation_test {
    my $afc = shift;
    my $af = $afc->autoform('register');

    $af->language('en');

    is $af->has_error, 0, 'has_error';
    $af->check_params;
    is $af->has_error, 1, 'has_error';

    is $af->error('txt1'), IS_EMPTY, q|error('txt1')|;

    is_deeply $af->errors, {
        txt1            => IS_EMPTY,
        name            => IS_EMPTY,
    }, q|errors|;

    $af = $afc->autoform('register', { txt1 => 'hoge' });
    is $af->has_error, 0, 'has_error';

    $af->params({});
    $af->check_params;
    is $af->error('txt1'), IS_EMPTY, q|error('txt1') IS_EMPTY|;

    $af->params({ txt1 => 'hoge' });
    $af->check_params;
    is $af->error('txt1'), NO_ERROR, q|error('txt1') NO_ERROR|;

    $af->param(txt1 => undef);
    $af->check_params;
    is $af->error('txt1'), IS_EMPTY, q|error('txt1') IS_EMPTY|;

    $af->param(txt1 => 'hoge');
    $af->check_params;
    is $af->error('txt1'), NO_ERROR, q|error('txt1') NO_ERROR|;

    $af->param(email => 'hoge');
    $af->check_params;
    is $af->error('email'), NOT_EMAIL_ADDRESS, q|error('email') NOT_EMAIL_ADDRESS|;

    $af->param(email => 'hoge@hoge.com');
    $af->check_params;
    is $af->error('email'), NO_ERROR, q|error('email') NO_ERROR|;

    is_deeply $af->errors, {
        confirm_email   => NOT_EQUALS,
        name            => IS_EMPTY,
    }, q|errors|;

    $af->param(first_name => 'first');
    $af->param(last_name => 'last');
    $af->check_params;

    is $af->value('name'), 'firstlast', q|value('name')|;

    is $af->error('confirm_email'), NOT_EQUALS, q|error|;
    is $af->error_label('confirm_email'), 'not_equals', q|error_label|;
    is $af->error_message('confirm_email'), 'is not same values', q|error_message|;

    is_deeply $af->errors, {
        confirm_email   => NOT_EQUALS,
    }, q|errors|;

    is_deeply $af->errors_labels, {
        confirm_email   => 'not_equals',
    }, q|errors_labels|;

    is_deeply $af->errors_messages, {
        confirm_email   => 'is not same values',
    }, q|errors_messages|;

    $af->params({ search => '1 1a' });
    $af->check_params;

    $af->params(ta1 => 'hogehoge');
    $af->check_params;

    is $af->has_error('ta1'), 0;
}

sub label_test {
    my $afc = shift;
    my $af = $afc->autoform('register');

    is $af->label('sel1', 2),
        qq|SELECT 2|,
        q|tag('sel1', 2)|;

    is $af->label('rd2', 1),
        qq|RADIO 1|,
        q|tag('sel1', 2)|;

    is_deeply $af->label('msel1', [2,3]),
        ['MULTI SELECT 2', 'MULTI SELECT 3'],
        q|label('msel1', [2,3])|;

    $af->param(msel1 => [2]);

    is_deeply $af->value_label('msel1'),
        ['MULTI SELECT 2'],
        q|value_label('msel1')|;

    is $af->item_label('txt1'), 'TEXT 1', q|item_label('txt1')|;

    my $msg = new Wiz::Message(data => {
        en  => {
            item_label => {
                register => {
                    txt1    => 'HOGE',
                },
            },
        },
    });
    $af->message($msg);
    is $af->item_label('txt1'), 'HOGE', q|item_label('txt1')|;

    is_deeply $af->label('sel1'), [
          'SELECT VOID',
          'SELECT 0',
          'SELECT 1',
          'SELECT 2',
          'SELECT 3'
    ], q|label('sel1')|;

    is_deeply $af->label('rd2'), [
        'RADIO VOID',
        'RADIO 0',
        'RADIO 1',
        'RADIO 2',
        'RADIO 3'
    ], q|label('rd2')|;

    is_deeply $af->tagmap('rd2'), {
      '<input type="radio" name="rd2" value="" id="hoge">'          => 'RADIO VOID',
      '<input type="radio" name="rd2" value="0" id="hoge">'         => 'RADIO 0',
      '<input type="radio" name="rd2" value="1" id="hoge">'         => 'RADIO 1',
      '<input type="radio" name="rd2" value="2" id="hoge" checked>' => 'RADIO 2',
      '<input type="radio" name="rd2" value="3" id="hoge">'         => 'RADIO 3'
    }, q|tagmap('rd2')|;
}

sub filter_test {
    my $afc = shift;
    my $af = $afc->autoform('register',
        {
            txt1    => "<strong>hoge</strong>\nfuga",
            ta1     => "<a>a</a>hoge\nfuga http://www.google.com アボン",
            sel1    => 2,
            date1   => '1975-12-7',

        },
        { message => undef, language => 'ja' },
    );
    is $af->html_value('ta1'),
        '&lt;a&gt;a&lt;/a&gt;hoge<br />fuga <a href="http://www.google.com" target="_blank">http://www.google.com</a> ｱﾎﾞﾝ', 'filterd_value';
    is $af->html_value('sel1'), 'SELECT 2', 'html_value - select';
    is $af->html_value('sel1', 3), 'SELECT 3', 'html_value - select2';
    is $af->html_value('date1'), '197512', 'html_value - date';
}

sub append_options {
    my $afc = shift;
    my $af = $afc->autoform('register',
        { hoge => 'HOGE', fuga => 'FUGA' },
        { message => undef, language => 'ja' },
    );
    $af->options('sel1', [ 1 => 'HOGE', 2 => 'FUGA' ]);
    is $af->tag('sel1'), q|<select name="sel1"><option value="1">HOGE<option value="2" selected>FUGA</select>|, q|set options by array ref|;
    $af->options('sel1', { 1 => 'HOGE', 2 => 'FUGA' });
    is $af->tag('sel1'), q|<select name="sel1"><option value="1">HOGE<option value="2" selected>FUGA</select>|, q|set options by hash ref|;
    $af->append_options('sel1', 3 => 'FOO', 4 => 'BAR');
    is $af->tag('sel1'), q|<select name="sel1"><option value="1">HOGE<option value="2" selected>FUGA<option value="3">FOO<option value="4">BAR</select>|, q|append options|;
}

exit main;
