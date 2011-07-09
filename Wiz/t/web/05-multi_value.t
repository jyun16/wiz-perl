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
    date_test($afc);
    time_test($afc);
    checkbox_test($afc);
    credit_card_number_test($afc);
    return 0;
}

sub date_test {
    my $afc = shift;
    my $af = $afc->autoform('regist',
        {
            date1_y => '2008',
            date1_m => '08',
            date1_d => '11',
            date2   => '2009-02-31',
        },
        { message => undef, language => 'ja' },
    );
    is $af->value('date1'), '2008-08-11', q|$af->value('date1')|;
    is $af->html_value('date1'), '200808', q|$af->html_value('date1')|;
    is $af->value('date2'), '2009-02-31', q|$af->value('date2')|;
    is $af->html_value('date2'), '2009-02-31', q|$af->html_value('date2')|;
    is $af->tag('date3'), q|<input type="text" name="date3" value="20091231">|;

    $af->check_params;

    is_deeply $af->errors, {
        date2   => 277,
        hobby   => 2,
        name    => 2,
        txt1    => 2
    };
}

sub time_test {
    my $afc = shift;
    my $af = $afc->autoform('regist',
        {
            time1_h => '11',
            time1_mi => '22',
            time1_s => '33',
        },
        { message => undef, language => 'ja' },
    );

    is $af->value('time1'), '11:22:33', q|$af->value('time1')|;
    is $af->html_value('time1'), '112233', q|$af->html_value('time1')|;
}

sub checkbox_test {
    my $afc = shift;
    my $af = $afc->autoform('regist',
        {
            chk1  => [1,2],
        },
        { message => undef, language => 'ja' },
    ); 
    is_deeply $af->value_label('chk1'), [
        'CHECKBOX 1',
        'CHECKBOX 2',
    ], q|$af->value_label('chk1')|;
    is_deeply $af->html_value('chk1'), [
        'CHECKBOX 1',
        'CHECKBOX 2', 
    ], q|$af->html_value('chk1')|;
}

sub credit_card_number_test {
    my $afc = shift;
    my $af = $afc->autoform('regist',
        {
            credit_card_number  => '1111-2222-3333-4444',
        },
        { message => undef, language => 'ja' },
    ); 
    is $af->tag('credit_card_number'), q|<input type="text" name="credit_card_number_1" value="1111" maxlength="4" size="4">-<input type="text" name="credit_card_number_2" value="2222" maxlength="4" size="4">-<input type="text" name="credit_card_number_3" value="3333" maxlength="4" size="4">-<input type="text" name="credit_card_number_4" value="4444" maxlength="4" size="4">|, q|$af->tag('credit_card_number')|;
    is $af->html_value('credit_card_number'), q|1111-2222-3333-4444|, q|$af->html_value('credit_card_number')|;
}

exit main;
