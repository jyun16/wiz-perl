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
    my $c = get_context;
    my $member = $c->model('Member');
    my $member_data = $member->retrieve(userid => $args->{u});
    if ($member_data) {
        if ($args->{f}) {
            $member->set(password  => $args->{p});
            $args->{m} and $member->set(email  => $args->{m});
            $member->modify(id => $member_data->{id});
        }
        else {
            die "already exists user $args->{u}";
        }
    }
    else {
        $member->set(userid  => $args->{u});
        $member->set(password  => $args->{p});
        $member->set(email  => $args->{m});
        $member->create;
    }
    $member->commit;
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
    printf " $opt $desc\n", '-u, --userid';
    printf " $opt $desc\n", '-p, --password', 'password';
    printf " $opt $desc\n", '-m, --mail', 'email';
    printf " $opt $desc\n", '-f, --force', 'force update';
}

exit main;
