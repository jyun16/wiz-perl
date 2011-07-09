#!/usr/bin/perl

use strict;

use lib qw(../lib);

use Wiz::Noose;
use Wiz::Test qw(no_plan);
use Wiz::Net::Service::LinkShare;

chtestdir;

sub main {
    my $link_share = new Wiz::Net::Service::LinkShare(
        token => '3b86021fe896e576f2dae423067dd85617ea3c97dabbcb94974e668dd69c683e',
    );

#    wd $link_share->product_search({
#    });

    wd $link_share->product_search(
        and         => 'a',
        max         => 10,
        sort_desc   => 'product',
        sort        => 'price',
    );
    return 0;
}

exit main;
