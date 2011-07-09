#!/usr/bin/perl

use strict;
use warnings;

use lib qw(../../lib);

use Wiz::Test qw(no_plan);
use Wiz::Util::File qw(:all);

use Data::Dumper;

chtestdir;

$| = 1;

my $cwd = cwd;
my $conf_file = 'conf/file.pdat';
my $prop_file = 'conf/file.prop';
my $test_data_dir = 'data/file_test';
my $ls_test_dir = "$test_data_dir/ls_test";
my $test_file = "$test_data_dir/test.dat";
my $config_tree_test = "$test_data_dir/config_tree_test";
my $extended_config_tree_test = "$test_data_dir/extended_config_tree_test";
my $test_data = <<EOS;
hogehoge
    fugafuga
        foo bar blah 
            you like that?
EOS
my $replace_test_dir = "data/replace_test";

sub main {
    mkdir "$ls_test_dir/.fuga";
    file_write_test();
    file_append_test();
    file_read_test();
    file_read2str_test();
    file_flush_write_test();
    file_flush_append_test();
    file_sync_write_test();
    file_sync_append_test();
    file_data_eval_test();
    fix_path_test();
    properties_test();
    config_tree_test();
    extended_config_tree_test();
    extended_config_tree_test2();
    get_absolute_path_test();
    cp_test();
    mv_test();
    mkdir_test();
    rm_empty_dir_test();
    touch_test();
    touch_a_test();
    touch_m_test();
    ls_test();
    ls_r_test();
    dirname_test();
    filename_test();
    replace_copy_test();
    return 0;
}

sub file_write_test {
    file_write($test_file, $test_data);
    file_contents($test_file, $test_data, q|file_write($test_file, $test_data)|);

    file_write($test_file, \$test_data);
    file_contents($test_file, $test_data, q|file_write($test_file, \$test_data)|);

    unlink $test_file;
}

sub file_append_test {
    my $append_data = 'aooooooooohhhhhhhhh';
    file_write($test_file, $test_data);
    file_append($test_file, $append_data);
    file_contents($test_file, $test_data . $append_data, q|file_append($test_file, $append_data)|);
    unlink $test_file;
}

sub file_read_test {
    file_write($test_file, $test_data);
    is_deeply([ file_read($test_file) ],
        [ map { chomp; $_; } split /\r?\n/, $test_data ],
        q|file_read($test_file)|);
    unlink $test_file;
}

sub file_read2str_test {
    file_write($test_file, $test_data);
    is(file_read2str($test_file), $test_data, q|file_read2str($test_file)|);
    unlink $test_file;
}

sub file_flush_write_test {
    file_flush_write($test_file, $test_data);
    file_contents($test_file, $test_data, q|file_flush_write($test_file, $test_data)|);
    unlink $test_file;
}

sub file_flush_append_test {
    my $append_data = 'aooooooooohhhhhhhhh';
    file_write($test_file, $test_data);
    file_flush_append($test_file, $append_data);
    file_contents($test_file, $test_data . $append_data, q|file_flush_append($test_file, $append_data)|);
    unlink $test_file;
}

sub file_sync_write_test {
    file_sync_write($test_file, $test_data);
    file_contents($test_file, $test_data, q|file_sync_write($test_file, $test_data)|);
    unlink $test_file;
}

sub file_sync_append_test {
    my $append_data = 'aooooooooohhhhhhhhh';
    file_write($test_file, $test_data);
    file_sync_append($test_file, $append_data);
    file_contents($test_file, $test_data . $append_data, q|file_sync_append($test_file, $append_data)|);
    unlink $test_file;
}

sub file_data_eval_test {
    my $data = {
        hoge    => 'HOGE',
        fuga    => 'FUGA',
    };

    is_deeply(file_data_eval($conf_file), $data, q|file_data_eval($conf_file)|); 
}

sub fix_path_test {
    is fix_path('/hoge/foo', '/tmp'), '/tmp';
    is fix_path('/home/foo', '.'), '/home/foo';
    is fix_path('/home/foo', '..'), '/home';
    is fix_path('/home/foo', '../..'), '/';
    is fix_path('/home/foo', './'), '/home/foo';
    is fix_path('/home/foo', '../'), '/home';
    is fix_path('/home/foo', '../..'), '/';
    is fix_path('/home/foo', 'bar'), '/home/foo/bar';
    is fix_path('/home/foo', 'bar/'), '/home/foo/bar';
    is fix_path('/home/foo', './bar'), '/home/foo/bar';
    is fix_path('/home/foo', '../bar'), '/home/bar';
    is fix_path('/home/foo', '../../bar'), '/bar';
    is fix_path('/home/foo', '../../../bar'), '/bar';
}

sub config_tree_test {
    has_hash(config_tree($config_tree_test), { 
        foo => {
            bar => {
                foo_bar => 'FOO_BAR'
            }
        },
        hoge => {
            fuga => {
                xxx => {
                    fuga_xxx => 'FUGA_XXX'
                }
            },
            yyy => {
                hoge_yyy => 'HOGE_YYY'
            }
        },
        zzz => {
            zzz => 'ZZZ'
        },
        yaml => {
            yaml_hash => {
                yaml_key02 => 'yaml_value02',
                yaml_key01 => 'yaml_value01',
                yaml_key03_array => [qw(val1 val2 val3)],
            }
        },
    }, q|config_tree($config_tree_test)|);
}

sub extended_config_tree_test {
    is_deeply extended_config_tree("$test_data_dir/test", 1), {
        'hoge' => {
                'xxx' => {
                    'yyy' => 'YYY',
                    'ddd' => {
                        'eee' => 'EEE',
                    }
                },
                'fuga' => {
                    'foo' => {
                        'bar'   => 'BAR',
                        'yyy'   => 'XXXXXX',
                        'zzz'   => {
                            'eee' => 'EEE',
                        }
                    },
                },
            },
        }, q|extended_config_tree("$test_data_dir/test")|;
}

sub extended_config_tree_test2 {
    is_deeply extended_config_tree("$extended_config_tree_test", 1), {
        'parent1_base' => {
            'parent1' => {
                'parent1_data' => 'PARENT1'
            }
        },
        'parent2_base' => {
            'parent2' => {
                'parent2_data' => 'PARENT2'
            }
        },
        'child_base' => {
            'parent2' => {
                'parent2_data' => 'PARENT2'
            },
            'parent1' => {
                'parent1_data' => 'FUGA'
            },
            'hoge' => {
                'HOGE' => 'HOGE'
            }
        }
    };
}

sub properties_test {
    my $data = {
        hoge        => 'HOGE',
        fuga        => 'FUGA',
        foo         => 'FOO',
        bar         => 'BAR',
        nonvalue1   => '',
        nonvalue2   => '',
    };
    is_deeply(properties($prop_file), $data, q|properties($prop_file)|);
}

sub get_absolute_path_test {
    is(get_absolute_path($conf_file), "$cwd/conf/file.pdat", q|get_absolute_path($conf_file)|);
}

sub cp_test {
    my $new_conf_file = $conf_file . '.bak';
    cp($conf_file, $new_conf_file);
    file_equals($conf_file, $new_conf_file, q|cp($conf_file, $new_conf_file)|);
    unlink $new_conf_file;
}

sub mv_test {
    my $new_conf_file = $conf_file . '.bak';
    my $new_new_conf_file = $new_conf_file . '.bak';
    cp($conf_file, $new_conf_file);
    mv($new_conf_file, $new_new_conf_file);

    file_equals($conf_file, $new_new_conf_file, q|mv($new_conf_file, $new_new_conf_file)|);

    unlink $new_conf_file;
    unlink $new_new_conf_file;
}

sub mkdir_test {
    my $dir1 = "$test_data_dir/_hoge";
    my $dir2 = "$dir1/_fuga";
    mkdir $dir2;
    ok(-d $dir2, q|mkdir $dir|);
    rmdir $dir2;
    rmdir $dir1;
}

sub rm_empty_dir_test {
    local $| = 1;
    my $dir1 = "$test_data_dir/_aaa";
    my $dir2 = "$dir1/_bbb";
    mkdir $dir2;
    rm_empty_dir($test_data_dir);
}

# XXX need to change tests about touch after developed Wiz::DateTime
sub touch_test {
    my $file = "$test_data_dir/hoge";
    touch($file);
    ok(-f $file, q|touch($file)|);
    unlink $file;
}

sub touch_a_test {
    my $file = "$test_data_dir/hoge";

    my $d = get_last_modify($file);
    touch_a($file);
    ok(-f $file, q|touch_a($file)|);
    unlink $file;
}

sub touch_m_test {
    my $file = "$test_data_dir/hoge";
    touch_m($file);
    ok(-f $file, q|touch_m($file)|);
    unlink $file;
}

sub ls_test {
    my $abs_ls_test_dir = get_absolute_path($ls_test_dir);

    has_array([ ls($ls_test_dir) ],
        [   
            "$ls_test_dir/hoge.txt",
            "$ls_test_dir/fuga.txt",
            "$ls_test_dir/foo",
            "$ls_test_dir/bar",
        ],
        'ls($ls_test_dir)',
    );

    has_array([ ls($ls_test_dir, LS_ALL) ],
        [   
            "$ls_test_dir/hoge.txt",
            "$ls_test_dir/fuga.txt",
            "$ls_test_dir/foo",
            "$ls_test_dir/bar",
            "$ls_test_dir/.hoge",
        ],
        'ls($ls_test_dir, LS_ALL)',
    );
    
    has_array([ ls($ls_test_dir, LS_ABS) ],
        [   
            "$abs_ls_test_dir/hoge.txt",
            "$abs_ls_test_dir/fuga.txt",
            "$abs_ls_test_dir/foo",
            "$abs_ls_test_dir/bar",
        ],
        'ls($ls_test_dir, LS_ABS)',
    );

    has_array([ ls($ls_test_dir, LS_FILE) ],
        [   
            "$ls_test_dir/hoge.txt",
            "$ls_test_dir/fuga.txt",
        ],
        'ls($ls_test_dir, LS_FILE)',
    );

    has_array([ ls($ls_test_dir, LS_DIR) ],
        [   
            "$ls_test_dir/foo",
            "$ls_test_dir/bar",
        ],
        'ls($ls_test_dir, LS_DIR)',
    );
}

sub ls_r_test {
    my $abs_ls_test_dir = get_absolute_path($ls_test_dir);

    has_array([ ls_r($ls_test_dir) ],
        [   
            "$ls_test_dir/foo",
            "$ls_test_dir/hoge.txt",
            "$ls_test_dir/fuga.txt",
            "$ls_test_dir/bar",
            "$ls_test_dir/foo/foo.txt",
            "$ls_test_dir/bar/bar.txt",
        ],
        'ls_r($ls_test_dir)',
    );

    has_array([ ls_r($ls_test_dir, LS_ABS) ],
        [   
            "$abs_ls_test_dir/hoge.txt",
            "$abs_ls_test_dir/fuga.txt",
            "$abs_ls_test_dir/foo",
            "$abs_ls_test_dir/bar",
            "$abs_ls_test_dir/foo/foo.txt",
            "$abs_ls_test_dir/bar/bar.txt",
        ],
        'ls_r($ls_test_dir, LS_ABS)',
    );

    has_array([ ls_r($ls_test_dir, LS_FILE) ],
        [   
            "$ls_test_dir/hoge.txt",
            "$ls_test_dir/fuga.txt",
            "$ls_test_dir/foo/foo.txt",
            "$ls_test_dir/bar/bar.txt",
        ],
        'ls_r($ls_test_dir, LS_FILE)',
    );

    has_array([ ls_r($ls_test_dir, LS_FILE | LS_ALL) ],
        [   
            "$ls_test_dir/.hoge",
            "$ls_test_dir/.hoge",
            "$ls_test_dir/hoge.txt",
            "$ls_test_dir/fuga.txt",
            "$ls_test_dir/foo/foo.txt",
            "$ls_test_dir/bar/bar.txt",
        ],
        'ls_r($ls_test_dir, LS_FILE | LS_ALL)',
    );

    has_array([ ls_r($ls_test_dir, LS_DIR) ],
        [   
            "$ls_test_dir/foo",
            "$ls_test_dir/bar",
        ],
        'ls_r($ls_test_dir, LS_DIR)',
    );

    has_array([ ls_r($ls_test_dir, LS_DIR | LS_ALL) ],
        [   
            "$ls_test_dir/.fuga",
            "$ls_test_dir/foo",
            "$ls_test_dir/bar",
        ],
        'ls_r($ls_test_dir, LS_DIR | LS_ALL)',
    );


    has_array([ ls_r($ls_test_dir, LS_DIR | LS_ALL | LS_ABS) ],
        [   
            "$abs_ls_test_dir/.fuga",
            "$abs_ls_test_dir/foo",
            "$abs_ls_test_dir/bar",
        ],
        'ls_r($ls_test_dir, LS_DIR | LS_ALL | LS_ABS)',
    );
}

sub dirname_test {
    my $abs_conf_file = get_absolute_path($conf_file);
    is(dirname($abs_conf_file), "$cwd/conf", q|dirname($abs_conf_file)|); 
}

sub filename_test {
    my $abs_conf_file = get_absolute_path($conf_file);
    is(filename($abs_conf_file), 'file.pdat', q|dirname($abs_conf_file)|); 
}

sub replace_copy_test {
    replace_copy(
        "$replace_test_dir/hoge",
        "$replace_test_dir/fuga",
        "s/hoge/HOGE/g",
    );

    file_contains "$replace_test_dir/fuga", "HOGE";
    file_contains "$replace_test_dir/fuga", "fuga";

    replace_copy(
        "$replace_test_dir/hoge",
        "$replace_test_dir/fuga2",
        [ "s/hoge/HOGE/g", "s/fuga/FUGA/g" ]
    );

    file_contains "$replace_test_dir/fuga2", "HOGE";
    file_contains "$replace_test_dir/fuga2", "FUGA";

    unlink "$replace_test_dir/fuga";
    unlink "$replace_test_dir/fuga2";
}

exit main;
