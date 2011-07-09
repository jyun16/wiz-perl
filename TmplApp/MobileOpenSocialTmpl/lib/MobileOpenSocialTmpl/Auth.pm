package MobileOpenSocialTmpl::Auth;

use strict;

use Wiz::Constant qw(:common);
use Wiz::Net::OAuth qw(check_oauth_signature_from_header);

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

sub mixi {
    my ($c, $user) = @_;
    my $p = $c->req->params;
    my $conf = $c->app_conf('mixi');
    return check_oauth_signature_from_header(
        $conf->{consumer_secret},
        $c->req->headers->{authorization},
        $c->req->method,
        $c->req->uri,
        $p,
    );
}

sub mbga {
    my ($c, $user) = @_;
    my $p = $c->req->params;
    my $conf = $c->app_conf('mbga');
    return check_oauth_signature_from_header(
        $conf->{consumer_secret},
        $c->req->headers->{authorization},
        $c->req->method,
        $c->req->uri,
        $p,
    );
}

1;
