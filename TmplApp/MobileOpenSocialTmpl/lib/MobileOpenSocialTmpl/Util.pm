package MobileOpenSocialTmpl::Util;

use strict;

use URI;

use Wiz::Web::Util qw(uri_escape);
use Wiz::ConstantExporter [qw(
    redirect4mbga
    redirect4mixi
)];

sub redirect4mbga {
    my ($c, $uri, $param) = @_;
    my $uri_base = $c->app_conf('mbga')->{uri_base};
    $uri !~ m#://# and $uri = $c->uri_for($uri);
    my $u = new URI($uri);
    $param and $u->query_form($param);
    my $stash = $c->stash;
    $c->redirect("$uri_base/$stash->{opensocial_app_id}/?url=" . uri_escape($u->as_string));
}

sub redirect4mixi {
    my ($c, $uri, $param) = @_;
    my $uri_base = $c->app_conf('mixi')->{uri_base};
    $uri !~ m#://# and $uri = $c->uri_for($uri);
    my $u = new URI($uri);
    $param and $u->query_form($param);
    my $stash = $c->stash;
    $c->redirect("$uri_base/$stash->{opensocial_app_id}/?url=" . uri_escape($u->as_string));
}

1;
