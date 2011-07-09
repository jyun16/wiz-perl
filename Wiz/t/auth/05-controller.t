#!/usr/bin/perl

use strict;
use warnings;

use lib qw(../../lib);

use Wiz::Test qw(no_plan);

use Wiz::Constant qw(:all);
use Wiz::Auth::Controller;

chtestdir;

sub main {
	my $ac = Wiz::Auth::Controller->new(
        authz   => {
            default => {
                user    => {
                    hoge => {
                        password    => 'HOGE',
                    },
                    fuga => {
                        password    => 'FUGA',
                        roles       => {
                            read    => 1,
                        },
                    },
                },
            },
            admin   => {
                password_type   => 'sha512_base64',
                user    => {
                    root => {
                        password    => 'UJvcRtCocT2OEX5OlXNLiOqxcwZxHd4rPF4rTjEv7JdoQtGnkbBsw6677/4OGyQsBAVA01+FOFvLsoopUIvusA',
                    },
                },
            }
        },
	);

    my $default = $ac->auth;
    is_undef $default->execute(userid => 'root', password => 'ROOT');
    has_hash $default->execute(userid => 'hoge', password => 'HOGE'),
        {
            'user' => {
                userid      => 'hoge',
                label       => 'default',
            }
        };
    is_undef $default->execute(userid => 'hoge', password => 'XXX');

    my $hoge = $default->execute(userid => 'hoge', password => 'HOGE');
    my $fuga = $default->execute(userid => 'fuga', password => 'FUGA');

    is $hoge->has_role('read'), 0;
    is $fuga->has_role('read'), 1;

    my $auth = $ac->auth('admin');
    has_hash $auth->execute(userid => 'root', password => 'ROOT'),
        {
            'user' => {
                'userid' => 'root'
            }
        };
    is_undef $auth->execute(userid => 'hoge', password => 'HOGE');

    return 0;
}

exit main;
