#!/usr/bin/perl

use strict;
use warnings;

use Wiz::Test qw(no_plan);

use lib qw(../lib);

use Data::Dumper;

use Wiz::Net::Service::Twitter;

chtestdir;

sub main {
#    my $client = new Wiz::Net::Service::Twitter(
#        basic => 1,
#        user_info => {
#            username => '',
#            password => '',
#        },
#    );
#    warn Dumper $client->verify_credentials;
    return 0;
}

exit main;
