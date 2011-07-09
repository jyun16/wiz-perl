#!/usr/bin/perl

use Test::More qw(no_plan);

use lib qw(../../lib);

BEGIN { use_ok('Wiz::DB::Connection'); }
diag( "Testing Wiz::DB::Connection $Wiz::DB::Connection::VERSION" );

BEGIN { use_ok('Wiz::DB::ConnectionPool'); }
diag( "Testing Wiz::DB::ConnectionPool $Wiz::DB::ConnectionPool::VERSION" );

BEGIN { use_ok('Wiz::DB::ConnectionFactory'); }
diag( "Testing Wiz::DB::ConnectionFactory $Wiz::DB::ConnectionFactory::VERSION" );

BEGIN { use_ok('Wiz::DB::Cluster'); }
diag( "Testing Wiz::DB::Cluster $Wiz::DB::Cluster::VERSION" );

BEGIN { use_ok('Wiz::DB::DataIO'); }
diag( "Testing Wiz::DB::DataIO $Wiz::DB::DataIO::VERSION" );
