package Wiz::Web::Framework::ContextBase;

=head1 NAME

Wiz::Web::Framework::ContextBase

=head1 VERSION

version 1.0

=cut

use Carp;
use Module::Pluggable::Object;
use Template;
use Devel::Symdump;
# This module put stupid warning message 'HOME is not set' in the File::BaseDir.
use File::MimeInfo;
use Cache::Memcached::Fast;

use Wiz::Noose;
use Wiz::Constant qw(:common);
use Wiz::Config qw(load_config_files);
use Wiz::Util::String qw(pascal2normal);
use Wiz::Util::File qw(dirname filename fix_path);
use Wiz::Util::Hash qw(override_hash);
use Wiz::Log::Controller;
use Wiz::Message;
use Wiz::DB::Cluster;
use Wiz::DB::Cluster::Controller;
use Wiz::Auth::Controller;
use Wiz::Web::AutoForm::Controller;
use Wiz::Validator::Constant qw(:error);
use Wiz::Web::Filter qw(:all);
use Wiz::Web::Framework::Session::Controller;

our $VERSION = '1.0';

has 'app_base' => (is => 'rw');
has 'app_name' => (is => 'rw');
has 'app_root' => (is => 'rw');
has 'controllers' => (is => 'rw');
has 'conf' => (is => 'rw');
has 'app_conf' => (is => 'rw');
has 'log' => (is => 'rw');
has 'message' => (is => 'rw');
has 'db' => (is => 'rw');
has 'session_controller' => (is => 'rw');
has 'auth' => (is => 'rw');
has 'tt' => (is => 'rw');
has 'autoform' => (is => 'rw');
has 'exclusive' => (is => 'rw');
has 'const' => (is => 'rw');

*appconf = 'app_conf';
*config = 'conf';

our $CONTROLLER_INFO_PACKAGE = 0;
our $CONTROLLER_INFO_METHOD = 1;
our $CONTROLLER_INFO_ACTION = 2;
our %CONTROLLERS = ();

sub BUILDARGS {
    my ($class, %value) = @_;
    $value{conf} ||= {};
    if (ref $value{exclusive} eq 'ARRAY') {
        $value{exclusive} = { map {
            $_ => 1
        } @{$value{exclusive}} };
    }
    return \%value;
}

sub BUILD {
    my $self = shift;
    my ($args) = @_;
    $self->init;
}

sub init {
    my $self = shift;
    for (qw(app_conf const controllers log message db session_controller auth tt autoform memcached)) {
        my $m = "init_$_";
        $self->{exclusive}{$_} or $self->$m;
    }
    $self->conf->{use_secure_token} and $self->init_secure_token;
}

sub init_app_conf {
    my $self = shift;
    my $app_conf = {};
    for(@{_app_conf_files($self->app_root . '/conf')}) {
        (filename $_) =~ /([^\.]*)\..*$/;
        my $data = { $1 => load_config_files($_) };
        defined $data->{$1} and override_hash($app_conf, $data);
    }
    $self->app_conf($app_conf);
    return $app_conf;
}

sub _app_conf_files {
    my ($dir) = @_;
    $dir !~ /\/$/ and $dir .= '/';
    my @files = ();
    _app_conf_files_list($dir, \@files);
    _app_conf_files_list($dir . 'common', \@files);
    _app_conf_files_list($dir . ($ENV{WIZ_APP_ENV} || $ENV{CATALYST_APP_ENV} || 'test'), \@files);
    return \@files;
}

sub _app_conf_files_list {
    my ($path, $files) = @_;
    opendir my $dir, $path or confess "can't open $path ($!)";
    for my $f (grep !/^\.\.?$/, readdir($dir)) {
        -d "$path/$f" and next;
        $f =~ /\.(ya?ml|pdat)$/ and push @$files, "$path/$f";
    }
    closedir $dir;
}

sub init_controllers {
    my $self = shift;
    my $app_pkg = $self->app_name . '::Controller';
    no strict 'refs';
    my %controllers = ();
    for my $pkg (Module::Pluggable::Object->new(search_path => [$app_pkg])->plugins) {
        # suck catalyst
        *{"${pkg}::MODIFY_CODE_ATTRIBUTES"} = sub {};
        eval "use $pkg;";
        if ($@) {
            warn "failed to compile a controller -> $pkg";
             die warn $@;
        }
        (my $path = $pkg) =~ s/^${app_pkg}:://;
        $path eq 'Root' and $path = '';
        my $p;
        for my $n (split /::/, $path) { $p .= pascal2normal($n) . '/'; }
        $controllers{"/$p"} = $pkg;
    }
    $self->controllers(\%controllers);
}

sub init_log {
    my $self = shift;
    my $conf = $self->app_conf->{log};
    $conf or return;
    if ($conf->{base_dir}) {
        $conf->{base_dir} !~ /^\// and
            $conf->{base_dir} = fix_path $self->app_root, $conf->{base_dir};
    }
    else { $conf->{base_dir} = $self->app_root; }
    $self->log(new Wiz::Log::Controller($conf)); 
}

sub init_message {
    my $self = shift;
    my $conf = $self->app_conf->{message};
    $conf or return;
    if ($conf->{base_dir}) {
        $conf->{base_dir} !~ /^\// and
            $conf->{base_dir} = fix_path $self->app_root, $conf->{base_dir};
    }
    else { $conf->{base_dir} = $self->app_root . '/message'; }
    $self->message(new Wiz::Message($conf));
}

sub init_db {
    my $self = shift;
    my $conf = $self->app_conf->{db};
    $conf or return;
    if ($conf->{base_dir}) {
        $conf->{base_dir} !~ /^\// and
            $conf->{base_dir} = fix_path $self->app_root, $conf->{base_dir};
    }
    else { $conf->{base_dir} = $self->app_root; }
    $self->db(exists $conf->{clusters} ?
        new Wiz::DB::Cluster::Controller($conf) : new Wiz::DB::Cluster($conf));
}

sub init_session_controller {
    my $self = shift;
    $self->{session_controller} =
        new Wiz::Web::Framework::Session::Controller(conf => $self->app_conf->{session});
}

sub init_auth {
    my $self = shift;
    my $conf = $self->app_conf->{auth};
    $conf or return;
    my $auth_pkg = $self->app_name . '::Auth';
    eval "use $auth_pkg;";
    $@ and warn $@;
    $conf->{cluster} = $self->db;
    $conf->{authz}{session_key_prefix} = $self->app_name;
    $self->auth(new Wiz::Auth::Controller($conf));
}

sub init_tt {
    my $self = shift;
    my %filters = ();
    for (Devel::Symdump->functions('Wiz::Web::Filter')) {
        my @p = split /::/;
        my $f = pop @p;
        my $fn = $f;
        if ($f eq 'auto_link') { $fn = 'autolink'; }
        $filters{$fn} = [ sub {
            shift;
            my @args = @_;
            if ($f eq 'datetime') {
                @args = { format => $args[0] };
            }
            return sub {
                no strict 'refs';
                "$f"->(shift, @args);
            }
        }, 1 ];
    }
    my $tt_conf = {
        INCLUDE_PATH => [
            $self->app_root . '/tmpl'
        ],
        COMPILE_DIR         => $self->app_root . '/tmpl/.cache',
        COMPILE_EXT         => '.ttc',
        RECURSION           => 1,
        TRIM                => 1,
        ABSOLUTE            => 1,
        PRE_PROCESS         => $self->_tt_pre_process,
        FILTERS             => \%filters,
    };
    if ($self->conf->{TT}) { override_hash($tt_conf, $self->conf->{TT}); }
    $self->tt(new Template($tt_conf));
}

sub _tt_pre_process {
    my $self = shift;
    return $self->app_root . '/tmpl/include/macro.tt';
}

sub init_autoform {
    my $self = shift;
    if ($self->{conf}{use_pds4autoform}) {
        $self->autoform(
            new Wiz::Web::AutoForm::Controller(
                "$self->{app_root}/autoform",
                $self->{message},
                {
                    pds_pkg => "$self->{app_name}::PDS",
                },
            )
        );
    }
    else {
        $self->autoform(
            new Wiz::Web::AutoForm::Controller("$self->{app_root}/autoform", $self->{message})
        );
    }
}

sub init_secure_token {
    my $self = shift;
    use Wiz::Web::Framework::Context::SecureToken;
    use Devel::Symdump;
    Wiz::Web::Framework::Context::SecureToken::init_conf($self->{app_conf}{secure_token} ||= {});
}

sub init_memcached {
    my $self = shift;
    my $conf = $self->app_conf->{memcached};
    $conf or return;
    my $memcached = {};
    for (keys %$conf) {
        $memcached->{$_} = new Cache::Memcached::Fast($conf->{$_});
    }
    $self->{memcached} = $memcached;
}

sub memcached {
    my $self = shift;
    $self->{memcached}{shift()}; 
}

sub init_const {
    my $self = shift;
    my $cm = $self->app_name . '::ConstantMap';
    eval "use $cm;";
    unless ($@) {
        $self->{const} = wcm();
    }
}

sub _set_template2stash {
    my $self = shift;
    my ($c, $controller_info) = @_;
    my $stash = $c->stash;
    my $tmpl_sub_dir = 'default';
    my $lang = $c->language;
    if ($lang and -d $self->app_root . "/tmpl/$lang/") { $tmpl_sub_dir = $lang; }
    $stash->{base} = $c->req->base;
    $stash->{template_base} = $self->app_root . "/tmpl/$tmpl_sub_dir/";
    $stash->{c} = $c;
    $stash->{u} = $c->u;
    $stash->{p} = $c->req->params;
    $stash->{env} = \%ENV;
    $stash->{template_sub_dir} = $tmpl_sub_dir;
    if ($controller_info) {
        my $action = $controller_info->[$CONTROLLER_INFO_ACTION];
        $stash->{template} = "$action.tt";
        $c->req->action($action);
        $c->req->action_package(dirname $action);
        $c->req->action_method(filename $action);
    }
}

sub _replace_path_with_uri_map {
    my $self = shift;
    my ($c, $path, $uri_map) = @_;
    if (ref $uri_map eq 'ARRAY') {
        for (my $i = 0; $i < @$uri_map; $i += 2) {
            if ($self->__replace_path_with_uri_map($c, $path, $uri_map->[$i])) {
                return $uri_map->[$i+1];
            }
        }
    }
    else {
        for my $r (keys %$uri_map) {
            if ($self->__replace_path_with_uri_map($c, $path, $r)) {
                return $uri_map->{$r};
            }
        }
    }
    return $path;
}


sub __replace_path_with_uri_map {
    my $self = shift;
    my ($c, $path, $r, $dest) = @_;
    if (my @res = $path =~ /$r/) {
        if (%+) {
            $c->req->args({ %+ });
        }
        else {
            my %res = ();
            my $cnt = 0;
            for (@res) { $res{$cnt++} = $_; }
            $c->req->args(\%res);
        }
        return TRUE;
    }
    return FALSE;
}

sub get_controller {
    my $self = shift;
    my ($c, $path) = @_;
    if (my $uri_map = $self->app_conf('uri_map')) {
        $path = $self->_replace_path_with_uri_map($c, $path, $uri_map);
    }
    my $controller_info = $self->controller_info($path);
    my $controller = $CONTROLLERS{$controller_info->[$CONTROLLER_INFO_PACKAGE]};
    unless ($controller) {
        $controller_info->[$CONTROLLER_INFO_PACKAGE] or return undef;
        $controller = "$controller_info->[$CONTROLLER_INFO_PACKAGE]"->new;
        $CONTROLLERS{$controller_info->[$CONTROLLER_INFO_PACKAGE]} = $controller;
    }
    if (!$controller->can($controller_info->[$CONTROLLER_INFO_METHOD]) and $path !~ /index$/) {
        ($controller, $controller_info) = $self->get_controller($c, "$path/index");
    }
    return ($controller, $controller_info);
}

sub _modify_template_path_on_stash {
    my $self = shift;
    my ($c) = @_;
    my $stash = $c->stash;
    $stash->{template} !~ /^\// and $stash->{template} = "/$stash->{template}";
}

sub _output_filter {}

sub _init_c {};

sub execute_controller {
    my $self = shift;
    my ($c, $path) = @_;
    no strict 'refs';
    my $res = $c->res;
    $c->session_controller->init;
    my ($controller, $controller_info) = $self->get_controller($c, $path);
    $self->_set_template2stash($c, $controller_info); 
    $self->_modify_template_path_on_stash($c);
    unless ($controller) {
        $self->error_response($c, 404);
        die "Can't find controller ($path)" . ref $controller;
    }
    if (my $auth_map = $self->app_conf('auth_map')) {
        for (keys %$auth_map) {
            if ($path =~ /$_/) {
                no strict 'refs';
                my $auth_pkg = $self->app_name . '::Auth::' . $auth_map->{$_};
                unless ($auth_pkg->($c, $c->u)) {
                    $c->goto_error(msgid => 'not_login');
                }
            }
        }
    }
    $self->_init_c($c);
    my $method = $controller_info->[$CONTROLLER_INFO_METHOD];
    if ($method =~ /^_/) { $self->error_response($c, 403); return; }
    $c->controller($controller);
    $controller->can('__begin_auth') and $controller->__begin_auth($c);
    $controller->__begin($c);
    if ($controller->can($method)) {
        {
            local $SIG{__DIE__} = sub {
                print STDERR "@_\n";
                my @stack_dump;
                for (0..5) {
                    my @ca = caller($_);
                    if (@ca) {
                        push @stack_dump, "$ca[0]($ca[2]) - $ca[3]\n";
                    }
                }
                print STDERR join /\n/, @stack_dump;
                print STDERR "\n";
            };
            eval {
                $controller->$method($c);
            };
        }
        if ($@) {
            my $die_msg = $@;
            chomp $die_msg;
            $c->session_controller->data2server;
            die $die_msg;
        }
    }
    else {
        $self->error_response($c, 404);
        die "can't find $method in the " . ref $controller;
    }
END_OF_CONTROLLER:
    if (!defined $res->content and $res->code == 200) {
        my $content = '';
        my $stash = $c->stash;
        $stash->{template} !~ /^\// and $stash->{template} = "/$stash->{template}";
        if ($self->tt->process(
            "$stash->{template_sub_dir}$stash->{template}", $stash, \$content)
        ) {
            $self->_output_filter($c, \$content);
            $res->content($content);
        }
        else {
            $self->error_response($c, 500);
            $c->session_controller->data2server;
            die $self->tt->error;
        }
    }
    $c->session_controller->data2server;
}

sub error_response {
    my $self = shift;
    my ($c, $code) = @_;
    my $res = $c->res;
    $res->code($code);
    my $conf = $self->conf->{custom_error} or return;
    my $template = $conf->{$code} ? $conf->{$code} : $conf->{default};
    $template or return;
    $template !~ /^\// and $template = "/$template";
    my $content = '';
    my $stash = $c->stash;
    if ($self->tt->process(
        "$stash->{template_sub_dir}$template", $stash, \$content)
    ) {
        $res->content($content);
    }
    else {
        die $self->tt->error;
    }
}

sub controller_info {
    my $self = shift;
    my ($path) = @_;
    if ($path eq '') { $path = '/'; }
    else { $path =~ s/(.*)\?(?:.*)/$1/; }
    if ($path ne '/' && $path =~ /\/$/) { $path .= 'index'; }
    my $controllers = $self->controllers;
    if ($controllers->{$path}) {
        return [
            $controllers->{$path},
            'index',
            $path eq '/' ? '/index' : "${path}index"
        ];
    }
    my $package = dirname $path;
    my $method = filename $path;
    my $ab = $self->app_base;
    $ab ne '/' and $package =~ s/^$ab//;
    $method ||= 'index';
    $package eq '/' and $package = '';
    return [ $controllers->{"$package/"}, $method, "$package/$method" ];
}

sub read_static_file {
    my $self = shift;
    my ($c, $path) = @_;
    my $r = $self->app_base;
    (my $fpath = $path) =~ s/^$r//;
    my $res = $c->res;
    my $file_path = $self->app_root . "/root/$fpath";
    my $f;
    unless (open $f, '<', $file_path) {
        my ($controller, $controller_info) = $self->get_controller($c, $path);
        $self->_set_template2stash($c, $controller_info); 
        $self->error_response($c, 404);
        die "$file_path($!)";
    }
    my $data;
    while (<$f>) { $data .= $_; }
    close $f;
    $res->content_type(mimetype($file_path));
    $res->content($data);
    return;
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


