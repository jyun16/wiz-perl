#!/usr/bin/perl

use strict;
use Digest;

my $password = 'pass01';

my $md5  = Digest->new("MD5");
my $sha1 = Digest->new("SHA-1");
my $sha256 = Digest->new("SHA-256");
my $sha384 = Digest->new("SHA-384");
my $sha512 = Digest->new("SHA-512");

my $count = 1;
for my $alg ( $md5, $sha1, $sha256, $sha384, $sha512 ) {
	$alg->add($password);
	my $hex = $alg->hexdigest;
	$alg->reset;
	$alg->add($password);
	my $b64 = $alg->b64digest;
	my $username = sprintf("hexuser%03d", $count++);
	print "INSERT INTO user(user, password) VALUES ('$username', '$hex');\n";
	$username = sprintf("b64user%03d", $count++);
	print "INSERT INTO user(user, password) VALUES ('$username', '$b64');\n";
}

exit(0);


