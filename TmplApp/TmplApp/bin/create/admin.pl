#!/usr/bin/perl

use strict;

use IO::Prompt;

use Wiz::Web::Framework::BatchBase;

sub main {
    my $args = init_args(<<"EOS");
u(user):
m(mail):
f(force)
p(password);
EOS
    my $c = get_context(exclusive => [qw(controllers log message session_controller auth tt autoform memcached)]);
    my $admin = $c->model('Admin');
    my $admin_data = $admin->retrieve(userid => $args->{u});
    if ($admin_data) {
        if ($args->{f}) {
            $admin->set(password  => $args->{p});
            $args->{m} and $admin->set(email  => $args->{m});
            $admin->modify(id => $admin_data->{id});
        }
        else {
            die "already exists user $args->{u}";
        }
    }
    else {
        $admin->set(userid  => $args->{u});
        $admin->set(password  => $args->{p});
        $admin->set(email  => $args->{m});
        $admin->create;
    }
    $admin->commit;
    return 0;
}

sub init_args {
    my $args = get_args(@_);
    $args->{u} or do { usage(); exit 1; };
    unless ($args->{p}) { $args->{p} = prompt('password: ', -te => '*'); }
    return $args;
}

sub usage {
    my ($opt, $desc) = qw(%-16s %-30s);
    print "$Wiz::Web::Framework::BatchBase::SCRIPT_NAME -u USERID [ OPTIONS ]\n\n";
    printf " $opt $desc\n", '-u, --userid', 'userid';
    printf " $opt $desc\n", '-p, --password', 'password';
    printf " $opt $desc\n", '-m, --mail', 'email';
    printf " $opt $desc\n", '-f, --force', 'force update';
}

exit main;
