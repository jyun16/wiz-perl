#!/usr/bin/perl

use strict;

use IO::Prompt;

use Wiz::Constant qw(:common);
use Wiz::Args::Simple qw(getopts);
use Wiz::Auth;
use Wiz::Web::Framework::BatchBase;

sub main {
    my $args = init_args();
    my $auth = new Wiz::Auth(
        user_role       => FALSE,
        password_type   => $args->{t},
    );
    print $auth->digest_password($args->{p}) . "\n";
    return 0;
}

sub init_args {
    my $args = get_args(<<EOS);
t(type):
p(password);
EOS
    unless ($args->{p}) { $args->{p} = prompt('password: ', -te => '*'); }
    $args->{t} or do { usage(); exit 1; };
    return $args;
}

sub usage {
    my ($opt, $desc) = qw(%-16s %-30s);
    print "$Wiz::Web::Framework::BatchBase::SCRIPT_NAME -t TYPE [ OPTIONS ]\n\n";
    printf " $opt $desc\n", '-t, --type', 'Digest type';
    print <<EOS;

TYPE

    md5-hex
    md5-base64
    sha1-hex
    sha1-base64
    sha256-hex
    sha256-base64
    sha384-hex
    sha384-base64
    sha512-hex
    sha512-base64

OPTIONS

EOS
    printf " $opt $desc\n", '-p, --password', 'password';
    print "\n";
}

exit main;
