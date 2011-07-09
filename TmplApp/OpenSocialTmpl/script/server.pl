#!/usr/bin/perl

use strict;

use FindBin;
use lib ("$FindBin::Bin/../lib");

use OpenSocialTmpl;

use Wiz::Args::Simple qw(getopts);
use Wiz::Util::File qw(filename dirname);

my $args = init_args(<<EOS);
-p(port):
-i(ip):
-d(debug)
-r(reload)
-h(help)
EOS

(my $app_root = $FindBin::Bin) =~ s/\/script$//;
my $ignore_pattern = 'scripts?$|trunk$|branches$|branch$|tags?$|\d+$';
my $app_name = get_app_name($app_root);

sub main {
    my $log_level = $args->{debug} ? 'debug' : 'info';
    my $httpd = new OpenSocialTmpl(
        host => $args->{i},
        port => $args->{p},
        max_request_size => 10_000_000,
        log_conf => {
            level   => $log_level,
            stderr  => 1,
            simple  => 1,
        },
        app_root    => $app_root,
        app_name    => $app_name,
    );
    $args->{r} and $httpd->module_reload(0.1);
    $httpd->listen;
}

sub get_app_name {
    my $app_root = shift;
    my $name = filename $app_root;
    $name =~ /$ignore_pattern/ and return get_app_name(dirname $app_root);
    return $name;
}

sub init_args {
    my $args_pattern = shift;
    $args_pattern .= 'hv';
    my $args = getopts($args_pattern);
    $args->{h} and do { usage(); exit 0; };
    $args->{p} ||= 3000;
    return $args;
}

sub version {
    print <<EOS;
Version: 

Author: Junichiro NAKAMURA
EOS

}

sub usage {
    my ($opt, $desc) = qw(%-16s %-30s);
    print "$FindBin::Script -u USERID [ OPTIONS ]\n\n";
    printf " $opt $desc\n", '-p, --port', 'Listening port';
    printf " $opt $desc\n", '-i, --ip', 'Binding IP address';
    printf " $opt $desc\n", '-r, --reload', 'Reload module';
    printf " $opt $desc\n", '-d, --debug', 'Debug mode';
}

exit main;
