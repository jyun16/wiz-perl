#!/usr/bin/perl

use strict;

use MIME::Base64;
use Storable qw(thaw);

use Wiz::Dumper;
use Wiz::Web::Framework::BatchBase;
use Wiz::DateTime;

my $args = init_args(get_args(<<EOS));
m(model):
EOS
my $c = get_context(exclusive => [qw(controllers log message session_controller auth tt autoform memcached)]);
my $session = $c->model($args->{m});

sub main {
    if ($args->{0} eq 'list') { list(); }
    elsif ($args->{0} eq 'get') { get(); }
    elsif ($args->{0} eq 'dump') { dump_all(); }
    elsif ($args->{0} eq 'remove') { remove(); }
    elsif ($args->{0} eq 'remove_all') { remove_all(); }
    $session->commit;
    return 0;
}

sub list {
    my $rs = $session->select;
    while ($rs->next) {
        print $rs->get('id') . "\n"; 
    }
}

sub get {
    print_session(thaw_data($session->retrieve(id => $args->{1})));
}

sub dump_all {
    my $rs = $session->select;
    while ($rs->next) {
        print_session(thaw_data($rs->data));
    }
}

sub remove {
    print_success_or_fail($session->delete(id => $args->{1}));
}

sub remove_all {
    my $rs = $session->select;
    while ($rs->next) {
        my $id = $rs->get('id');
        print "$id";
        print_success_or_fail($session->delete(id => $id));
    }
}

sub thaw_data {
    my ($data) = @_;
    $data->{session_data} = thaw decode_base64 $data->{session_data};
    return $data;
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
    $args->{m} ||= 'Session';
    $ENV{WIZ_APP_ENV} = $args->{env};
    return $args;
}

sub usage {
    my ($opt, $desc) = qw(%-16s %-30s);
    print "$Wiz::Web::Framework::BatchBase::SCRIPT_NAME -p PORT [ OPTIONS ] {list|get|dump|remove KEY|remove_all}\n\n";
    printf " $opt $desc\n", '-m, --model', 'default: Session';
    printf " $opt $desc\n", '-h, --help', 'Usage';
}

exit main;
