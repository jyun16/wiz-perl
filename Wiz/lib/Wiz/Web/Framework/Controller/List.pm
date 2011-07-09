package Wiz::Web::Framework::Controller::List;

=head1 NAME

Wiz::Web::Framework::Controller::List

=head1 VERSION

version 1.0

=cut

our $VERSION = '1.0';

=head1 SYNOPSIS

=cut

use Wiz::Noose;
use Wiz::Util::File qw(dirname);
use Wiz::DB qw(like_sub);
use Wiz::DB::SQL::Constant qw(:like);
use Wiz::Util::String qw(camel2normal);
use Wiz::Validator::Constant qw(IS_EMPTY);

extends qw(Wiz::Web::Framework::Controller);

sub _index {
    my $self = shift;
    my ($c, $af, $p, $s) = @_;
    my $pager = $self->_pager($c, $af);
    my $pager_param = $self->_pager_param($c, $af);
    defined $pager_param and $pager->param($pager_param);
    my $m = $self->_model($c, $af, $p, $s);
    my $sort = $self->_sort($c, $af);
    if ($c->req->method eq 'POST' and !$p->{ignore_validation}) { $af->check_params; }
    my $errors = $af->{validator}{errors};
    if ($af->skip_not_empty) {
        for (keys %$errors) { $errors->{$_} == IS_EMPTY and delete $errors->{$_}; }
    }
    my %forms = map { $_ => 1 } @{$af->forms};
    for (keys %$errors) { $forms{$_} or delete $errors->{$_}; }
    unless ($af->has_error) {
        my $param = $self->_create_search_param($c, $af, $m);
        $self->_append_search_param($c, $param, $m, $af);
        if (defined $param->{-limit}) {
            defined $param->{-limit}[0] and $pager->offset($param->{-limit}[0]);
            defined $param->{-limit}[1] and $pager->limit($param->{-limit}[1]);
        }
        if (defined $param->{-order} and $sort->param eq '') {
            my $order = $sort->order;
            push @$order, @{$param->{-order}};
            $sort->order($order);
        }
        $param->{-limit} = [ $pager->offset, $pager->limit ];
        my %count_param = %$param;
        delete $count_param{-limit};
        delete $count_param{-order};
        my $count_method = $self->ourv('NUMERATE_METHOD') || $self->ourv('COUNT_METHOD') || 'numerate';
        $pager->total_number($m->$count_method(\%count_param));
        $param->{-order} = $sort->order;
        my $list = $self->_execute($c, $param, $af);
        for my $data (@$list) {
            for (keys %$data) {
                my $ft = $af->form_type($_);
                if ($ft eq 'checkbox' or $ft eq 'multiselect') {
                    $data->{$_} = [ split /\t/, $data->{$_} ];
                }
            }
        }
        $af->list_values($list);
        $c->stash->{sort} = $sort;
        $c->stash->{pager} = $pager;
    }
}

sub _model {
    my $self = shift;
    my ($c, $af, $p, $s) = @_;
    return $c->slave_model($self->ourv('MODEL'));
}

sub _index_multi_list {
    my $self = shift;
    my ($model_name, $c) = @_;
    my $normal_model_name = camel2normal $model_name;
    my $af = $c->autoform([ $normal_model_name, 'list' ], $c->req->params);
    my $pager = $self->_pager($c, $af);
    my $p = $c->req->params;
    my $s = $self->_session($c);
    my $m = $self->_model($c, $af, $p, $s);
    my $sort = $self->_sort($c, $af);
    $c->req->method eq 'POST' and $af->check_params;
    my $ret = {};
    unless ($af->has_error) {
        my $param = $self->_create_search_param($c, $af, $m);
        $self->_append_search_param($c, $param, $m, $af);
        if (defined $param->{-limit}) {
            defined $param->{-limit}[0] and $pager->offset($param->{-limit}[0]);
            defined $param->{-limit}[1] and $pager->limit($param->{-limit}[1]);
        }
        if (defined $param->{-order} and $sort->param eq '') {
            my $order = $sort->order;
            push @$order, @{$param->{-order}};
            $sort->order($order);
        }
        $param->{-limit} = [ $pager->offset, $pager->limit ];
        my %count_param = %$param;
        delete $count_param{-limit};
        delete $count_param{-order};
        my $count_method = $self->ourv('NUMERATE_METHOD') || $self->ourv('COUNT_METHOD') || 'numerate';
        $pager->total_number($m->$count_method(\%count_param));
        $param->{-order} = $sort->order;
        my $search_method = $self->ourv('SEARCH_METHOD') || 'search';
        $af->list_values($m->$search_method($param));
        $c->stash->{"af_$normal_model_name"} = $af;
        $c->stash->{sort}{$normal_model_name} = $sort;
        $c->stash->{pager}{$normal_model_name} = $pager;
    }
    return $ret;
}

sub _create_search_param {
    my $self = shift;
    my ($c, $af, $m) = @_;
    my %param = ();
    if ($self->ourv('ORDER', '@')) {
        $param{-order} = [ $self->ourv('ORDER', '@') ];
    }
    my $like_search = { $self->ourv('LIKE_SEARCH', '%') };
    my $params = $c->req->params;
    for my $k ($m->ourv('SEARCH', '@')) {
        my $p = $params->{$k};
        defined $p or $p = '';
        $p eq '' and next;
        my @p = split /\s/, $p;
        if (@p > 1) {
            if (defined $like_search->{$k}) {
                my @d = ();
                my $sub = like_sub($like_search->{$k});
                for (@p) {
                    push @d, [ 'like', $k, $sub->($_) ],
                }
                $param{-or} = \@d;
            }
            else { $param{-in} = { $k => \@p, }; }
        }
        else {
            if (defined $like_search->{$k}) {
                $param{$k} = [ 'like', like_sub($like_search->{$k})->($p) ];
            }
            else {
                if ($af->is_multi_value($k) && $af->is_join_mode($k)) {
                    $p = [ $p ] unless ref $p;
                    my @d = ();
                    for (@$p) { push @d, [ 'like', $k, Wiz::DB::like("\t$_") ], }
                    $param{-or} = \@d;
                }
                else {
                    $param{$k} = $p;
                }
            }
        }
    }
    return \%param;
}

sub _execute {
    my $self = shift;
    my ($c, $param, $af) = @_;
    my $m = $self->_model($c, $af, $c->req->params, $self->_session($c));
    my $search_method = $self->ourv('SEARCH_METHOD') || 'search';
    my $ret = $m->$search_method($param);
    $self->_append_value($c, $param, $ret, $m);
    return $ret;
}

sub __before_index {}
sub _before_index {}
sub _after_index {}
sub _before_execute_index {}
sub _after_execute_index {}
sub _append_search_param {}
sub _pager_param {}
sub _append_value {}

sub _restore_current_search_params {
    my $self = shift;
    my ($c, $af, $p, $s) = @_;
    my $referer = $c->req->referer;
    my $action = dirname $c->req->action_package;
    if ($referer =~ /$action/ and $referer =~ /modify|delete/) {
        for (keys %$s) { $p->{$_} = $s->{$_}; $af->param($_ => $s->{$_}); }
    }
}

sub _save_current_search_params {
    my $self = shift;
    my ($c, $af, $p, $s) = @_;
    for (keys %$p) { $s->{$_} = $p->{$_}; }
}

sub index {
    my $self = shift;
    my ($c) = @_;
    my $af = $c->autoform([$self->ourv('AUTOFORM', '@')], $c->req->params, { language => $c->language });
    my $p = $c->req->params;
    my $s = $self->_session($c);
    my $method = $c->req->method;
    if (ref $self->ourv('MODEL')) {
        if ($method eq 'GET') {
            $self->__before_index($c, $af, $p, $s);
            $self->_before_index($c, $af, $p, $s);
            for (@{$self->ourv('MODEL')}) { $self->_index_multi_list($_, $c); }
            $self->_after_index($c, $af, $p, $s);
        }
        elsif ($method eq 'POST') {
            $self->__before_index($c, $af, $p, $s);
            $self->_before_execute_index($c, $af, $p, $s);
            for (@{$self->ourv('MODEL')}) { $self->_index_multi_list($_, $c); }
            $self->_after_execute_index($c, $af, $p, $s);
        }
    }
    else {
        if ($method eq 'GET') {
            $self->_restore_current_search_params($c, $af, $p, $s);
            $self->__before_index($c, $af, $p, $s);
            $self->_before_index($c, $af, $p, $s);
            $self->_index($c, $af, $p, $s);
            $self->_after_index($c, $af, $p, $s);
        }
        elsif ($method eq 'POST') {
            $self->_save_current_search_params($c, $af, $p, $s);
            $self->__before_index($c, $af, $p, $s);
            $self->_before_execute_index($c, $af, $p, $s);
            $self->_index($c, $af, $p, $s);
            $self->_after_execute_index($c, $af, $p, $s);
        }
    }
    my $stash = $c->stash;
    $stash->{f} = $af;
    $stash->{s} = $s;
}

=head1 AUTHOR

Junichiro NAKAMURA, C<< <jyun16@gmail.com> >>

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
