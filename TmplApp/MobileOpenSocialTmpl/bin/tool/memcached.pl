#!/usr/bin/perl

use strict;

use POSIX;

use Wiz::Args::Simple qw(getopts);

my $MEMCACHED = '/usr/bin/memcached -d';
my $PKILL = '/usr/bin/pkill';

my $args = init_args('u:p:c:l:h');

$| = 1;

sub main {
    no strict 'refs';
    $args->{0}->();
    return 0;
}

sub _ope {
    my ($ope) = @_;
    no strict 'refs';
    if ($args->{c}) {
        if ($args->{l}) { $ope->("$MEMCACHED $args->{c}{$args->{l}}"); }
        else { for (keys %{$args->{c}}) { $ope->("$MEMCACHED $args->{c}{$_}"); } }
    }
    else { $ope->("$MEMCACHED -p $args->{p} -u $args->{u}"); }
}

sub start {
    _ope('_start');
}

sub stop {
    _ope('_stop');
}

sub stat {
    _ope('_stat');
}

sub restart {
    stop();
    start();
}

sub _start {
    my ($cmd) = @_;
    print "Start: $cmd\n";
    _stat($cmd) and do { print "Already started.\n"; return; };
    `$cmd`;
    my $code = $? / 256;
    unless ($code) {
        my $cnt = 0;
        while(!_stat($cmd)) {
            print ".";
            $cnt++ > 10 and die "\n[FAILED]";
            select undef, undef, undef, 0.5;
        }
        print "[SUCCESS]\n";
        return;
    }
    die "[FAILED]";
}

sub _stop {
    my ($cmd) = @_;
    print "Stop: $cmd\n";
    _stat($cmd) or do { print "Already stopped.\n"; return; };
    `$PKILL -f "$cmd"`;
    my $cnt = 0;
    while(_stat($cmd)) {
        print ".";
        $cnt++ > 10 and die "\n[FAILED]";
        select undef, undef, undef, 0.5;
    }
    print "[SUCCESS]\n";
}

sub _stat {
    my ($cmd) = @_;
    grep /$cmd/, `ps -ef`;
}

sub _print_stat {
    my ($cmd) = @_;
    print (_stat($cmd) ? "Exists $cmd\n" : "Not Exists $cmd\n");
}

sub init_args {
    my $args_pattern = shift;
    getuid and die "Please execute by root user.";
    my $args = getopts($args_pattern);
    $args->{h} and usage();
    !$args->{0} and usage();
    if ($args->{c}) {
        my $c = do $args->{c} or die "Can't open config file $args->{c} ($!)";
        $args->{c} = $c;
    }
    if ($args->{l}) {
        exists $args->{c}{$args->{l}} or die "No such label ($args->{l})";
    }
    (!$args->{c} and !$args->{p}) and usage();
    return $args;
}

sub usage {
    print <<EOS;
USAGE:

    memcached.pl [ OPTIONS ] start|stop|restart|stat

OPTIONS

    -p port.
    -u user.
    -l memcached label
    -c config file path

CONFIG SAMPLE

{
    # LABEL     => OPTIONS
    sample     => '-u root -m 64 -p 13111',
    sample2    => '-u root -m 64 -p 12111',
}

    memcached.pl -c sample.pdat -l sample start

    If you will start sample(memcached -u root -m 64 -p 13111)

    memcached.pl -c sample.pdat start

    Start all server(sample sample2)

EOS
    exit;
}

exit main;
