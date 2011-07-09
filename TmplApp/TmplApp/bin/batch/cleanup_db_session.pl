#!/usr/bin/perl

use strict;

use MIME::Base64;
use Storable qw(thaw);

use Wiz::Dumper;
use Wiz::Web::Framework::BatchBase;
use Wiz::DateTime;

my $args = get_args(<<EOS);
p(port):
-host:
EOS
my $c = get_context(exclusive => [qw(controllers log message session_controller auth tt autoform memcached)]);
my $session = $c->model($args->{m});

sub main {
    my $rs = $session->select(expires => ['<', time]);
    while ($rs->next) {
        my $data = $rs->data;
        $session->delete(id => $data->{id});
    }
    $session->commit;
    return 0;
}

sub get_args {
    my ($appended) = @_;
    use Wiz::Args::Simple qw(getopts);
    my $args = getopts(<<"EOS");
e(env):
$appended
EOS
    $args->{m} ||= 'Session';
    $ENV{WIZ_APP_ENV} = $args->{env};
    return $args;
}

sub usage {
    my ($opt, $desc) = qw(%-16s %-30s);
    print "$Wiz::Web::Framework::BatchBase::SCRIPT_NAME -m MODEL [ OPTIONS ]\n\n";
    printf " $opt $desc\n", '-m, --model', 'default: Session';
    printf " $opt $desc\n", '-h, --help', 'Usage';
}

exit main;
