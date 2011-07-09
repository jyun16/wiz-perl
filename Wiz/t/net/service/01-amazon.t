#!/usr/bin/perl

use strict;
use warnings;

use Wiz::Test qw(no_plan);

use lib qw(../lib);

use Data::Dumper;

use Wiz::Net::Service::Amazon;

chtestdir;

sub main {
    my $amazon = new Wiz::Net::Service::Amazon(
#        access_key => 'AKIAIT2MWK5N2Y2CF5HQ',
#        secret_key => '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'
    );

    $amazon->access_key('AKIAIT2MWK5N2Y2CF5HQ');
    $amazon->secret_key('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');

    warn Dumper $amazon->item_search('Perl');
    return 0;
}

exit main;
