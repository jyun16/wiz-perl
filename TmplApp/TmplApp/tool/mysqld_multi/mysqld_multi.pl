#!/usr/bin/perl

use strict;

use Wiz::Dumper;
use Wiz::Args::Simple qw(getopts);

sub main {
    my $args = init_args('hc:pf:u:d:');
    my $conf = parse_config($args->{c});
    if ($args->{0} =~ /^\d*$/ ) {
        my $c = $conf->{$args->{0}};
        unless ($args->{u}) {
            my $user = `whoami`;
            chomp $user ;
            $args->{u} = $user;
        }
        my $cmd = "mysql -u $args->{u}";
        if (-r $c->{socket}) {
            $cmd .= " -S $c->{socket}";
        }
        else {
            if ($args->{p}) {
                $cmd .= " -p $args->{p}";
            }
            if ($c->{port}) {
                $cmd .= " --port $c->{port}";
            }
            if ($c->{bind_address}) {
                $cmd .= " --host $c->{bind_address}";
            }
        }
        $args->{d} and $cmd .= " $args->{d}";
        $args->{f} and $cmd .= " < $args->{f}";
        exec $cmd;
    }
    else {
        my $cmd = $args->{0};
        my $gnr = $args->{1};
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
        elsif (/socket\s*=\s*(.*)/) { $tmp->{socket} = $1; }
        elsif (/bind-address\s*=\s*(.*)/) { $tmp->{bind_address} = $1; }
        elsif (/port\s*=\s*(.*)/) { $tmp->{port} = $1; }
        elsif (/pid-file\s*=\s*(.*)/) { $tmp->{pid_file} = $1; }
        elsif (/mysqld\s*=\s*(.*)/) {
            $1 =~ /(.*)\/mysqld_safe/;
            $conf->{bin_dir} = $1;
        }
    }
    close $f;
    return $conf;
}

sub init_args {
    my ($args_pattern) = @_;
    my $args = getopts($args_pattern);
    $args->{h} and usage();
    $args->{c} or usage();
    !$args->{0} and usage();
    if ($args->{c}) {
        -r $args->{c} or die "Can't open config file $args->{c} ($!)";
    }
    if ($args->{p}) {
        $args->{p} = prompt("Password: ", -te => '*'); 
    }
    return $args;
}

sub usage {
    print <<EOS;
    mysql_multi -c mysqld_multi.cnf [OPTIONS] [MYSQL_SERVER_NUMBER]
    mysql_multi -c mysqld_multi.cnf [OPTIONS] {start|stop} [MYSQL_SERVER_NUMBER]
    MYSQL_SERVER_NUMBER: 1,2,3,4 or 1-4

    OPTIONS

        u: Database user
        p: Database user password
        d: Database
        f: SQL query file
    
EOS
    exit 0;
}

exit main;
