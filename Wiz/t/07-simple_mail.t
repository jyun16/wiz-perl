#!/usr/bin/perl

use strict;
use warnings;

use Wiz::Test qw(no_plan);

use lib qw(../lib);

use Wiz qw(:all);
use Wiz::SimpleMail;

chtestdir;

is 1, 1;

exit main();

sub main {
    my $m = new Wiz::SimpleMail(
        smtp        => '7pp.jp',
        port        => 587,
        user        => 'gotouchi',
        password    => 'gotouchigachi',
    );
    my $data = <<EOS;
TEST本文
EOS
    $m->send(
        from        => '7pp@7pp.jp',
        to          => 'jn@7pp.jp',
        subject     => 'TESTですけども何か？',
        data        => $data,
        header      => {
            Subject => '',
        },
    );
    return 0;
}

