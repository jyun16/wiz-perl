#!/usr/bin/perl

use strict;

use Wiz::Test qw(no_plan);

use lib qw(../../lib ./lib);

chtestdir;

use Normal;
use Super;
use Child;
use Grandchild;
use Interface;
use ImplementsInterface;

use Wiz::Dumper;

sub main {
#    normal();
    extends();
#    implements_interface();
    return 0;
}

sub normal {
    my $normal;

    like_die_msg(sub {
        $normal = new Normal(member => 'MEMBER'); 
    }, q|^Normal->required_member is required value|);

    $normal = new Normal(
        member          => 'MEMBER',
        required_member => 'REQUIRED_MEMBER',
        setter_test     => 'SETTER',
        getter_test     => 'GETTER',
    ); 

    is $normal->member, 'MEMBER';
    $normal->member('HOGE');
    like_die_msg(sub {
        $normal->member_ro('MEMBER_RO');
    }, q|^Normal->member_ro is read only value|);
    $normal->hook_target(hoge => 'HOGE');

    is $normal->setter_test, q|[SET > SETTER]|;
    $normal->setter_test('SETTER2');
    is $normal->setter_test, q|[SET > SETTER2]|;
    is $normal->getter_test, q|[GET < GETTER]|;
}

sub extends {
#    my $child = new Child(member => 'MEMBER', required_member => 'REQUIRED_MEMBER');
#    my $child = new Child(required_member => 'REQUIRED_MEMBER');
#    warn $child->super_method;

    my $grand_child = new Grandchild(
    );

    warn $grand_child->member;



#    my $grand_child = new Grandchild(child_member => 'CHILD_MEMBER', required_member => 'REQUIRED_MEMBER');
#    warn Dumper $grand_child;
#    warn $grand_child->super_method; 
#    warn $grand_child->member;
#    warn $grand_child->child_method;
#    warn $grand_child->child_member;
}

sub implements_interface {
    my $ii = new ImplementsInterface(member1 => 'MEMBER1'); 
}

exit main;
