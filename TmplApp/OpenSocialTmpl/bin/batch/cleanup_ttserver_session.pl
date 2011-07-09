#!/usr/bin/perl

use strict;

use TokyoTyrant;
use MIME::Base64;
use Storable qw(thaw);

use Wiz::DateTime;
use Wiz::Web::Framework::BatchBase;

use OpenSocialTmpl;

my $args = get_args(<<EOS);
p(port):
-host:
EOS

sub main {
    my $rdb = get_rdb($args);
    $rdb->iterinit;
    my @keys = ();
    my $now = time;
    while (my $key = $rdb->iternext) {
        my $data = $rdb->get($key);
        $data or next;
        $data = thaw decode_base64 $data;
        if (time > $data->{expires}) {
            $rdb->out($key);        
        }
    }
    return 0;
}

sub get_rdb {
    my $rdb = new TokyoTyrant::RDB;
    $rdb->open($args->{host}, $args->{port}) or die $rdb->errmsg($rdb->ecode);
    return $rdb;
}

sub get_args {
    my ($appended) = @_;
    use Wiz::Args::Simple qw(getopts);
    my $args = getopts(<<"EOS");
e(env):
$appended
EOS
    if (!@ARGV or !$args->{p}) { ::usage(); exit 0; }
    $args->{host} ||= 'localhost';
    $ENV{WIZ_APP_ENV} = $args->{env};
    return $args;
}

sub usage {
    my ($opt, $desc) = qw(%-16s %-30s);
    print "$Wiz::Web::Framework::BatchBase::SCRIPT_NAME -p PORT [ OPTIONS ]\n\n";
    printf " $opt $desc\n", '-p, --port', '';
    printf " $opt $desc\n", '--host', 'Default is localhost';
    printf " $opt $desc\n", '-h, --help', 'Usage';
}

exit main;
