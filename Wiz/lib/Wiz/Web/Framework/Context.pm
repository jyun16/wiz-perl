package Wiz::Web::Framework::Context;

=head1 NAME

Wiz::Web::Framework::Context

=head1 VERSION

version 1.0

=cut

use Carp;
use URI;
use I18N::LangTags;
use I18N::LangTags::Detect;
use Data::Dumper;

use Wiz::Noose;
use Wiz::Constant qw(:common);
use Wiz::DB qw(db_label2status);
use Wiz::DB::Constant qw(:status);
use Wiz::DB::DataIO;
use Wiz::Web::Framework::Session;
use Wiz::Util::File qw(fix_path);
use Wiz::Util::Hash qw(args2hash);

extends qw(
    Wiz::Web::Framework::ContextBase
);

our $VERSION = '1.0';

has 'controller' => (is => 'rw');
has 'req' => (is => 'rw');
has 'res' => (is => 'rw');
has 'stash' => (is => 'rw');

*request = 'req';
*response = 'res';
*appconf = 'app_conf';
*applog = 'app_log';

our %LOADED = ();
our %LOADED_MODEL = ();
our %LOADED_WORKER = ();

sub init {
    my $self = shift;
    my ($req, $res) = @_;
    $self->{req} = $req;
    $self->{res} = $res;
    $self->{stash} = {};
    $self->load_secure_token();
}

sub load_secure_token {
    my $self = shift;
    if ($self->conf->{use_secure_token} and !$LOADED{secure_token}) {
        my @funcs = @Wiz::Web::Framework::Context::SecureToken::PUBLIC_FUNCTIONS;
        no strict 'refs';
        for (@funcs) {
            *{$_} = "Wiz::Web::Framework::Context::SecureToken::$_";
        }
        $LOADED{secure_token} = 1;
    }
}

sub app_conf {
    my $self = shift;
    my ($target) = @_;
    $self->{app_conf}{$target};
}

sub app_log {
    my $self = shift;
    return $self->log->log(shift);
}

sub message {
    my $self = shift;
    my $m = $self->{message};
    $m->language($m->can_use_language($self->languages));
    return $m->get(@_);
}

sub validation_message {
    my $self = shift;
    my $m = $self->{message};
    $m->language($m->can_use_language($self->languages));
    return $m->validation(@_);
}

sub error_message {
    my $self = shift;
    my $m = $self->{message};
    $m->language($m->can_use_language($self->languages));
    return $m->error(@_);
}

sub system_error_message {
    my $self = shift;
    my $m = $self->{message};
    $m->language($m->can_use_language($self->languages));
    return $m->system_error(@_);
}

sub system_message {
    my $self = shift;
    my $m = $self->{message};
    $m->language($m->can_use_language($self->languages));
    return $m->system(@_);
}

sub common_message {
    my $self = shift;
    my $m = $self->{message};
    $m->language($m->can_use_language($self->languages));
    return $m->common(@_);
}

sub accept_language {
    my $self = shift;
    $self->req->header('Accept-Language');
}

sub languages {
    my $self = shift;
    my @languages = I18N::LangTags::implicate_supers(
        I18N::LangTags::Detect->http_accept_langs(
            $self->req->header('Accept-Language')
        )
    );
    return wantarray ? @languages : \@languages;
}

sub language {
    my $self = shift;
    my $lang = (I18N::LangTags::implicate_supers(
        I18N::LangTags::Detect->http_accept_langs(
            $self->req->header('Accept-Language')
        )
    ))[0];
    if ($lang =~ /(.*?)-.*/) { return $1; }
    else { return $lang; }
}

sub connection {
    my $self = shift;
    my ($status, $cluster_label) = @_;
    $status ||= MASTER;
    $status !~ /\d/ and $status = db_label2status($status);
    if ($status) { return $self->db->get_master($cluster_label); }
    elsif ($status == SLAVE) { return $self->db->get_slave($cluster_label); }
    else { confess qq|can't use the db type: $status|; }
}

sub master_connection {
    my $self = shift;
    my ($cluster_label) = @_;
    return $self->db->get_master($cluster_label);
}

sub slave_connection {
    my $self = shift;
    my ($cluster_label) = @_;
    return $self->db->get_slave($cluster_label);
}

sub model {
    shift->master_model(@_);
}

sub master_model {
    my $self = shift;
    my ($name, $arg) = @_;
    $self->_model($name, $arg, 'master');
}

sub slave_model {
    my $self = shift;
    my ($name, $arg) = @_;
    $self->_model($name, $arg, 'slave');
}

sub _model {
    my $self = shift;
    my ($name, $arg, $type) = @_;
    no strict 'refs';
    my $method = "${type}_connection";
    my $conn = undef;
    if (defined $arg) {
        my $r = ref $arg;
        if ($r eq 'Wiz::DB::Connection') { $conn = $arg; }
        else { $conn = $self->$method($arg); }
    }
    else { $conn = $self->$method; }
    defined $conn or confess qq|can't get connection($type)|;
    my $pkg = $self->app_name;
    $name = "${pkg}::Model::${name}";
    unless ($LOADED_MODEL{$name}) { eval "use $name"; $@ and die $@; $LOADED_MODEL{$name} = 1; }
    my $model = $name->new($conn);
    $self->db->is_controller and $model->cluster_controller($self->db);
    $model->{_c} = $self;
    return $model;
}

sub session {
    my $self = shift;
    $self->session_controller->session($self, @_);
}

sub session_id {
    my $self = shift;
    my $session_obj = $self->session_controller->_get_session_obj($self, @_);
    $session_obj ? $session_obj->_get_session_id : undef;
}

sub session_name {
    my $self = shift;
    my $session_obj = $self->session_controller->_get_session_obj($self, @_);
    $session_obj ? $session_obj->_session_name : undef;
}

sub change_session_id {
    my $self = shift;
    $self->session_controller->change_session_id($self, @_);
}

*_session = 'session';

sub login {
    my $self = shift;
    my ($userinfo, $label, $db_label, $opts);
    $opts ||= {};
    if (ref $_[0] eq 'HASH') { ($userinfo, $label, $db_label, $opts) = @_; }
    else { ($userinfo->{userid}, $userinfo->{password}, $label, $db_label, $opts) = @_; }
    $db_label ||= 'default';
    my $user = $self->auth->auth($label, $db_label)->execute($userinfo);
    if (defined $user) {
        my $session_label = $opts->{session_label};
        $self->session($session_label)->{$self->auth->session_key($label)} = $user;
        if ($opts->{session_secure}) {
            $self->session("${session_label}_secure")->{$self->auth->session_key($label)} = $user;
        }
    }
    return $user;
}

sub force_login {
    my $self = shift;
    my ($user_data, $label, $session_label) = @_;
    ref $user_data eq 'HASH' and $user_data = new Wiz::Auth::User($user_data);
    $label and $user_data->set_label($label);
    $self->session($session_label)->{$self->auth->session_key($label)} = $user_data;
    return $user_data;
}

sub logined {
    my $self = shift;
    my ($label, $session_label) = @_;
    $session_label ||= 'default';
    exists $self->session($session_label)->{$self->auth->session_key($label)};
}

sub logined_secure {
    my $self = shift;
    my ($label, $session_label) = @_;
    $session_label ||= 'default';
    exists $self->session("${session_label}_secure")->{$self->auth->session_key($label)};
}

*u = \&login_user;

sub login_user {
    my $self = shift;
    my ($label, $session_label) = @_;
    return $self->session($session_label)->{$self->auth->session_key($label)};
}

*refresh_login_user = \&reflesh_login_user;

sub reflesh_login_user {
    my $self = shift;
    my ($label, $db_label, $session_label) = @_;
    $db_label ||= 'default';
    my $u = $self->u;
    my $user = $self->auth->auth($label, $db_label)->force_get_user($u->{user});
    for (qw(login_mode)) { $user->{$_} = $u->{$_}; }
    defined $user and $self->session($session_label)->{$self->auth->session_key($label)} = $user;
    return $user;
}

sub logout {
    my $self = shift;
    my ($label, $session_label) = @_;
    my $s = $self->session($session_label);
    for (keys %$s) { delete $s->{$_}; }
    #delete $self->session($session_label)->{$self->auth->session_key($label)};
}

sub autoform {
    my $self = shift;
    my ($action, $params, $options) = @_;
    $params ||= $self->req->params;
    $options ||= {};
    $options->{language} ||= $self->language;
    return $self->{autoform}->autoform($action, $params, $options);
}

sub uri_for {
    my $self = shift;
    my ($path) = @_;
    my $ret = fix_path $self->req->action_package, $path;
    $ret =~ s/^\///;
    return $self->req->base . $ret;
}

sub path_to {
    my $self = shift;
    my ($path) = @_;
    return fix_path $self->app_root, $path;
}

sub redirect {
    my $self = shift;
    my ($uri, $param) = @_;
    $uri !~ m#://# and $uri = $self->uri_for($uri);
    my $u = new URI($uri);
    my %param = $u->query_form;
    if ($param) {
        for (keys %$param) { $param{$_} = $param->{$_}; }
        $param and $u->query_form(%param);
    }
    $self->res->redirect($u->as_string);
    goto END_OF_CONTROLLER;
}

*detach_redirect = 'redirect';

sub continue_redirect {
    my $self = shift;
    $self->redirect(@_);
}

sub _call_method {
    my $self = shift;
    my ($target, $args, $goto_end) = @_;
    no strict 'refs';
    my $ret;
    if ($target =~ /^\/|(?:\.\.)/) {
        my ($controller, $controller_info) =
            $self->get_controller($self, $target);
        if ($goto_end) {
            $self->_set_template2stash($self, $controller_info);
            $self->_modify_template_path_on_stash($self);
        }
        my $method =
            $controller_info->[$Wiz::Web::Framework::ContextBase::CONTROLLER_INFO_METHOD];
        $ret = $controller->$method($self, @$args);
    }
    else {
        $ret = $self->controller->$target($self, @$args);
    }
    if ($goto_end) {
        goto END_OF_CONTROLLER;
    }
    else { return $ret; }
}

sub forward {
    my $self = shift;
    my $target = shift;
    my $args = ref $_[0] eq 'ARRAY' ? $_[0] : [ @_ ];
    $self->_call_method($target, $args);
}

sub detach {
    my $self = shift;
    my $target = shift;
    my $args = ref $_[0] eq 'ARRAY' ? $_[0] : [ @_ ];
    $self->_call_method($target, $args, TRUE);
}

sub goto_error {
    my $self = shift;
    my $param = args2hash @_; 
    defined $param or $param = {}; 
    $self->detach('/error', [ %$param ]);
}

sub worker {
    my $self = shift;
    my ($name, $cluster_label) = @_;
    $self->_worker($name, $cluster_label, 'master');
}

sub slave_worker {
    my $self = shift;
    my ($name, $cluster_label) = @_;
    $self->_worker($name, $cluster_label, 'slave');
}

sub _worker {
    my $self = shift;
    my ($name, $cluster_label, $type) = @_;
    my $pkg = $self->app_name;
    $name = "${pkg}::Worker::${name}";
    unless ($LOADED_WORKER{$name}) { eval "use $name"; $@ and die $@; $LOADED_WORKER{$name} = 1; }
    my $connection_method = "${type}_connection";
    $name->new(dbc => $self->$connection_method);
}

sub d {
    my $c = shift;
    my ($pkg, $fn, $line) = caller;
    local $Data::Dumper::Terse = 1;
    local $Data::Dumper::Indent = 1;
    local $Data::Dumper::Sortkeys = 1;
    (my $dump = Dumper @_) =~ s/\r?\n$//;
    print STDERR "$dump -- $pkg($line)\n";
}

=head1 AUTHOR

Junichiro NAKAMURA, C<< <jyun16@gmail.com> >>

[Modify] Toshihiro MORIMOTO C<< dealforest.net@gmail.com >>

=head1 COPYRIGHT & LICENSE

Copyright 2010 The Wiz Project. All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice,
this list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright
notice, this list of conditions and the following disclaimer in the
documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE WIZ PROJECT ``AS IS'' AND ANY
EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED.  IN NO EVENT SHALL THE WIZ PROJECT OR CONTRIBUTORS BE
LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER
IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OROTHERWISE)
ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
THE POSSIBILITY OF SUCH DAMAGE.

The views and conclusions contained in the software and documentation are
those of the authors and should not be interpreted as representing official
policies, either expressed or implied, of the Wiz Project.

Additionally, the followings are recommended for the developers
to modify/improve/extend Wiz. Please send modified code/patch to mail list,
wiz-perl@googlegroups.com.
The source you sent will be merged into Wiz package.
We welcome anyone who cooperates with us in developing this software.

We'll invite you to this project's member.

=cut

1;

__END__


