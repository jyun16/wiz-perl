package OpenSocialTmpl::Auth;

use strict;

use Wiz::Constant qw(:common);

sub member {
    my ($c, $user) = @_;
    $c->logined('member') ? SUCCESS : FAIL;
    return FAIL;
}

sub member_secure {
    my ($c, $user) = @_;
    $c->logined_secure('member') ? SUCCESS : FAIL;
}

sub admin {
    my ($c, $user) = @_;
    $c->logined('admin') ? SUCCESS : FAIL;
}

sub admin_secure {
    my ($c, $user) = @_;
    $c->logined_secure('admin') ? SUCCESS : FAIL;
}

1;
