#!/usr/bin/perl

use strict;

use Data::Dumper;
use Wiz::Web::Framework::BatchBase;

sub main {
    my $c = get_context;
    my $member = $c->model('Member');
    my $member_data = $member->retrieve(id => 1);
    warn Dumper $member_data;
    return 0;
}

exit main;
