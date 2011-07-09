#!/usr/bin/perl

use lib qw(../../lib);

use Wiz::Test qw(no_plan);
use Wiz::Web::Ext qw(:all);

chtestdir;

use Data::Dumper;

my $data = {
    c => {
        text    => 'C',
        cls     => 'folder',
        children    => {
            env => {
                text    => 'Envilonment',
                cls     => 'folder',
            },
            tool    => {
                text    => 'Tool',
                cls     => 'folder',
            },
        },
    },
    cpp => {
        text    => 'C++',
        cls     => 'folder',
    },
    python  => {
        text    => 'Python',
        cls     => 'folder',
    },
};

data_complement4async_tree($data);

is_deeply $data, {
    'python' => {
        'cls' => 'folder',
        'text' => 'Python'
    },
    'c' => {
        'cls' => 'folder',
        'text' => 'C',
        'children' => {
            'tool' => {
                'cls' => 'folder',
                'text' => 'Tool'
            },
            'env' => {
                'cls' => 'folder',
                'text' => 'Envilonment'
            }
        }
    },
    'cpp' => {
    'cls' => 'folder',
    'text' => 'C++'
    }
};

is_deeply data_accessor4async_tree($data, ''), [
    {
        'cls' => 'folder',
        'text' => 'Python',
        'id' => '/python'
    },
    {
        'cls' => 'folder',
        'text' => 'C',
        'id' => '/c'
    },
    {
        'cls' => 'folder',
        'text' => 'C++',
        'id' => '/cpp'
    }
];


is_deeply data_accessor4async_tree($data, 'c'), [
    {
        'cls' => 'folder',
        'text' => 'Tool',
        'id' => '/c/tool'
    },
    {
        'cls' => 'folder',
        'text' => 'Envilonment',
        'id' => '/c/env'
    }
];

__END__

sub main {
    my $data = {
        'hoge1' => {
            cls     => 'folder',
            children   => {
                'HOGE1-1'   => {
                },
                'hoge1-2',  => {
                    cls     => 'folder',
                    children => {
                        'hoge-1-2-1'    => {
                        }, 
                    },
                },
            },
        },
    };

    is_deeply data_complement4async_tree($data), {
        'hoge1' => {
            'cls' => 'folder',
            'text' => 'hoge1',
            'children' => {
                'hoge1-2' => {
                    'cls' => 'folder',
                    'text' => 'hoge1-2',
                    'children' => {
                        'hoge-1-2-1' => {
                            'cls' => 'file',
                            'text' => 'hoge-1-2-1',
                            'leaf' => 1
                        }
                    }
                },
                'HOGE1-1' => {
                    'cls' => 'file',
                    'text' => 'HOGE1-1',
                    'leaf' => 1
                }
            }
        }
    }, q|data_complement4async_tree|;

    is_deeply data_accessor4async_tree($data, 'hoge1/hoge1-2'), [
        {
            'cls' => 'folder',
            'text' => 'hoge1-2',
            'id' => '/hoge1/hoge1-2/hoge1-2',
        },
        {
            'cls' => 'file',
            'text' => 'HOGE1-1',
            'id' => '/hoge1/hoge1-2/HOGE1-1',
            'leaf' => 1
        }
    ], q|data_accessor4async_tree|;

    return 0;
}

exit main;
