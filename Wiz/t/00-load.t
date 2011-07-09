#!/usr/bin/perl

use Test::More qw(no_plan);

use lib qw(../lib);

BEGIN { use_ok('Wiz'); }
diag( "Testing Wiz $Wiz::VERSION" );

BEGIN { use_ok('Wiz'); }
diag( "Testing Wiz $Wiz::VERSION" );

BEGIN { use_ok('Wiz::DB'); }
diag( "Testing Wiz::DB $Wiz::DB::VERSION" );

BEGIN { use_ok('Wiz::Message'); }
diag( "Testing Wiz::Message $Wiz::Message::VERSION" );
