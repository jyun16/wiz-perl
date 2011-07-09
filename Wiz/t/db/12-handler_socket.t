#!/usr/bin/perl

use strict;

use lib qw(../../lib);

use Wiz::Test qw(no_plan);

chtestdir;

use Wiz::Dumper;
use Wiz::Constant qw(:common);
use Wiz::DB::Connection;
use Wiz::DB::HandlerSocketFactory;

my $conf = {
    type            => 'mysql',
    db              => 'test',
    user            => 'root',
    host            => 'localhost',
    handler_socket  => {
        port    => 9999,
    },
    log     => {
        stderr          => TRUE,
        stack_dump      => TRUE,
        level           => 'warn',
    },
};

sub main {
#    my $hsf = new Wiz::DB::HandlerSocketFactory({
#        host => $conf->{host}, port => $conf->{handler_socket}{port}, db => $conf->{db}
#    });
#    my $hs = $hsf->open('test', 'PRIMARY', [qw(id text)]) or die $hsf->error;
#    my @data = $hs->select('>=', 1, 0, 100);
#    $hs->insert(qw(1 HOGE));
#    $hs->update('=', 1, [qw(1 XXXXXXXXX)]);
#    $hs->delete('=', 1);
}

skip_confirm(2) and exit main;
#exit main;
