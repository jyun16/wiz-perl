#!/usr/bin/perl

use strict;

use Wiz::Web::Framework::BatchBase;
use Mobile::Wiz::Web::Framework::CIDR;

sub main {
    only_single_process("Can't execute $0 because other $0 process.");
    my $args = get_args;
    my $c = get_context;
    my $conf = $c->app_conf('cidr');
    my $cidr = new Mobile::Wiz::Web::Framework::CIDR(%$conf);
    $cidr->update_memcached;
    test($cidr);
    return 0;
}

sub get_cache_server {
    my ($conf) = @_; 
    return Cache::Memcached::Fast->new($conf->{memcached});
}

sub test {
    my ($cidr) = @_;
    my $mobile_ip = '121.111.227.160';
    my $pc_ip = '210.111.111.111';
    warn $cidr->get_carrier($mobile_ip);
    warn $cidr->is_mobile($mobile_ip);
    warn $cidr->is_non_mobile($mobile_ip);
    warn $cidr->get_carrier($pc_ip);
    warn $cidr->is_mobile($pc_ip);
    warn $cidr->is_non_mobile($pc_ip);
}

sub usage {
    my ($opt, $desc) = qw(%-16s %-30s);
    print "$Wiz::Web::Framework::BatchBase::SCRIPT_NAME -t TYPE [ OPTIONS ]\n\n";
    printf " $opt $desc\n", '-e, --env', 'WIZ_APP_ENV(production or test, and any. The default is test)';
    printf " $opt $desc\n", '-h, --help', 'Usage';
}

exit main;
