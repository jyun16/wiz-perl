#!/usr/bin/perl

use strict;

use Wiz::Auth;
use Wiz::Args::Simple qw(getopts);

our $VERSION = '1.0';

my $args = init_args(<<'EOS');
t(type):
v(version)
h(help)
EOS

my %crypt_type = (
    md5_hex         => 1,
    md5_base64      => 1,
    sha1_hex        => 1,
    sha1_base64     => 1,
    sha256_hex      => 1,
    sha256_base64   => 1,
    sha384_hex      => 1,
    sha384_base64   => 1,
    sha512_hex      => 1,
    sha512_base64   => 1,
    sha1_hex        => 1,
    sha1_base64     => 1,
    md5_hex         => 1,
    md5_base64      => 1,
);

sub main {
    if ($args->{0} eq '' or $args->{t} eq '' or $crypt_type{$args->{t}} != 1) { usage(); exit 1; }
    print Wiz::Auth->digest_password($args->{0}, $args->{t}) . "\n";
    return 0;
}

sub init_args {
    my $args_pattern = shift;

    my $args = getopts($args_pattern);

    if (defined $args->{h}) { usage(); exit 0; }
    elsif (defined $args->{v}) { version(); exit 0; }

    return $args;
}

sub version {
    print <<EOS;
VERSION: $VERSION

          powered by Junichiro NAKAMURA
EOS
}

sub usage {
    print <<EOS;
USAGE: auth_passwd.pl -t PASSWORD

    -t, --type: crypt type

        md5_hex
        md5_base64
        sha1_hex
        sha1_base64
        sha256_hex
        sha256_base64
        sha384_hex
        sha384_base64
        sha512_hex
        sha512_base64
        sha1_hex
        sha1_base64
        md5_hex
        md5_base64

EOS
}

exit main;

__END__
