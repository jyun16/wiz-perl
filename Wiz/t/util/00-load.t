#!/usr/bin/perl

use lib qw(../../lib);

use Wiz::Test qw(no_plan);

BEGIN { use_ok('Wiz::Util::Array'); }
diag( "Testing Wiz::Util::Array $Wiz::Util::Array::VERSION" );

BEGIN { use_ok('Wiz::Util::File'); }
diag( "Testing Wiz::Util::File $Wiz::Util::File::VERSION" );

BEGIN { use_ok('Wiz::Util::Hash'); }
diag( "Testing Wiz::Util::Hash $Wiz::Util::Hash::VERSION" );

BEGIN { use_ok('Wiz::Util::Math'); }
diag( "Testing Wiz::Util::Math $Wiz::Util::Math::VERSION" );

BEGIN { use_ok('Wiz::Util::String'); }
diag( "Testing Wiz::Util::String $Wiz::Util::String::VERSION" );

BEGIN { use_ok('Wiz::Util::System'); }
diag( "Testing Wiz::Util::System $Wiz::Util::System::VERSION" );

