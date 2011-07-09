#!/usr/bin/perl

use strict;

use Wiz::Web::Framework::BatchBase;

use OpenSocialTmpl;

sub main {
    only_single_process("Can't execute $0 because other $0 process.");
    my $args = get_args;
    my $c = get_context(exclusive => [qw(controllers message tt autoform memcached)]);
    return 0;
}

sub usage {
    my ($opt, $desc) = qw(%-16s %-30s);
    print "$Wiz::Web::Framework::BatchBase::SCRIPT_NAME -t TYPE [ OPTIONS ]\n\n";
    printf " $opt $desc\n", '-e, --env', 'WIZ_APP_ENV(production or test, and any. The default is test)';
    printf " $opt $desc\n", '-h, --help', 'Usage';
}

exit main;
