package Wiz::Web::Framework::Model;

use Carp;

use Wiz::Noose;
use Wiz qw(ourv);
use Wiz::Constant qw(:common);
use Wiz::Util::String qw(camel2normal);
use Wiz::Util::Hash qw(args2hash override_hash);
use Wiz::DB qw(db_label2status);
use Wiz::DB::Constant qw(:status);
use Wiz::DB::Cluster::Controller;
use Wiz::DB::DataIO;
use Wiz::DateTime;

extends qw(Wiz::DB::DataIO);

has 'conn' => (is => 'rw', required => 1);
has 'table_name' => (is => 'rw');
has 'hs' => (is => 'rw');

our $USE_HANDLER_SOCKET = FALSE;

sub new {
    my $self = shift;
    my ($conn, $table_name) = @_;
    ref $conn or return;
    my %args = ();
    $args{table_name} = $table_name;
    $self->_noose_init_args(\%args);
    $table_name ||= $self->find_table_name;
    my $ret = $self->SUPER::new($conn, $table_name);
    for (keys %args) { $ret->{$_} ||= $args{$_}; }
    if ($conn->{hs}) {
        $ret->{hs} = $ret->handler_socket('PRIMARY', ['id',$ret->ourv('CREATE', '@')]);
    }
    return $ret;
}

sub find_table_name {
    my $self = shift;
    no strict 'refs';
    my $table_name = $self->{table};
    defined $table_name and return $table_name;
    $table_name = ${"${self}::TABLE_NAME"};
    defined $table_name and return $table_name;
    $self =~ /::([^\:]*)$/;
    $table_name = camel2normal($1);
    return $table_name;
}

sub set_table_name {
    my $self = shift;
    $self->{table} = shift;
}

sub instance {
    my $self = shift;
    my ($c, $conn, $table_name) = @_;
    $table_name ||= $self->table_name;
    my $instance = $self->SUPER::new($conn, $table_name);
    $instance->{_c} = $c;
    return $instance;
}

sub debug {
    my $self = shift;
    $self->{debug} = shift;
}

sub db {
    my $self = shift;
    return $self->{dbc};
}

sub c {
    my $self = shift;
    return $self->{_c};
}

sub u {
    my $self = shift;
    my ($label, $session_label) = @_;
    $label ||= 'default';
    my $c = $self->{_c};
    return $c->logined($label, $session_label) ? $c->u($label, $session_label) : undef;
}

sub user {
    my $self = shift;
    my $u = $self->u(@_);
    return $u ? $u->{user} : undef;
}

*appconf = 'app_conf';
sub app_conf {
    my $self = shift;
    $self->c->app_conf(@_);
}

sub numerate {
    my $self = shift;
    my ($param) = args2hash(@_);
    if ($self->ourv('DELETE_FLAG')) {
        defined $param->{delete_flag} or $param->{delete_flag} = 0;
    }
    my %filters = $self->ourv('SEARCH_FILTERS', '%');
    my @search = $self->ourv('SEARCH', '@');
    for (@search) {
        exists $param->{$_} or next;
        if (defined $filters{$_}) {
            $param->{$_} = $filters{$_}->($self, $param->{$_});
        }
    }
    return $self->count($param);
}

sub search {
    my $self = shift;
    my ($param) = args2hash(@_);
    if ($self->ourv('DELETE_FLAG')) {
        defined $param->{delete_flag} or $param->{delete_flag} = 0;
    }
    my %filters = $self->ourv('SEARCH_FILTERS', '%');
    my @search = $self->ourv('SEARCH', '@');
    for (@search) {
        exists $param->{$_} or next;
        if (defined $filters{$_}) {
            $param->{$_} = $filters{$_}->($self, $param->{$_});
        }
    }
    my $rs = $self->select($param);
    my @ret = ();
    while ($rs->next) { push @ret, $rs->data; }
    return \@ret;
}

sub getone {
    my $self = shift;
    my ($param) = args2hash(@_);
    if ($self->{hs}) {
        if (my $d = $self->{hs}->retrieve($_[1])) { return $d; }
    }
    if ($self->ourv('DELETE_FLAG')) {
        defined $param->{delete_flag} or $param->{delete_flag} = 0;
    }
    my %filters = $self->ourv('SEARCH_FILTERS', '%');
    my @search = $self->ourv('SEARCH', '@');
    for (@search) {
        exists $param->{$_} or next;
        if (defined $filters{$_}) {
            $param->{$_} = $filters{$_}->($self, $param->{$_});
        }
    }
    my $rs = $self->select($param);
    return $rs->next ? $rs->data : undef;
}

sub search4list {
    my $self = shift;
    my $param = args2hash @_;
    my $query =  $self->create_query;
    $query->table($self->ourv('FROM'));
    $query->fields($self->ourv('FIELDS', '@'));
    $query->where($param);
    my $rs = $self->execute($query->select, $query->values);
    my @ret = ();
    while ($rs->next) { push @ret, $rs->data; }
    $self->clear;
    return \@ret;
}

sub numerate4list {
    my $self = shift;
    my $param = args2hash @_;
    my $query =  $self->create_query;
    $query->table($self->ourv('FROM'));
    $query->fields('*');
    $query->where($param);
    my $rs = $self->execute($query->count, $query->values);
    defined $rs or return undef;
    return $rs->next ? $rs->get('COUNT') : return 0;
}

sub _getone {
    my $self = shift;
    my $param = args2hash @_;
    my $query =  $self->create_query;
    $query->table($self->ourv('FROM'));
    $query->fields($self->ourv('FIELDS', '@'));
    $query->where($param);
    my $rs = $self->execute($query->select, $query->values);
    $self->clear;
    return $rs->next ? $rs->data : undef;
}

sub create {
    my $self = shift;
    my ($param) = args2hash(@_);
    my %filters = $self->ourv('CREATE_FILTERS', '%');
    my @create = $self->ourv('CREATE', '@');
    if (grep /created_time/, @create) {
        $param->{created_time} or 
            $param->{created_time} = Wiz::DateTime->new->to_string || undef;
    }
    for (@create) {
        if (defined $filters{$_}) {
            if ($self->{data}{$_}) {
                $self->{data}{$_} = $filters{$_}->($self, $self->{data}{$_});
            }
            else {
                exists $param->{$_} or next;
                $self->set($_, $filters{$_}->($self, $param->{$_}));
            }
        }
        else {
            exists $param->{$_} or next;
            if (ref $param->{$_} eq 'ARRAY') {
                $self->set($_, "\t" . join ("\t", @{$param->{$_}}));
            }
            else {
                $self->set($_, $param->{$_});
            }
        }
    }
    $self->{debug} and $self->{dbc}->log->debug($self->insert_dump);
    $self->insert;
    $self->get_insert_data;
}

sub create_or_modify {
    my $self = shift;
    my ($param) = args2hash(@_);
    my $primary_key = $self->ourv('PRIMARY_KEY');
    my $modify_key = $self->ourv('MODIFY_KEY');
    my $old_data = $self->getone($primary_key => $param->{$primary_key});
    if (exists $param->{$primary_key} && $old_data) {
        $self->modify($param);
        return $old_data;
    } elsif ($modify_key) {
        my $p = {};
        if (ref $modify_key eq 'ARRAY') {
            for (@$modify_key) { $p->{$_} = $param->{$_} };
        } else {
            $p->{$modify_key} = $param->{$modify_key};
        }
        my $data = $self->getone($p);
        if ($data) {
            $param->{$primary_key} = $data->{$primary_key};
            $self->modify($param);
            return $data;
        }
    }
    return $self->create($param);
}

sub modify {
    my $self = shift;
    my ($param) = args2hash(@_);
    my $primary_key = $self->ourv('MODIFY_KEY') || $self->ourv('PRIMARY_KEY');
    my @modify = $self->ourv('MODIFY', '@');
    my %filters = $self->ourv('MODIFY_FILTERS', '%');
    %filters or %filters = $self->ourv('CREATE_FILTERS', '%');
    for (@modify) {
        $_ eq 'created_time' and next;
        if (defined $filters{$_}) {
            if ($self->{data}{$_}) {
                $self->{data}{$_} = $filters{$_}->($self, $self->{data}{$_});
            }
            else {
                exists $param->{$_} or next;
                $self->set($_, $filters{$_}->($self, $param->{$_}));
            }
        }
        else {
            exists $param->{$_} or next;
            if (ref $param->{$_} eq 'ARRAY') {
                $self->set($_, "\t" . join("\t", @{$param->{$_}}));
            }
            else {
                $self->set($_, $param->{$_});
            }
        }
    }
    if (ref $primary_key) {
        my %w = ();
        for (@$primary_key) { $w{$_} = $param->{$_}; }
        $self->{debug} and $self->{dbc}->log->debug($self->update_dump(\%w));
        $self->update(\%w);
    }
    else {
        $self->{debug} and 
            $self->{dbc}->log->debug($self->update_dump($primary_key => $param->{$primary_key}));
        $self->update($primary_key => $param->{$primary_key});
    }
}

sub modify_key_params {
    my $self = shift;
    my ($param) = args2hash(@_);
    my $primary_key = $self->ourv('MODIFY_KEY') || $self->ourv('PRIMARY_KEY');
    if (ref $primary_key) {
        my %w = ();
        for (@$primary_key) { $w{$_} = $param->{$_}; }
        return \%w;
    }
    else {
        return $param->{$primary_key};
    }
}

sub drop {
    my $self = shift;
    my ($param) = args2hash(@_);

    my $primary_key =
        $self->ourv('DELETE_KEY') || $self->ourv('MODIFY_KEY') || $self->ourv('PRIMARY_KEY');
    if (ref $primary_key) {
        my %w = ();
        for (@$primary_key) { $w{$_} = $param->{$_}; }
        $self->{debug} and $self->{dbc}->log->debug($self->delete_dump(\%w));
        $param = \%w;
    }
    elsif (defined $primary_key) {
        $param = {
            $primary_key => $param->{$primary_key}
        };
    }
    if ($self->ourv('DELETE_FLAG')) {
        $param->{DELETE_FLAG} = 1;
        $self->{debug} and 
            $self->{dbc}->log->debug($self->update_dump($param));
        $self->update($param);
    }
    else {
        $self->{debug} and 
            $self->{dbc}->log->debug($self->delete_dump($param));
        $self->delete($param);
    }
}

*remove = 'drop';

sub remove_key_params {
    my $self = shift;
    my ($param) = args2hash(@_);
    my $primary_key =
        $self->ourv('DELETE_KEY') || $self->ourv('MODIFY_KEY') || $self->ourv('PRIMARY_KEY');
    if (ref $primary_key) {
        my %w = ();
        for (@$primary_key) { $w{$_} = $param->{$_}; }
        return \%w;
    }
    else {
        return { $primary_key => $param->{$primary_key} };
    }
}

sub worker {
    my $self = shift;
    my ($name) = @_;
    croak "must pass worker name!!" unless $name;
    my $w = 
        $self->{_c} ?
            $self->{_c}->worker($name) :
            do {
                my $ref = ref $self;
                $ref =~ /.*Model::(.*)$/;
                "$self->app_name::Worker::$1"->new(dbc => $self->dbc);
            };
    return $w;
}

sub model {
    my $self = shift;
    my ($table, $dbc) = @_;
    croak "must pass table name!!" unless $table;
    my $m = 
        $self->{_c} ?
            $self->{_c}->model($table, $dbc ? $dbc : $self->dbc) :
            do {
                my $ref = ref $self;
                $ref =~ /(.*Model::)(.*)$/;
                "$1$table"->new($dbc ? $dbc : $self->dbc);
            };
    $m->clear;
    return $m;
}


sub init_cluster_model {
    my $self = shift;
    my ($table, $cluster_group, $key) = @_;
    my $cc = $self->cluster_controller;
    my $parent = $self->{dbc};
    my $field = "$self->{cluster_label_field_prefix}_$cluster_group";
    if ($self->is_slave) {
        $parent->write_error("can't init clusterd data, because this is slave model.");
    }
    else {
        my $child = $cc->get_master_in_group($cluster_group);
        $self->set($field => $child->label);
        $self->update($key);
    }
}

sub _cluster_model {
    my $self = shift;
    my ($table, $cluster_group, $key, $ms) = @_;
    my $cc = $self->cluster_controller;
    my $parent = $self->{dbc};
    if (not defined $cc) {
        $parent->write_error('set cluster controller.');
        return;
    }
    my $field = "$self->{cluster_label_field_prefix}_$cluster_group";
    my $label;
    if (ref $key eq 'HASH') {
        my $label_data = $self->getone($key);
        $label = $label_data->{$field};
    }
    else { $label = $key; }
    my $child;
    if ($label) {
        if ($ms) {
            $child = $ms == SLAVE ? $cc->get_slave($label) : $cc->get_master($label);
        }
        else {
            $child = $self->is_slave ? $cc->get_slave($label) : $cc->get_master($label);
        }
    }
    $self->model($table, $child);
}

sub cluster_model {
    shift->_cluster_model(@_);
}

sub cluster_master_model {
    shift->_cluster_model(@_, MASTER);
}

sub cluster_slave_model {
    shift->_cluster_model(@_, SLAVE);
}

sub csv_data {
    my $self = shift;
    my ($param) = @_;
    my @fields = $self->ourv('CSV_DATA_FIELDS', '@');
    my $data = $self->search(fields => \@fields, where => $param);
    my @ret = ();
    for my $d (@$data) {
        my @r = ();
        for my $f (@fields) {
            push @r, $d->{$f};
        }
        push @ret, \@r;
    }
    return \@ret;
}

sub handler_socket {
    my $self = shift;
    $self->{dbc}->handler_socket($self->{table}, @_);
}

sub handler_socket_error {
    shift->{dbc}->handler_socket_error;
}

sub writable_handler_socket {
    my $self = shift;
    $self->{dbc}->writable_handler_socket($self->{table}, @_);
}

sub writable_handler_socket_error {
    shift->{dbc}->writable_handler_socket_error;
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
