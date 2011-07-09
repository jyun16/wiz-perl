#!/usr/bin/perl

use strict;
use warnings;

use lib qw(../lib);

use Wiz::Test qw(no_plan);
use Wiz::Constant qw(:common);
use Wiz::Filter::Digest qw(:digest);

chtestdir;

sub main {
    is SHA256_BASE64->("hoge"), '7LZm13hyXslzBwRNZCv00WCqu3b1bABpxx6iWx6SaCU';
    return 0;
}


exit main;
