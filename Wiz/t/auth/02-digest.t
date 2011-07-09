#!/usr/bin/perl

use strict;
use warnings;

use lib qw(../../lib);

use Wiz::Test qw(no_plan);

use Wiz::Constant qw(:all);
use Wiz::DB::Constant qw(:all);
use Wiz::DB::Connection;
use Wiz::DB::DataIO;
use Wiz::DB::PreparedStatement;
use Wiz::DB::ResultSet;

use Wiz::Auth;
use Wiz::Auth::User;

use Data::Dumper;

chtestdir;

sub main {
    my @digest = qw(
        hexuser001 md5-hex
        b64user002 md5-base64
        hexuser003 sha1-hex
        b64user004 sha1-base64
        hexuser005 sha256-hex
        b64user006 sha256-base64
        hexuser007 sha384-hex
        b64user008 sha384-base64
        hexuser009 sha512-hex
        b64user010 sha512-base64
    );
    while (@digest) { 
        my $username = shift @digest;
        my $method = shift @digest;
        my $auth = Wiz::Auth->new(
            use_role        => FALSE,
            password_type   => $method,
        );
        $auth->{conf}{user} = {
            $username   => {
                password => $auth->digest_password('pass', $method),
            },
        };
        my $user = $auth->execute({userid => $username, password => 'pass'});
        is ($user->userid, $username, qq|$method|);
    }
    return 0;
}

exit main;
