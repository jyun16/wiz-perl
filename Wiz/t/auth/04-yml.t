#!/usr/bin/perl

use strict;
use warnings;

use lib qw(../../lib);

use Wiz::Test qw(no_plan);

use Wiz::Constant qw(:all);
use Wiz::Auth;

chtestdir;

sub main {
	my $auth = Wiz::Auth->new(
		_conf => './conf/test.yml',
	);

	my $user = $auth->execute({userid => 'teston', password => 'papas'});
    is $user->userid, 'teston';

	return 0;
}

exit main;
