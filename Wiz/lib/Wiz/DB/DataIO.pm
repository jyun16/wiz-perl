package Wiz::DB::DataIO;

use strict;

=head1 NAME

Wiz::DB::DataIO - Data Access Object

=head1 VERSION

version 1.0

=cut

our $VERSION = '1.0';

=head1 SYNOPSIS

 my $data = Wiz::DB::DataIO->new($dbc, 'TABLE_NAME');
 my $rs = $data->select(column => 'value');
 if ( $rs->next ) {
    my $column_value = $rs->get('column_name');
 }

=head2 COUNT

 # returns the count of $table's all data.
 $data->count;
 
 # returns the count of $table data name is 'blah'.
 $data->count({ name => 'blah' });

=head2 SELECT

 # returns Wiz::DB::ResultSet can fetch all data of the table.
 my $rs = $data->select;
 
 # returns all data. too heavy.
 my @data = $data->select;
 
 # returns Wiz::DB::ResultSet can fetch the data of id is 2.
 my $rs = $data->select(id => 1)
 
=head3 RETRIEVE

 # returns hash reference value id is 1 in the table.
 my $data = $data->retrieve(id => 1)
 
 # returns hash reference value. it has id, name field value.
 my $data = $data->retrieve(fields => [qw(id name)], where => { id => 1 })

=head2 INSERT

 $data->set(name => 'blah');
 $data->set(data => 'BLAH!');
 
 # returns 1 when insert success.
 $data->insert;
 
 # returns the id of data last inserted.
 $data->get_insert_id;
 
 # returns the data of last inserted.
 $data->get_insert_data;
 
=head2 UPDATE

 $data->set(name => 'foo');
 $data->set(data => 'BAR!');
 
 # returns 1 when update success.
 $data->update(id => 1);

=head2 DELETE

 $data->delete(id => 1);

=head2 PREPARED

In case of need to execute same query too many times, 

 my $pstmt = $data->prepared_insert(qw(name data));
 
 $pstmt->execute_only('foo', 'FOO');
 $pstmt->execute_only('bar', 'BAR');
 $pstmt->execute_only('blah', 'BLAH');

=head2 SIMPLE JOIN

 use Wiz::DB::SQL::Constant qw(:join)
 
 my $foo = new Wiz::DB::DataIO($conn, 'foo');
 $foo->join(INNER_JOIN, [ $foo => 'bar_id' ], [ bar => 'id' ]);
 
 # SELECT * FROM foo INNER JOIN bar ON foo.bar_id=bar.id
 $foo->select_dump;

=head2 TWO TABLES JOIN

 my $foo = new Wiz::DB::DataIO($conn, 'foo');
 my $bar = new Wiz::DB::DataIO($conn, 'bar');
 
 $foo->join(INNER_JOIN, [ $foo => 'bar_id' ], [ $bar => 'id' ]);
 
 # SELECT * FROM foo INNER JOIN bar ON foo.bar_id=bar.id
 $foo->select_dump
 
 # SELECT bar.id AS bar_id,bar.name AS bar_name,foo.id AS foo_id FROM foo INNER JOIN bar ON foo.bar_id=bar.id
 $foo->select_dump(fields => { foo => 'id', bar => ['id', 'name'] });
 
=head3 SPECIFIED FIELDS
 
 my $rs = $foo->select(fields => { foo => 'id', bar => ['id', 'name'] });
 $rs->next;
 $rs->get('foo_id');
 $rs->get('bar_id');
 $rs->get('bar_name');
 
=head3 USE ALIAS
 
 $foo->alias('f');
 $bar->alias('b');
 $foo->join(INNER_JOIN, [ $foo => 'bar_id' ], [ $bar => 'id' ]);
 
 # SELECT * FROM foo f INNER JOIN bar b ON f.bar_id=b.id
 $foo->select_dump;
 
 $rs = $foo->select(fields => { f => 'id', b => ['id', 'name'] });
 $rs->next;
 $rs->get('f_id');
 $rs->get('b_id');
 $rs->get('b_name');
 
 $foo->join(INNER_JOIN,
     [ $foo => 'bar_id' ],
     [ $bar => 'id' ],
     {
         foo    => 'f',
         bar    => 'b',
     },
 );
 
 # SELECT * FROM foo f INNER JOIN bar b ON f.bar_id=b.id
 $foo->select_dump;
 
 $rs = $foo->select(field => { f => 'id', b => ['id', 'name'] });
 $rs->next;
 $rs->get('f_id');
 $rs->get('b_id');
 $rs->get('b_name');

=head3 DATA CLUSTER

You can get clusterd data.

 my %mysql_param = (
     type            => DB_TYPE_MYSQL,
     db              => 'test',
     user            => 'root',
     priority_flag   => ENABLE,
     log => {
         stderr  => 1,
         path    => 'logs/cluster_controller.log',
     },
     clusters    => {
         member          => 'conf/member.pdat',
         footstamp01     => {
             priority    => 10,
             _conf       => 'conf/footstamp01.pdat',
         },
         footstamp02     => {
             priority    => 5,
             _conf       => 'conf/footstamp02.pdat',
         },
         article01       => 'conf/article01.pdat',
         article02       => 'conf/article02.pdat',
     },
 );

 my $cc = new Wiz::DB::Cluster::Controller(%mysql_param);
 my $member = new Wiz::DB::DataIO($cc->get_master('member'), 'member');
 $member->cluster_controller($cc);
 $member->set(id => 1);
 
 my $article = $member->cluster_data_io('article');
 my $footstamp = $member->cluster_data_io('footstamp');
 
 is_defined $article, q|$member->cluster_data_io('article')|;
 is_defined $footstamp, q|$member->cluster_data_io('footstamp')|;
 
 $member->commit;

If you hate $member->commit, call $member->cluster_data_io_with_commit('article');

=cut

use base qw(Class::Accessor::Fast);

use Scalar::Util qw(blessed);
use Storable qw(thaw nfreeze);
use MIME::Base64;

use Wiz qw(get_hash_args);
use Wiz::Constant qw(:common);
use Wiz::Util::Array qw(args2array);
use Wiz::Util::Hash qw(create_ordered_hash args2hash);
use Wiz::DB::Constant qw(:all);
use Wiz::DB::SQL::Where;
use Wiz::DB::SQL::Where::MySQL qw(against);
use Wiz::DB::SQL::Query;
use Wiz::DB::SQL::Query::MySQL;
use Wiz::DB::SQL::Query::PostgreSQL;

=head1 ACCESSORS

 dbc
 data
 table
 alias
 query
 primary_key
 use_cache
 cluster_controller
 cluster_label_field_prefix

=cut

__PACKAGE__->mk_accessors(qw(dbc data table alias query use_cache cluster_controller cluster_label_field_prefix));

=head1 CONSTRUCTOR

=head2 new($dbc, $table)

=cut

sub new {
    my $self = shift;
    my ($dbc, $table, $alias) = @_;

    my $instance = bless {
        dbc                 => $dbc,
        data                => create_ordered_hash,
        table               => $table,
        alias               => $alias,
        query               => undef,
        primary_key         => 'id',
        use_cache           => FALSE,
        cluster_controller  => undef,
        cluster_label_field_prefix  => 'cluster_label',
    }, $self;

    $dbc->can('cache') and defined $dbc->cache and $instance->{use_cache} = TRUE;

    $instance->init_instance;

    return $instance;
}

=head1 METHODS

=head2 prepared_delete($columns, $where)

Returns Wiz::DB::PreparedStatement object that is set the DELETE.

=cut

sub init_instance {}

=head2 set($key, $value)

Sets the value for INSERT or UPDATE.

 my $data = new Wiz::DB::DataIO($dbc, 'TABLE_NAME');
 $data->{name} = 'NAME';
 $data->{age} = 31;

 $data->insert;

=cut

sub set {
    my $self = shift;
    my $args = ref $_[0] eq 'HASH' ? [ %{$_[0]} ] : args2array @_;
    my $n = @$args;
    for (my $i = 0; $i < $n; $i+=2) {
        $self->{data}{$args->[$i]} = $args->[$i+1];
    }
}

=head2 $value = get($key)

Gets the value that set by set method.

 $data->get('name');

=cut

sub get {
    my $self = shift;
    return $self->{data}{+shift};
}

=head2 remove($key);

Removes the value that set by set method.

 $data->remove('name');

=cut

sub remove {
    my $self = shift;
    delete $self->{data}{+shift};
}

=head2 clear;

Delete all values that set by set method.

=cut

sub clear {
    my $self = shift;
    $self->{data} = create_ordered_hash;
    $self->{query} = undef;
}

sub fields {
    my $self = shift;
    $self->{query} = defined $self->{query} ? $self->{query} : $self->create_query;
    $self->{query}->fields(@_);
}

sub where {
    my $self = shift;
    $self->{query} = defined $self->{query} ? $self->{query} : $self->create_query;
    $self->{query}->where(@_);
}
sub sub_query {
    my $self = shift;
    $self->{query} = defined $self->{query} ? $self->{query} : $self->create_query;
    $self->{query}->sub_query(@_);
}

=head2 $query = create_query

Returns Wiz::DB::SQL::Query instance.

=cut

sub create_query {
    my $self = shift;
    return new Wiz::DB::SQL::Query(
        type => $self->{dbc}->type, table => $self->{table});
}

=head2 $count = count(@args)

Executes query and returns result value.
@args is same value for Wiz::DB::SQL::Query::count.

=cut

sub count {
    my $self = shift;
    my $query = defined $self->{query} ? $self->{query} : $self->create_query;
    my $rs = $self->{dbc}->execute($query->count(@_), $query->values);
    defined $rs or return undef;
    return $rs->next ? $rs->get('count') : return 0;
}

=head2 $query = count_dump(@args)

Returns query values already binded(for debug).

=cut

sub count_dump {
    my $self = shift;
    my $query = defined $self->{query} ? $self->{query} : $self->create_query;
    return $query->count_dump(@_);
}

=head2 $prepared_statement = prepared_count(@args)

Returns Wiz::DB::PreparedStatement object.

=cut

sub prepared_count {
    my $self = shift;
    my $query = defined $self->{query} ? $self->{query} : $self->create_query;
    $self->{dbc}->prepared_statement($query->count(@_));
}

=head2 $data or $result_set = retrieve(@arg)

Execute select query and returns the result hash reference value.

=cut

sub retrieve {
    my $self = shift;

    my $query = $self->create_query;
    my $cache_key;
    if ($self->use_cache) {
        $cache_key = $self->get_cache_key(@_);
        my $ret = $self->{dbc}->cache->get($cache_key);
        (defined $ret and $ret ne '') and return thaw decode_base64 $ret;
    }
    my $rs = $self->{dbc}->execute($query->select(@_), $query->values);
    defined $rs or return undef;
    $rs->next;
    my $data = $rs->data;
    my $ret = %$data ? $data : undef;
    if ($self->use_cache and defined $ret) {
        $self->{dbc}->cache->set($cache_key => encode_base64(nfreeze($ret)));
    }
    return $ret;
}

=head2 @data or $result_set = select(@args)

Executes query and returns result value.
@args is same value for Wiz::DB::SQL::Query::select.

When use wantarray, result data array value.
Other case, return Wiz::DB::ResultSet.

=cut

sub select {
    my $self = shift;
    my $query = defined $self->{query} ? $self->{query} : $self->create_query;
    my $rs = $self->{dbc}->execute($query->select(@_), $query->values);
    defined $rs or return undef;
    if (wantarray) {
        my @list = ();
        while ($rs->next) { push @list, $rs->data; }
        return @list;
    }
    else { return $rs; }
}

=head2 $data = select_data(@args)

Executes query and returns result value.
Returns result data array reference.

for to call in the Template::Toolkit's template file.

=cut

sub select_data {
    my $self = shift;
    return [ $self->select(@_) ];
}

=head2 $query = select_dump($columns, $where)

Returns query values already binded(for debug).

=cut

sub select_dump {
    my $self = shift;

    my $query = defined $self->{query} ? $self->{query} : $self->create_query;
    return $query->select_dump(@_);
}

=head2 $prepared_statement = prepared_select(@args)

Returns Wiz::DB::PreparedStatement object.

=cut

sub prepared_select {
    my $self = shift;
    my $query = defined $self->{query} ? $self->{query} : $self->create_query;
    $self->{dbc}->prepared_statement($query->select(@_));
}

=head2 $lines = insert(@args)

Executes query and it returns the number of influenced lines.

=cut

sub insert {
    my $self = shift;
    my $dump_mode = shift;

    $self->_slave_check;
    keys %{$self->{data}} < 1 and return;
    my $query = $self->create_query;
    return $dump_mode ? 
        $query->insert_dump($self->{data}) :
        $self->{dbc}->execute_only($query->insert($self->{data}), $query->values);
}

=head2 $query = insert_dump(@args)

Returns query values already binded(for debug).

=cut

sub insert_dump {
    my $self = shift;
    $self->insert(TRUE);
}

=head2 $prepared_statement = prepared_insert(@args)

Returns Wiz::DB::PreparedStatement object.

=cut

sub prepared_insert {
    my $self = shift;

    $self->_slave_check;

    my $query = $self->create_query;
    if (@_) {
        my ($data) = $self->_get_data4insert(args2array @_);
        $query->insert($data);
        return $self->{dbc}->prepared_statement($query->insert($data));
    }
    else {
        keys %{$self->{data}} < 1 and return; 
        return $self->{dbc}->prepared_statement($query->insert($self->{data}));
    }
}

=head2 @data or $result_set = match($cols, $targets, $word)

For search of FULLTEXT INDEX(MySQL Only).

 # SELECT * FROM ANY_TABLE WHERE MATCH(title) AGAINST('blah') 
 $search->match_dump('title', 'blah');
 
 # SELECT * FROM ANY_TABLE WHERE MATCH(title,description,comment) AGAINST('*W1,2 blah' IN BOOLEAN MODE) 
 $search->match_dump(
     [qw(title description comment)],
     [qw(title description)],
     'blah'
 );

=cut

sub match {
    my $self = shift;
    my ($cols, $targets, $word) = @_;

    if (scalar @_ < 3) { return $self->select(-match_against => [ @_ ]); }
    elsif (ref $cols and @$cols > 0) {
        return $self->select(-match_against_boolean  => [ @$cols, against($cols, $targets, $word) ]);
    }
    else {
        return $self->select(-match_against => [ @$cols, against($cols, $targets, $word) ]);
    }
}

sub match_dump {
    my $self = shift;
    my ($cols, $targets, $word) = @_;

    if (scalar @_ < 3) { return $self->select_dump(-match_against => [ @_ ]); }
    elsif (ref $cols and @$cols > 0) {
        return $self->select_dump(-match_against_boolean  => [ @$cols, against($cols, $targets, $word) ]);
    }
    else {
        return $self->select_dump(-match_against => [ @$cols, against($cols, $targets, $word) ]);
    }
}

sub table_status {
    my $self = shift;

    my $query = $self->create_query;
    return $self->{dbc}->execute($query->table_status);
}

sub count_from_table_status {
    my $self = shift;

    my $query = $self->create_query;
    my $rs = $self->{dbc}->execute($query->table_status);
    $rs->next or return 0;
    return $rs->get('Rows');
}

=head2 $id = get_insert_id

Returns id(primary key) inserted at last.

=cut

sub get_insert_id {
    my $self = shift;

    my $dbc = $self->{dbc};
    if ($dbc->{type} == DB_TYPE_MYSQL) {
        return $dbc->{dbh}{mysql_insertid};
    }
    elsif ($dbc->{type} == DB_TYPE_ODBC_MYSQL) {
        my $rs = $self->{dbc}->execute(<<EOS);
SELECT LAST_INSERT_ID();
EOS
        $rs->next;
        my $data = $rs->data;
        return $data->{'LAST_INSERT_ID()'};
    }
    elsif ($dbc->{type} == DB_TYPE_POSTGRESQL) {
        return $dbc->{dbh}->last_insert_id(undef, undef, $self->{table}, undef);
    }
}

=head2 $id = get_insert_data

Returns data inserted at last.

=cut

sub get_insert_data {
    my $self = shift;
    my $column = shift;

    $column ||= 'id';
    return $self->retrieve($column => $self->get_insert_id);
}

sub insert_or_update {
    my $self = shift;
    my ($where) = args2hash(@_);
    my $data = $self->retrieve($where);
    if ($data) { return $self->update($where); }
    else { return $self->insert; }
}

=head2 $lines = update(@args)

Executes query and it returns the number of influenced lines.
@args is same value for Wiz::DB::SQL::Query::update.

=cut

sub update {
    my $self = shift;
    my $where = @_ ? args2hash @_ : undef;

    if (!$where) {
        $where = {
            $self->{primary_key} => $self->get($self->{primary_key}),
        };
    }
    $self->_slave_check;
    if ($self->use_cache) {
        $self->{dbc}->cache->delete($self->get_cache_key(@_));
    }
    keys %{$self->{data}} < 1 and return;
    my $query = $self->create_query;
    return $self->{dbc}->execute_only(
            $query->update(data => $self->{data}, where => $where), $query->values);
}

=head2 update_dump($columns, $where)

Returns query values already binded(for debug).

=cut

sub update_dump {
    my $self = shift;
    my $where = args2hash @_;
    if (!$where) {
        $where = {
            $self->{primary_key} => $self->get($self->{primary_key}),
        };
    }
    my $query = $self->create_query;
    return $query->update_dump(data => $self->{data}, where => $where);
}

=head2 prepared_update($columns, $where)

Returns Wiz::DB::PreparedStatement object.

=cut

sub prepared_update {
    my $self = shift;

    $self->_slave_check;
    my $query = $self->create_query;
    my ($field, $where) = ([], []);
    if (ref $_[0] eq 'ARRAY') {
        ($field, $where) = @_;
    }
    else {
        my %args = @_;
        ($field, $where) = ($args{fields}, $args{where});
    }
    return $self->{dbc}->prepared_statement(
        $query->update(
            data => { map { $_ => undef } @$field },
            where => { map { $_ => undef } @$where }));
}

=head2 delete($columns, $where)

Executes query and it returns the number of influenced lines.
@args is same value for Wiz::DB::SQL::Query::delete.

=cut

sub delete {
    my $self = shift;
    my $where = args2hash @_;

    if (!$where) {
        $where = {
            $self->{primary_key} => $self->get($self->{primary_key}),
        };
    }
    $self->_slave_check;
    if ($self->use_cache) {
        $self->{dbc}->cache->delete($self->get_cache_key(@_));
    }
    my $query = $self->create_query;
    return $self->{dbc}->execute_only($query->delete(@_), $query->values);
}

=head2 delete_dump($columns, $where)

Returns query values already binded(for debug).

=cut

sub delete_dump {
    my $self = shift;
    my $where = args2hash @_;

    if (!$where) {
        $where = {
            $self->{primary_key} => $self->get($self->{primary_key}),
        };
    }
    $self->create_query->delete_dump(where => $where);
}

=head2 $prepared_statement = prepared_delete(@args)

Returns Wiz::DB::PreparedStatement object.

=cut

sub prepared_delete {
    my $self = shift;
    my $query = defined $self->{query} ? $self->{query} : $self->create_query;
    $self->{dbc}->prepared_statement($query->delete(@_));
}

=head2 force_delete

Not need primary key but  not support memcached.

=cut

sub force_delete {
    my $self = shift;
    my $where = args2hash @_;

    $self->_slave_check;
    my $query = $self->create_query;
    $query->where($where);
    return $self->{dbc}->execute_only($query->force_delete, $query->values);
}

=head2 execute($query)

Direct executes the query and returns the ResultSet object.

=cut

sub execute {
    my $self = shift;
    return $self->{dbc}->execute(@_);
}

=head2 execute_only($query)

Direct executes the query and returns none.

=cut

sub execute_only {
    my $self = shift;
    return $self->{dbc}->execute_only(@_);
}

=head2 prepared_statement($query)

Makes PreparedStatement object and returns it.

=cut

sub prepared_statement {
    my $self = shift;
    return $self->{dbc}->prepared_statement(@_);
}

=head2 auto_commit($flag)

Sets the flag of the auto commit.

=cut

sub auto_commit {
    my $self = shift;
    return $self->{dbc}->auto_commit(shift);
}

=head2 commit

=cut

sub commit {
    my $self = shift;

    $self->_slave_check;
    return $self->{dbc}->commit;
}

=head2 rollback

=cut

sub rollback {
    my $self = shift;

    $self->_slave_check;
    return $self->{dbc}->rollback(shift);
}

=head2 store($data)

Copies data to this instance holding values.

=cut

sub store {
    my $self = shift;
    my ($data) = @_;
    for (keys %$data) {
        $self->set($_ => $data->{$_});
    }
}

=head2 join(@args)

Use join clause.

=cut

sub join {
    my $self = shift;
    my $args = args2array @_;

    if (ref $args->[$#$args] eq 'HASH') {
        _generate_alias($args, $args->[$#$args]);
    }
    else {
        my %alias = ();
        _generate_alias($args, \%alias);
        %alias and push @$args, \%alias;
    }

    my $query = $self->create_query;

    _join_args_init($args);

    $query->join($args);
    $self->{query} = $query;
}

=head2 $data_io = cluster_data_io($table, undef or $cluster_group)

=cut

sub init_cluster_data_io {
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

sub _cluster_data_io {
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
        my $label_data = $self->retrieve($key);
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
    return new Wiz::DB::DataIO($child, $table);
}

sub cluster_data_io {
    shift->_cluster_data_io(@_);
}

sub cluster_master_model {
    shift->_cluster_data_io(@_, MASTER);
}

sub cluster_slave_model {
    shift->_cluster_data_io(@_, SLAVE);
}

=head2 $data_io = cluster_data_io_with_commit($table, undef or $cluster_group)

=cut

sub cluster_data_io_with_commit {
    my $self = shift;
    $self->cluster_data_io(@_);
    $self->commit;
}

=head2 $primary_key = primary_key

Set or return primary keys.

primary_key('id');
primary_key('id', 'id2');
primary_key([ 'id', 'id2' ]);

=cut

sub primary_key {
    my $self = shift;
    if (@_) { $self->{primary_key} = @_ > 1 ? [@_] : $_[0]; }
    return $self->{primary_key};
}

=head2 $cache_key = get_cache_key

Returns key value for cache.

=cut

sub primary_key4cache {
    my $self = shift;
    if (@_) { $self->{primary_key4cache} = @_ > 1 ? [@_] : $_[0]; }
    return $self->{primary_key4cache} || $self->primary_key;
}

sub get_cache_key {
    my $self = shift;
    my ($args) = args2hash(@_);
    my $primary_key = $self->primary_key4cache;
    if (ref $primary_key) {
        my @primary_data = ();
        for (@$primary_key) {
            push @primary_data, $args->{$_};
        }
        return sprintf '%s::%s::%s', $self->label, $self->table, CORE::join '::', @primary_data;
    }
    else {
        return sprintf '%s::%s::%s', $self->label, $self->table, $args->{$primary_key};
    }
    return undef;
}

=head2 remove_cache

Remove cache data.

$self->remove_cache($self->get_cache_key(id => 1));

=cut

sub remove_cache {
    my $self = shift;
    $self->{dbc}->cache->delete(@_);
}

=head2 remove_cache_with_key

Remove cache data.

$self->remove_cache_with_key(id => 1);

=cut

sub remove_cache_with_key {
    my $self = shift;
    $self->{dbc}->cache->delete($self->get_cache_key(@_));
}

=head2 dump

Returns this instance holding values for INSERT or UPDATE.

=cut

sub dump {
    my $self = shift;

    my $data = shift;
    for (keys %{$self->{data}}) {
        $data->{$_} = $self->{data}{$_};
    }
}

sub has_error {
    my $self = shift;
    $self->{dbc}->has_error;
}

sub error {
    my $self = shift;
    $self->{dbc}->error;
}

sub label {
    shift->{dbc}->label;
}

sub is_slave {
    my $self = shift;
    $self->{dbc}{is_slave}
}

sub is_same_cluster {
    my $self = shift;
    my ($target) = @_;
    $self->{dbc}->label eq $target->{dbc}->label ? TRUE : FALSE;
}

#---- [ private ]------------------------------------------------------
sub _slave_check {
    my $self = shift;
    if ($self->{dbc}{is_slave}) {
        $self->{dbc}->write_error("this connection is slave. you must not insert.");
    }
}

sub _get_data4insert {
    my $self = shift;
    my ($args) = @_;

    my $data = $args->[0] eq 'data' ? $args->[1] : $args;
    return { map { $_ => undef } @$data };
}

#---- [ private static ]-----------------------------------------------
sub _generate_alias {
    my ($args, $alias) = @_;

    for (@$args) {
        my $r = ref $_;
        if (blessed $_ and $_->isa(__PACKAGE__)) {
            defined $_->alias and
                (exists $alias->{$_->table} or ($alias->{$_->table} = $_->alias));
        }
        elsif ($r eq 'ARRAY') {
            _generate_alias($_, $alias);
        }
    }
}

sub _join_args_init {
    my ($args) = @_;

    for (@$args) {
        if (blessed $_) {
            if ($_->isa('Wiz::DB::DataIO')) {
                $_ = [ $_ => $_->primary_key ];
            }
        }
        elsif (ref $_ eq 'ARRAY') {
            if ($_->[0] =~ /^\d*$/) {
                _join_args_init($_);
            }
        }
    }
}

=head1 SEE ALSO

L<Wiz::DB::ResultSet>, L<Wiz::DB::PreparedStatement>, 
L<Wiz::DB::SQL::Query>, L<Wiz::DB::SQL::Where>

=head1 AUTHOR

Junichiro NAKAMURA, C<< <jyun16@gmail.com> >>

=head1 COPYRIGHT & LICENSE

Copyright 2008 The Wiz Project. All rights reserved.

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

