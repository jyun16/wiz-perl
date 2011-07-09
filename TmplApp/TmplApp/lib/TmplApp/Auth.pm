package TmplApp::Auth;

use strict;

use Wiz::Constant qw(:common);

sub member {
    my ($c, $user) = @_;
    $c->logined('member') ? SUCCESS : FAIL;
}

sub member_secure {
    my ($c, $user) = @_;
    $c->logined_secure('member') ? SUCCESS : FAIL;
}

sub admin {
    my ($c, $user) = @_;
    if ($c->req->path eq '/admin/login') { return SUCCESS; }
    else { $c->logined('admin', 'admin') ? SUCCESS : FAIL; }
}

sub admin_secure {
    my ($c, $user) = @_;
    $c->logined_secure('admin', 'admin') ? SUCCESS : FAIL;
}

1;
