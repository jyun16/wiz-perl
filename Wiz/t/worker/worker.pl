#!/usr/bin/perl

use strict;
use warnings;

use Wiz::Test qw(no_plan);

use lib qw(../lib);

use Data::Dumper;

use Wiz::Constant qw(:common);
use Wiz::DB::Connection;

use SampleWorker;

chtestdir;

my $conf = {
    db  => {
        type    => 'mysql',
        host    => 'localhost',
        db      => 'worker',
        user    => 'root',
        passwd  => '',
        auto_commit => TRUE,
    },
#    table   => 'hoge',
};

sub main {
    my $worker = create_worker();
#    my $worker = create_worker_with_config();
#    $worker->delete_on_success(FALSE);
#    $worker->run;

    $worker->create_connection(sub {
        return new Wiz::DB::Connection($conf->{db});
    });
    $worker->timer(1);

    $worker->process(5);

    $worker->work;

#    $worker->run;
#    $worker->multi_run(2);

    return 0;
}

sub create_worker {
    return new SampleWorker(
        dbc => new Wiz::DB::Connection($conf->{db}),
#        table => $conf->{table},
        auto_commit => TRUE
    );
}

sub create_worker_with_config {
    return new SampleWorker($conf->{db});
}

exit main;
