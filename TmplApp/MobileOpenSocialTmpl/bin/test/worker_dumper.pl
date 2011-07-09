#!/usr/bin/perl

use strict;

use MIME::Base64;
use Storable qw(thaw);

use Wiz::Dumper;
use Wiz::DateTime;
use Wiz::Web::Framework::BatchBase;
use Wiz::Util::String qw(normal2pascal);
use Wiz::Web::Framework::Context;

use MobileOpenSocialTmpl;

my $args = init_args(get_args(<<EOS));
t(table):
m(model):
EOS

my $c = get_context;
force_generate_model();
my $model = $c->model($args->{m} || normal2pascal($args->{t}));

sub main {
    if ($args->{0} eq 'list') { list(); }
    elsif ($args->{0} eq 'get') { get(); }
    elsif ($args->{0} eq 'dump') { dump_all(); }
    elsif ($args->{0} eq 'remove') { remove(); }
    elsif ($args->{0} eq 'remove_all') { remove_all(); }
    $model->commit;
    return 0;
}

sub list {
    my $rs = $model->select;
    while ($rs->next) {
        print $rs->get('id') . "\n"; 
    }
}

sub get {
    print_model(thaw_data($model->retrieve(id => $args->{1})));
}

sub dump_all {
    my $rs = $model->select;
    while ($rs->next) {
        print_model(thaw_data($rs->data));
    }
}

sub remove {
    print_success_or_fail($model->delete(id => $args->{1}));
}

sub remove_all {
    my $rs = $model->select;
    while ($rs->next) {
        my $id = $rs->get('id');
        print "$id";
        print_success_or_fail($model->delete(id => $id));
    }
}

sub thaw_data {
    my ($data) = @_;
    $data->{args} = thaw decode_base64 $data->{args};
    return $data;
}

sub print_model {
    my ($data) = @_;
    $data or return;
    my $expire = new Wiz::DateTime;
    $expire->set_epoch($data->{expires});
    print "Expire: $expire\n";
    wd $data;
}

sub print_success_or_fail {
    print (shift() ? "[SUCCESS]\n" : "[FAIL]\n");
}

sub force_generate_model {
    my $app_name = $c->app_name;
    my $model_name = normal2pascal($args->{t});
    my $model_package = "${app_name}::Model::$model_name";
    eval "use $model_package";
    if ($@) {
        my $package = <<EOS;
package $model_package;

use Wiz::Noose;

extends qw(
    Wiz::Web::Framework::Model
);

1;
EOS
        eval $package;
        $Wiz::Web::Framework::Context::LOADED_MODEL{$model_package} = 1;
    }
}

sub init_args {
    my ($args) = @_;
    (!$args->{m} and !$args->{t}) and die "Please specify model(-m) or table(-t) name";
    $ENV{WIZ_APP_ENV} = $args->{env};
    return $args;
}

sub usage {
    my ($opt, $desc) = qw(%-16s %-30s);
    print "$Wiz::Web::Framework::BatchBase::SCRIPT_NAME -p PORT [ OPTIONS ] {list|get|dump|remove ID|remove_all}\n\n";
    printf " $opt $desc\n", '-t, --table', '';
    printf " $opt $desc\n", '-m, --model', '';
    printf " $opt $desc\n", '-h, --help', 'Usage';
}

exit main;

package JanetJobs;


