#!/usr/bin/perl

use strict;

use TokyoTyrant;
use MIME::Base64;
use Storable qw(thaw);

use Wiz::Dumper;
use Wiz::Web::Framework::BatchBase;
use Wiz::DateTime;

my $args = init_args(get_args(<<EOS));
p(port):
-host:
EOS
my $rdb = get_rdb($args);

sub main {
    if ($args->{0} eq 'list') { list(); }
    elsif ($args->{0} eq 'get') { get(); }
    elsif ($args->{0} eq 'dump') { dump_all(); }
    elsif ($args->{0} eq 'remove') { remove(); }
    elsif ($args->{0} eq 'remove_all') { remove_all(); }
    return 0;
}

sub list {
    $rdb->iterinit;
    my @keys = ();
    while (my $key = $rdb->iternext) {
        print "$key\n";
    }
}

sub get {
    print_session(get_value($args->{1}));
}

sub dump_all {
    $rdb->iterinit;
    my @keys = ();
    while (my $key = $rdb->iternext) {
        print_session(get_value($key));
    }
}

sub remove {
    print_success_or_fail($rdb->out($args->{1}));
}

sub remove_all {
    $rdb->iterinit;
    my @keys = ();
    while (my $key = $rdb->iternext) {
        print "$key";
        print_success_or_fail($rdb->out($key));
    }
}

sub get_value {
    my ($key) = @_;
    my $data = $rdb->get($key);
    if ($data) {
        return thaw decode_base64 $data;
    }
}

sub get_keys {
    $rdb->iterinit;
    my @keys = ();
    while (my $key = $rdb->iternext) { push @keys, $key; }
    wantarray ? @keys : \@keys;
}

sub get_rdb {
    my $rdb = new TokyoTyrant::RDB;
    $rdb->open($args->{host}, $args->{port}) or die $rdb->errmsg($rdb->ecode);
    return $rdb;
}

sub print_session {
    my ($data) = @_;
    $data or return;
    my $expire = new Wiz::DateTime;
    $expire->set_epoch($data->{expires});
    print "Expire: $expire\n";
    wd $data;
}

sub print_success_or_fail {
    print (shift() ? "[SUCCESS]\n" : "[FAIL]\n");
}

sub init_args {
    my ($args) = @_;
    $args->{host} ||= 'localhost';
    $ENV{WIZ_APP_ENV} = $args->{env};
    return $args;
}

sub usage {
    my ($opt, $desc) = qw(%-16s %-30s);
    print "$Wiz::Web::Framework::BatchBase::SCRIPT_NAME -p PORT [ OPTIONS ] {list|get|dump|remove KEY|remove_all}\n\n";
    printf " $opt $desc\n", '-p, --port', '';
    printf " $opt $desc\n", '--host', 'Default is localhost';
    printf " $opt $desc\n", '-h, --help', 'Usage';
}

exit main;
