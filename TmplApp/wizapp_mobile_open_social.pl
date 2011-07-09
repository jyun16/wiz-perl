#!/usr/bin/perl

=head1 NAME

    wizapp.pl APPNAME

=head1 AUTHOR

Junichiro NAKAMURA

=cut

use Wiz::Noose;

use Data::Dumper;
use Perl::Tidy;
use Clone qw(clone);

use lib qw(lib);
use Wiz::Term qw(confirm);
use Wiz::Args::Simple qw(getopts);
use Wiz::Util::String qw(normal2pascal pascal2normal);
use Wiz::Util::File qw(:all);
use Wiz::Util::Hash qw(create_ordered_hash);

our $VERSION = 0.1;

our $TMPL_APP_NAME = 'MobileOpenSocialTmpl';
our $TMPL_APP_NAME_S = 'mobile_open_social_tmpl';

my $args = init_args(<<'EOS');
t(tmplapp):
a(autoform):
c(controller):
m(model):
-mobile
v(version)
h(help)
EOS

my ($an, $lan, $nan, $dest) = get_names($args->{0});

my %conf = (
    tmplapp_dir => "./$TMPL_APP_NAME",
    replace     => [
        "s/$TMPL_APP_NAME/$an/g",
        "s/$TMPL_APP_NAME_S/$nan/g",
    ],
    ignore      => [
        '.svn',
    ],
    ignore_model_field => {
        id              => 1,
        last_modified   => 1,
        delete_flag     => 1,
    },
    remove_files => [
        "$dest$an/conf/test/uri_map.pdat",
        "$dest$an/tmpl/default/tt.tt",
        "$dest$an/.svnignore",
    ],
);
my $td = $args->{t} ? $args->{t} : $conf{tmplapp_dir};

sub main {
    print "[ target $args->{0} ]\n";
    $args->{c} and add_controller();
    $args->{m} and add_model();
    check_create_app() and create_app();
    print "\n";
    return 0;
}

sub check_create_app {
    for (qw(c m a)) { $args->{$_} and return 0; }
    return 1;
}

sub add_controller {
    my ($can, $clan, $cnan) = get_names($args->{c});
    print "- add controller $args->{c} -\n";
    (my $pcan = $can) =~ s/::/\//g;
    my $fcnan = $cnan;
    $fcnan =~ s/_::/::/g;
    $fcnan =~ s/::/\//g;
    if (!-f "$dest$an/lib/$an/Controller/$can.pm") {
        replace_copy(
            "$td/lib/$TMPL_APP_NAME/Controller/AllForm.pm",
            "$dest$an/lib/$an/Controller/$pcan.pm",
            [ @{$conf{replace}}, "s#AllForm#$can#g", "s#all_form#$fcnan#g" ],
            $conf{ignore},
        );
        replace_copy(
            "$td/lib/$TMPL_APP_NAME/Controller/AllForm",
            "$dest$an/lib/$an/Controller/$pcan",
            [ @{$conf{replace}}, "s#AllForm#$can#g", "s#all_form#$fcnan#g" ],
            $conf{ignore},
        );
        replace_copy(
            "$td/tmpl/default/all_form",
            "$dest$an/tmpl/default/$fcnan",
            [ @{$conf{replace}}, "s#AllForm#$can#g", "s#all_form#$fcnan#g" ],
            $conf{ignore},
        );
    }
    if ($args->{a}) {
        add_autoform();
    }
    else {
        if (!-d "$dest$an/autoform/default/$fcnan") {
            replace_copy(
                "$td/autoform/default/all_form",
                "$dest$an/autoform/default/$fcnan",
                $conf{replace}, $conf{ignore},
            );
        }
    }
}

sub add_autoform {
    my $conf = do $args->{a} or die "cant't load config $args->{a}: $!\n$@";
    my ($can, $clan, $cnan) = get_names($args->{c});
    print "- add autoform $args->{a} -\n";
    -d "$dest$an/autoform/default/$cnan" or mkdir "$dest$an/autoform/default/$cnan";
    file_write "$dest$an/autoform/default/$cnan/common.pdat", 
        _autoform_common($conf);
    file_write "$dest$an/autoform/default/$cnan/list.pdat", 
        _autoform_list($conf);
    file_write "$dest$an/autoform/default/$cnan/register.pdat", 
        _autoform_register($conf);
}

sub _autoform_common {
    my ($conf) = @_;
    my $c = create_ordered_hash;
    $c->{_extends} = '../../common';
    my $index = $conf->{_index} ? $conf->{_index} : [ keys %$conf ];
    for my $i (@$index) {
        my $ci = $conf->{$i};
        if (ref $ci) {
            my $cl = create_ordered_hash;
            for (qw(item_label type default options attribute validation)) {
                defined $ci->{$_} and $cl->{$_} = $ci->{$_};
            }
            for (keys %$ci) {
                if (ref $ci->{$_}) {
                    exists $cl->{$_} or $cl->{$_} = $ci->{$_};
                }
            }
            $c->{'&' . $i}  = $cl;
        }
        else {
            #$ci eq '_call_common' and $c->{'&' . $i} = "*$i";
        }
    }
    local $Data::Dumper::Indent = 1;
    local $Data::Dumper::Terse = 1;
    return tidy_code(Dumper $c);
}

sub _autoform_list {
    my ($conf) = @_;
    my $index = $conf->{_index} ? $conf->{_index} : [ keys %$conf ];
    my $ret = "{\n";
    $ret .= qq|\t_extends => '../common',\n|;
    $ret .= qq|\t_pager => 'google',\n|;
    for (@$index) { $ret .= qq|\t'$_' => '*$_',\n|; }
    $ret .= qq|\t_forms => [qw(\n|;
    for (@$index) { $ret .= qq|\t\t$_\n|; }
    $ret .= qq|\t)],\n|;
    $ret .= "}\n";
    return $ret;
}

sub _autoform_register {
    my ($conf) = @_;
    my $index = $conf->{_index} ? $conf->{_index} : [ keys %$conf ];
    my $ret = "{\n";
    $ret .= qq|\t_extends => '../common',\n|;
    $ret .= qq|\t_pager => 'google',\n|;
    for (@$index) { $ret .= qq|\t'$_' => '*$_',\n|; }
    $ret .= qq|\t_input_forms => [qw(\n|;
    for (@$index) { $ret .= qq|\t\t$_\n|; }
    $ret .= qq|\t)],\n|;
    $ret .= qq|\t_input_form_status => {\n|;
    $ret .= qq|\t},\n|;
    $ret .= qq|\t_confirm_forms => [qw(\n|;
    for (@$index) { $ret .= qq|\t\t$_\n|; }
    $ret .= qq|\t)],\n|;
    $ret .= "}\n";
    return $ret;
}

sub add_model {
    my ($can, $clan, $cnan) = get_names($args->{m});
    print "- add model $args->{m} -\n";
    (my $pcan = $can) =~ s/::/\//g;
    my $fcnan = $cnan;
    $fcnan =~ s/_::/::/g;
    $fcnan =~ s/::/\//g;
    my $model = "$dest$an/lib/$an/Model/$can.pm";
    if (!-f $model) {
        replace_copy(
            "$td/lib/$TMPL_APP_NAME/Model/AllForm.pm",
            "$dest$an/lib/$an/Model/$pcan.pm",
            [ @{$conf{replace}}, "s#AllForm#$can#g", "s#all_form#$fcnan#g" ],
            $conf{ignore},
        );
    }
    if ($args->{a}) {
        my $conf = do $args->{a} or die "cant't load config $args->{a}: $!\n$@";
        my $index = $conf->{_index} ? $conf->{_index} : [ keys %$conf ];
        open my $f, '<', $model;
        my @model = <$f>;
        close $f;
        open $f, '+<', $model;
        seek $f, 0, 0;
        my $start = 0;
        for (@model) {
            if ($start) {
                if (/^\);$/) {
                    for (@$index) {
                        $conf{ignore_model_field}{$_} or 
                            print $f "$_\n";
                    }
                    $start = 0;
                }
            }
            if ($start == 0) {
                if (/^our \@CREATE = qw\($/) {
                    $start = 1;
                }
                print $f $_;
            }
        }
        truncate $f, tell($f);
        close $f;
    }
}

sub create_app {
    replace_copy($td, "$dest$an", $conf{replace}, $conf{ignore});
    rename("$dest$an", "s/$TMPL_APP_NAME/$an/g");
    rename("$dest$an", "s/tmplapp/$lan/g");
    file_write("$dest$an/lib/$an/Controller/Root.pm", controller_root());
    if ($conf{remove_files}) { for (@{$conf{remove_files}}) { unlink $_; } }
    mv("$dest$an/docs/$TMPL_APP_NAME_S.sql", "$dest$an/docs/$nan.sql");
    mkdir "$dest$an/tmpl/.cache";
    chmod 0777, "$dest$an/logs";
    chmod 0777, "$dest$an/tmpl/.cache";
    chmod 0755, "$dest$an/script/*.pl";
}

sub controller_root {
    my $ret = "package ${an}::Controller::Root;\n";
    $ret .= <<'EOS';

use Wiz::Noose;

extends qw(
    Wiz::Web::Framework::Controller::Root
    Wiz::Web::Framework::Controller::Login
);

our @AUTOFORM = qw(login);
our $AUTHZ_LABEL = 'member';
our $SESSION_NAME = __PACKAGE__;
our $LOGIN_SUCCESS_DEST = '/list';
our $LOGOUT_DEST = '/login';
our $AUTH_FAIL_DEST = '/login';

sub index {
    my $self = shift;
    my ($c) = @_;
    $c->logined ?
        $c->redirect($LOGIN_SUCCESS_DEST) :
        $c->redirect($AUTH_FAIL_DEST);
}

1;
EOS
}

sub get_names {
    my ($name) = @_;
    my $dir = dirname $name;
    if ($dir eq '.') { $dir = ''; }
    if ($dir ne '') { $dir .= '/'; }
    $name = filename $name;
    return (normal2pascal($name), lc $name, pascal2normal($name), $dir);
}

sub tidy_code {
    my ($code) = @_;
    my $ret = '';
    perltidy(source => \$code, destination => \$ret, argv => '');
    return $ret;
}

sub init_args {
    my $args = getopts(shift);
    unless ($args->{0}) { usage(); exit 1; }
    if (defined $args->{h}) { usage(); exit 0; }
    elsif (defined $args->{v}) { version(); exit 0; }
    return $args;
}

sub version {
    print <<EOS;
VERSION: $VERSION

          powered by Junichiro NAKAMURA
EOS
}

sub usage {
    print <<EOS;
USAGE: wizapp.pl [ OPTIONS ] APPNAME

OPTIONS:

    t: $TMPL_APP_NAME directory
    c: Append controller
    m: Append model
    a: autoform config file path to append autoform (must be specified with c option)

        -a sample.pdat

            * sample.pdat

                {
                    'id'          => {
                        item_label  => 'ID',
                        type        => 'text',
                    },
                    'userid' => {
                        item_label  => 'USERID',
                        type        => 'text',
                    },
                    'member_id' => {
                        item_label  => 'MEMBER_ID',
                        type        => 'text',
                        attribute   => {
                            maxlength   => 32,
                            size        => 32,
                            class       => 'box',
                        },
                    },
                }
EOS
}

exit main;

__END__
