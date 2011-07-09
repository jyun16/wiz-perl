#!/usr/bin/perl

use strict;

use Getopt::Std;

sub main {
    my $args = init_args("hc:");
    my $conf = parse_config($args->{c});
    if ($ARGV[0] =~ /^\d*$/ ) {
        my $c = $conf->{$ARGV[0]};
        exec "mysql -S $c->{socket}";
    }
    else {
        my $cmd = $ARGV[0];
        my $gnr = $ARGV[1];
        if ($cmd eq 'start' and !check_process($conf, $gnr, 1)) { return 1; }
        elsif ($cmd eq 'stop' and check_process($conf, $gnr)) { print "Already all mysqld is stopped.\n"; return 1; }
        print `$conf->{bin_dir}/mysqld_multi --defaults-file=$args->{c} --verbose $cmd $gnr`;
    }
    return 0;
}

sub check_process {
    my ($conf, $gnr, $warn) = @_;
    my $ret = 1;
    my @gnr = ();
    if ($gnr =~ /(\d*)-(\d*)/) { @gnr = $1 .. $2; }
    else { @gnr = split /,/, $gnr; }
    unless (@gnr) {
        for (keys %$conf) { /^\d*$/ and push @gnr, $_; }
    }
    for my $n (@gnr) {
        my $pid_file = $conf->{$n}{pid_file};
        if (my $pid = exists_process($pid_file)) {
            $warn and print "Exists mysqld process $pid (mysqld$n: $pid_file)\n";
            $ret = 0;
        }
    }
    return $ret;
}

sub exists_process {
    my ($pid_file) = @_;
    -f $pid_file or return 0;
    open my $f, "<$pid_file" or die "$pid_file($!)";
    while (<$f>) {
        chomp;
        my $ps_res =  `ps -p $_`;
        $ps_res =~ /mysqld/ and return $_;
    }
    close $f;
    return 0;
}

sub parse_config {
    my ($conf_path) = @_;
    my $conf = {};
    my $tmp = {};
    open my $f, "<$conf_path" or die "$conf_path($!)";
    while (<$f>) {
        if (/^\[mysqld(.*)\]/) {
            ($1 eq '' or $1 eq '_multi') and next;
            $conf->{$1} = {};
            $tmp = $conf->{$1};
        }
        elsif (/socket\s*=\s*(.*)/) {
            $tmp->{socket} = $1;
        }
        elsif (/pid-file\s*=\s*(.*)/) {
            $tmp->{pid_file} = $1;
        }
        elsif (/mysqld\s*=\s*(.*)/) {
            $1 =~ /(.*)\/mysqld_safe/;
            $conf->{bin_dir} = $1;
        }
    }
    close $f;
    return $conf;
}

sub init_args {
    my ($opt) = @_;
    my $args = {};
    getopt($opt, $args);
    $args->{h} and usage();
    $args->{c} or usage();
    @ARGV or usage();
    return $args;
}

sub usage {
    print "mysql_multi -c mysqld_multi.cnf [MYSQL_SERVER_NUMBER]\n";    
    print "mysql_multi -c mysqld_multi.cnf {start|stop} [MYSQL_SERVER_NUMBER]\n";    
    print "MYSQL_SERVER_NUMBER: 1,2,3,4 or 1-4\n";    
    exit 0;
}

exit main;
