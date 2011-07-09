#!/usr/bin/perl

use strict;
use warnings;

use lib qw(../../lib);

use Wiz::Test qw(no_plan);
use Wiz::Constant qw(:common);
use Wiz::ReturnCode qw(:all);
use Wiz::DB::Constant qw(:all);
use Wiz::DB::ConnectionPool;

chtestdir;

my %mysql_param = (
    type        => DB_TYPE_MYSQL,
    db          => 'test',
    user        => 'root',
    auto_commit => TRUE,
    log     => {
        stderr  => TRUE,
    },
    max_active  => 8,
    min_idle    => 2,
    max_idle    => 4,
    pooling     => 1,
);

sub main {
    my $dbcp = new Wiz::DB::ConnectionPool(%mysql_param);
    pool_test($dbcp);

    return 0;
}

sub pool_test {
    my ($dbcp) = @_;

    my $dbc1 = $dbcp->get_connection;
    return_code_is($dbc1, undef) and die $dbc1->message;

    my $dbc2 = $dbcp->get_connection;

    $dbcp->status_dump;

    is($dbcp->active_count, 2, 'rent 2 conn: active 2');
    $dbc1->close;
    $dbc2->close;

    is($dbcp->active_count, 0, 'all close: active 0');
    is($dbcp->idle_count, 4, 'idle 4');

    $dbc1 = $dbcp->get_connection;
    is($dbcp->active_count, 1, 'get conn: active 1');
    is($dbcp->idle_count, 3, 'idle 3');
    $dbc1->close;

    is($dbcp->active_count, 0, 'all close: active 0');
    is($dbcp->idle_count, 4, 'idle 4');

    my @conn = ();
    for (0..7) {
        push @conn, $dbcp->get_connection;
    }

    is_undef($dbcp->get_connection);
}

skip_confirm(2) and exit main;
