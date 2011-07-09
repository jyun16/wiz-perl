package TmplApp::Controller::Root;

use Wiz::Noose;
use Wiz::Constant qw(:common);

extends qw(
    Wiz::Web::Framework::Controller::Root
    Wiz::Web::Framework::Controller::Login
);

our @AUTOFORM = qw(login);
our $AUTHZ_LABEL = 'member';
our $SESSION_NAME = __PACKAGE__;
our $LOGIN_SUCCESS_DEST = '/all_form/list/index';
our $LOGOUT_DEST = '/login';
our $AUTH_FAIL_DEST = '/login';
#our $CHANGE_SESSION_ID = TRUE;
#our $SESSION_SECURE = TRUE;
#our $SESSION_LABEL = 'default';

sub index {
    my $self = shift;
    my ($c) = @_;
    $c->logined ?
        $c->redirect($LOGIN_SUCCESS_DEST) :
        $c->redirect($AUTH_FAIL_DEST);
}

sub test {
    my $self = shift;
    my ($c) = @_;
    warn '>> ' . $c->req->client_host;
    $c->res->content('body');
}

sub args {
    my $self = shift;
    my ($c) = @_;
    use Data::Dumper;
    $c->res->content(Dumper $c->req->args);
}

sub list {
    my $self = shift;
    my ($c) = @_;
    my $base = $c->req->base;
    my $uri = $c->req->uri;
    my $path = $c->req->path;
    my $params = Dumper $c->req->params;

#    my $m = $c->model('Member');
#    my $hs = $m->handler_socket('PRIMARY', 'userid,email') or die $m->handler_socket_error;
#    wd $hs->execute('=', 1);

    $c->res->content(<<"EOS");
<a href='${base}test.html'>test.html - static and multipart form</a><br />
<a href='${base}dump'>dump</a><br />
<a href='${base}form'>form</a><br />
<a href='${base}upload_form'>upload_form</a><br />
<a href='${base}download'>download</a><br />
<a href='${base}set_cookie'>set_cookie</a><br />
<a href='${base}dump_cookie'>dump_cookie</a><br />
<a href='${base}set_session'>set_session</a><br />
<a href='${base}dump_session'>dump_session</a><br />
<a href='${base}dump_session_and_change_sid'>dump_session_and_change_sid</a><br />
<a href='${base}tt'>tt</a><br />
<a href='${base}member/list/'>member</a><br />
<a href='${base}all_form/list/'>all_form</a><br />
URI: $uri<br />
PATH: $path<br />
PARAMS: $params<br />
EOS
}

sub dump {
    my $self = shift;
    my ($c) = @_;
    my ($req, $res) = ($c->req, $c->res);
    my $body;
    $body .= 'HOST: ' . $req->host . '<br />';
    $body .= 'USER_AGENT: ' . $req->user_agent . '<br />';
    $body .= 'SCHEME: ' . $req->scheme . '<br />';
    $body .= 'BASE: ' . $req->base . '<br />';
    $body .= 'URI: ' . $req->uri . '<br />';
    $body .= 'PATH: ' . $req->path . '<br />';
    $body .= 'METHOD: ' . $req->method . '<br />';
    $body .= 'HEADERS: ' . (Dumper $req->headers) . '<br />';
    $body .= 'CONTENT: ' . $req->content . '<br />';
    $body .= 'PARAMS: ' . (Dumper $req->params) . '<br />';
    $body .= 'CLIENT_HOST: ' . $req->client_host . '<br />';
    $body .= 'CLIENT_PORT: ' . $req->client_port . '<br />';
    $res->content($body);
}

sub form {
    my $self = shift;
    my ($c) = @_;
    my ($req, $res) = ($c->req, $c->res);
    $res->content(<<"EOS");
<form action='/act' method='post'>
    <input type='text' name='keywords' />
    <input type='text' name='keywords2' />
    <input type='submit' value='go' />
</form>
EOS
}

sub act {
    my $self = shift;
    my ($c) = @_;
    my ($req, $res) = ($c->req, $c->res);
    $res->content('<pre>' . (Dumper $req->params) . '</pre>');
}

sub set_cookie {
    my $self = shift;
    my ($c) = @_;
    my ($req, $res) = ($c->req, $c->res);
    $res->cookies->{new_cookie} = {
#        domain  => '',
#        path    => '',
        value   => 'NEW COOKIE DATA: ' . time,
        expires => time + 1_000_000,
    };

    $res->content(<<"EOS");
SET COOKIE
EOS
}

sub dump_cookie {
    my $self = shift;
    my ($c) = @_;
    my ($req, $res) = ($c->req, $c->res);
    $res->content('<pre>' . (Dumper $req->cookies) . '</pre>');
}

sub download {
    my $self = shift;
    my ($c) = @_;
    my ($req, $res) = ($c->req, $c->res);
    $res->content_type('text/csv');
    $res->filename('test.csv');
    $res->content('hoge,fuga,foo,bar');
}

sub upload_form {
    my $self = shift;
    my ($c) = @_;
    my ($req, $res) = ($c->req, $c->res);
    $res->content(<<EOS);
<form action='/upload' method='POST' enctype='multipart/form-data'>
    <input type='text' name='text_data' />
    <input type='file' name='file_data' />
    <input type='submit' value='go' />
</form>
EOS
}

sub upload {
    my $self = shift;
    my ($c) = @_;
    my ($req, $res) = ($c->req, $c->res);
    my $u = $req->upload('file_data');
    warn 'SIZE: ' . $u->size;
    warn 'TYPE: ' . $u->type;
    warn 'FILENAME: ' . $u->filename();
    $u->copy_to('/tmp/x_hoge', 1);
    $u->link_to('/tmp/x_hoge_link');
    my $fh = $u->fh;
    while (<$fh>) { warn $_; }
    $res->content('<pre>' . (Dumper $req->params) . '</pre>');
}

sub set_session {
    my $self = shift;
    my ($c) = @_;
    my ($req, $res) = ($c->req, $c->res);
    my $session = $c->session;
#    my $session = $c->session('db_session');
#    my $session = $c->session('memcached_session');
    $session->{hoge} = 'HOGE';
    $session->{time} = time;
    $res->content(<<"EOS");
SET SESSION
EOS
}

sub dump_session {
    my $self = shift;
    my ($c) = @_;
    my ($req, $res) = ($c->req, $c->res);
    my $session = $c->session;
#    my $session = $c->session('db_session');
#    my $session = $c->session('memcached_session');
    $res->content('<pre>' . (Dumper $session) . '</pre>');
}

sub dump_session_and_change_sid {
    my $self = shift;
    my ($c) = @_;
    my ($req, $res) = ($c->req, $c->res);
    $c->change_session_id;
    my $session = $c->session;
    $res->content('<pre>' . (Dumper $session) . '</pre>');
}

sub tt {
    my $self = shift;
    my ($c) = @_;
    my ($req, $res) = ($c->req, $c->res);
    $c->stash->{hoge} = 'HOGE';
    my $member = $c->model('Member');
    my $token = $c->model('Token');

    my $session = $c->session;

    $session->{hoge} = 'HOGE';
    $session->{fuga} = 'FUGA';

#    warn Dumper $member->getone(userid => 'test');
#    $c->redirect('http://www.google.com/index?hoge=HOGE');
}

1;
