#!/usr/bin/perl

use strict;

use POSIX;
use FindBin;
use Wiz::Args::Simple qw(getopts);

sub main {
    my $args = init_args(<<EOS);
p(port):
h(host):
EOS
    my @args = @{$args->{no_opt_args}};
    shift @args;
    my $cmd = "tcrmgr $args->{0} -port $args->{p} $args->{h} @args";
    print `$cmd`;
    return 0;
}

sub init_args {
    my ($appended) = @_;
    my $args = getopts(<<"EOS");
    h(help)
    $appended
EOS
    if (!@ARGV or !$args->{p}) { usage(); exit 0; }
    $args->{h} ||= 'localhost';
    return $args;
}

sub usage {
    my ($opt, $desc) = qw(%-16s %-30s);
    print "$FindBin::Script -p PORT [ OPTIONS ] start|stop|restart\n\n";
    printf " $opt $desc\n", '-p, --port', '';
    printf " $opt $desc\n", '-h, --host', '';
    print <<EOS;

    ttserver_client.pl -p PORT inform
    ttserver_client.pl -p PORT put key value
    ttserver_client.pl -p PORT out key
    ttserver_client.pl -p PORT get key
    ttserver_client.pl -p PORT mget host [key...]
    ttserver_client.pl -p PORT list
    ttserver_client.pl -p PORT ext func [key [value]]
    ttserver_client.pl -p PORT sync
    ttserver_client.pl -p PORT optimize host [params]
    ttserver_client.pl -p PORT vanish
    ttserver_client.pl -p PORT copy dpath
    ttserver_client.pl -p PORT misc func [arg...]
    ttserver_client.pl -p PORT importtsv [-port num] [-nr] [-sc] host [file]
    ttserver_client.pl -p PORT restore upath
    ttserver_client.pl -p PORT setmst  [mhost]
    ttserver_client.pl -p PORT repl
EOS
}

exit main;

