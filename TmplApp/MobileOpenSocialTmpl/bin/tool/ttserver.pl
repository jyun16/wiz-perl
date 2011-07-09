#!/usr/bin/perl

use strict;

use POSIX;

use Wiz::Args::Simple qw(getopts);

my $TTSERVER = 'ttserver -dmn';
my $PKILL = '/usr/bin/pkill';

my $args = init_args(<<EOS);
c(conf):
p(port):
l(label):
-pid:
-data:
EOS

sub main {
    no strict 'refs';
    $args->{0}->();
    return 0;
}

sub _ope {
    my ($ope) = @_;
    no strict 'refs';
    if ($args->{c}) {
        if ($args->{l}) { $ope->("$TTSERVER $args->{c}{$args->{l}}"); }
        else { for (keys %{$args->{c}}) { $ope->("$TTSERVER $args->{c}{$_}"); } }
    }
    else { $ope->("$TTSERVER -port $args->{p} -pid $args->{pid} $args->{data}"); }
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
    my ($appended) = @_;
    getuid and die "Please execute by root user.";
    my $args = getopts(<<"EOS");
    h(help)
    $appended
EOS
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

    ttserver.pl [ OPTIONS ] start|stop|restart|stat

OPTIONS

    -p port.
    --pid PID File.
    --data Data file
    -l ttserver label
    -c config file path

CONFIG SAMPLE

{
    # LABEL     => OPTIONS
    sample     => '-port 13111 -pid /var/run/ttserver-default.pid /var/ttserver-default.tch',
    sample2    => '-port 15111 -pid /var/run/ttserver-default.pid /var/ttserver-default.tch',
}

    ttserver.pl -c sample.pdat -l sample start

    If you will start sample(ttserver -port 13111 -pid /var/run/ttserver-default.pid /var/ttserver-default.tch)

    memcached.pl -c sample.pdat start

    Start all server(sample sample2)

EOS
    exit;
}

exit main;

