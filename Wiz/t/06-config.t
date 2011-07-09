#!/usr/bin/perl

use lib qw(../lib);

package main;

use Wiz::Test qw(no_plan);
use Wiz::Web qw(:all);
use Wiz::Config qw(load_config_files);

use Data::Dumper;

is 1, 1;

my $conf_dir = 'conf/test';

#is_deeply load_config_files("$conf_dir/config.pdat", "$conf_dir/config2.pdat"), {
#    hoge    => 'HOGE',
#    fuga    => 'FUGA',
#}, 'load PDAT';

#is_deeply load_config_files("$conf_dir/config.yaml"), {
#    hoge    => 'HOGE',
#    fuga    => 'FUGA',
#}, 'load YAML';

#is_deeply load_config_files("$conf_dir/config.json"), {
#    hoge    => 'HOGE',
#    fuga    => 'FUGA',
#}, 'load JSON';

