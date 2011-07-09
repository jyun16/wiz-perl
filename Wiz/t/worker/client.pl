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
    },
#    table   => 'hoge',
};

sub main {
    my $worker = create_worker();
#    my $worker = create_worker_with_config();
#    $worker->register(hoge => 'HOGE', fuga => 'FUGA');
    $worker->register(abon => 'ABON');
    $worker->commit;
#    $worker->run;
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

__END__

CREATE TABLE job (
    id                      BIGINT UNSIGNED    AUTO_INCREMENT PRIMARY KEY,
    args                    TEXT,
    status                  TINYINT UNSIGNED    DEFAULT 0,
    try_count               INTEGER UNSIGNED    DEFAULT 0,
    result                  TEXT,
    error_message           VARCHAR(2048),
    created_time            DATETIME            NOT NULL,
    last_modified           TIMESTAMP
) ENGINE=innodb DEFAULT CHARACTER SET utf8 COLLATE utf8_bin;
