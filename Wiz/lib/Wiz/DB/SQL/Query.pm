package Wiz::DB::SQL::Query;

use strict;

=head1 NAME

Wiz::DB::SQL::Query - Generate SQL from Perl data structures

=head1 VERSION

version 1.0

=cut

our $VERSION = '1.0';

=head1 SYNOPSIS

 use Wiz::DB::SQL::Query;
 use Wiz::DB::Constant qw(:common);
 
 my $query = new Wiz::DB::SQL::Query(type => DB_TYPE_MYSQL, table => 'TABLE_NAME');

=head2 COUNT

 $query->count;

The above will give you the following query.

 SELECT COUNT(*) AS COUNT FROM TABLE_NAME

If you want to specify count target field and where clause, do the following.

 # SELECT COUNT(hoge) AS COUNT FROM TABLE_NAME WHERE id=?
 $query->count(fields => 'hoge', where => { id => 'xxx' })

If you want to get the values to bind

 $query->values

In the case, you can get

 [qw(xxx)]

The value of 'where' is equal to the value to give constructor of Wiz::DB::SQL::Where.

 $query->count(fields => 'hoge', where => new Wiz::DB::SQL::Where::MySQL({ id => 'xxx' }))

In the case too, the same value is returned.

You can give this function Wiz::DB::SQL::Where's instance.

 $query->count(new Wiz::DB::SQL::Where::MySQL({ id => 'xxx' }))

=head2 SELECT

 # SELECT * FROM TABLE_NAME
 $query->select;
 
 # SELECT hoge FROM TABLE_NAME WHERE id=?
 $query->select(fields => 'hoge', where => { id => 'xxx' });
 
 # SELECT hoge,fuga FROM TABLE_NAME WHERE id=?
 $query->select(fields => ['hoge', 'fuga'], where => { id => 'xxx' });

=head2 INSERT

 # INSERT INTO TABLE_NAME (fuga,hoge) VALUES (?,?)
 $query->insert(data => { hoge => 'HOGE', fuga => 'FUGA' });
 
 # INSERT INTO TABLE_NAME (fuga,hoge) VALUES (?,?)
 $query->insert(hoge => 'HOGE', fuga => 'FUGA');
 
 # INSERT INTO TABLE_NAME (foo,bar) VALUES (?,?)
 $query->clear;
 $query->set(foo => 'FOO');
 $query->set(bar => 'BAR');
 $query->insert;

The method "clear" delete the value holded by this instance.
If you have already called 

 # INSERT INTO TABLE_NAME (foo,bar) VALUES (?,?)
 $query->insert([ hoge => 'HOGE', fuga => 'FUGA' ]);
 
 # [qw(FUGA HOGE)]
 $query->values;
 
=head2 UPDATE

 # UPDATE $conf{table} SET (foo=?,bar=?) WHERE id=?
 $query->update(data => { 'hoge' => 'HOGE', fuga => 'FUGA' }, where => { id => 1 });
 
 # UPDATE TABLE_NAME SET (foo=?,bar=?) WHERE id=?
 $query->update(data => [ 'hoge' => 'HOGE', fuga => 'FUGA' ], where => { id => 1 });
 
 # [qw(HOGE FUGA 1)]
 $query->values
 
 # UPDATE TABLE_NAME SET (foo=?,bar=?) WHERE id=?
 $query->clear;
 $query->set(foo => 'FOO');
 $query->set(bar => 'BAR');
 $query->update(id => 1);
 
=head2 DELETE

 # DELETE FROM TABLE_NAME WHERE id=?
 $query->delete(where => { id => 'xxx' });
 
 # DELETE FROM TABLE_NAME WHERE id=?
 $query->delete({ id => 'xxx' });
 
 # DELETE FROM TABLE_NAME WHERE id=?
 $query->delete(id => 'xxx');
 
 # DELETE FROM TABLE_NAME WHERE id=?
 $query->delete(new Wiz::DB::SQL::Where({ id => 'xxx' }));
 
 # [qw(xxx)]
 $query->values;

=head2 CROSS JOIN

 # SELECT * FROM hoge CROSS JOIN fuga
 $query->join(CROSS_JOIN, hoge => 'fuga');

With alias: 
 
 # SELECT * FROM hoge h CROSS JOIN fuga f 
 $query->join(
     [ CROSS_JOIN, hoge => 'fuga' ],
     {
         hoge    => 'h',
         fuga    => 'f',
     },
 );

=head2 INNER JOIN, OUTER JOIN

 # SELECT * FROM hoge INNER JOIN fuga ON hoge.fuga_id=fuga.id
 $query->join(INNER_JOIN, 'hoge.fuga_id' => 'fuga.id');
 
 # SELECT * FROM hoge LEFT JOIN fuga ON hoge.fuga_id=fuga.id
 $query->join(LEFT_JOIN, 'hoge.fuga_id' => 'fuga.id');
 
 # SELECT * FROM hoge RIGHT JOIN fuga ON hoge.fuga_id=fuga.id
 $query->join(RIGHT_JOIN, 'hoge.fuga_id' => 'fuga.id');
 
 # SELECT * FROM hoge h INNER JOIN fuga f ON h.fuga_id=f.id
 $query->join([ INNER_JOIN, 'hoge.fuga_id' => 'fuga.id' ], { hoge => 'h', fuga => 'f', })
 
 # SELECT * FROM ((hoge INNER JOIN fuga ON hoge.fuga_id=fuga.id) LEFT JOIN bar ON hoge.bar_id=bar.id) RIGHT JOIN xxx ON hoge.xxx_id=xxx.id 
 $query->join(
     [ INNER_JOIN, 'hoge.fuga_id' => 'fuga.id' ],
     [ LEFT_JOIN, 'hoge.bar_id' => 'bar.id' ],
     [ RIGHT_JOIN, 'hoge.xxx_id' => 'xxx.id' ],
 );
 
 # SELECT * FROM ((hoge INNER JOIN fuga ON hoge.fuga_id=fuga.id) LEFT JOIN bar ON hoge.bar_id=bar.id) RIGHT JOIN xxx ON hoge.xxx_id=xxx.id
 $query->join(
     [ INNER_JOIN, 'hoge.fuga_id' => 'fuga.id' ],
     [ LEFT_JOIN, 'hoge.bar_id' => 'bar.id' ],
     [ RIGHT_JOIN, 'hoge.xxx_id' => 'xxx.id' ],
     {
         hoge    => 'h',
         fuga    => 'f',
         bar     => 'b',
         xxx     => 'x',
     },
 );
 
 # SELECT * FROM ((hoge h INNER JOIN fuga f ON h.fuga_id=f.id) LEFT JOIN bar b ON h.bar_id=b.id) RIGHT JOIN xxx x ON h.xxx_id=x.id
 $query->join(
     [ INNER_JOIN, '-and',
         [ 'hoge.fuga_id' => 'fuga.id' ],
         [ 'hoge.name' => IS_NULL ],
         [ '!=', 'fuga.name' => \"a'aa" ],
     ],
 );

 # SELECT * FROM hoge INNER JOIN fuga ON hoge.fuga_id=fuga.id AND hoge.name!=fuga.name AND (hoge.age=fuga
 .age OR hoge.type!=fuga.type)
 $query->join(
     [ INNER_JOIN, '-and',
         [ 'hoge.fuga_id' => 'fuga.id' ],
         [ '!=', 'hoge.name' => 'fuga.name' ],
         [ '-or',
             [ 'hoge.age' => 'fuga.age' ],
             [ '!=', 'hoge.type' => 'fuga.type' ],
         ],
     ],
 );
 
 # SELECT * FROM (hoge h INNER JOIN fuga f ON h.fuga_id=f.id) LEFT JOIN bar b ON h.bar_id=b.id
 $query->join(
     [ INNER_JOIN, '-and',
         [ 'hoge.fuga_id' => 'fuga.id' ],
     ],
     [ LEFT_JOIN, 'hoge.bar_id' => 'bar.id' ],
     {
         hoge    => 'h',
         fuga    => 'f',
         bar     => 'b',
     },
 );
 
 # SELECT * FROM (hoge h INNER JOIN fuga f ON h.fuga_id=f.id AND h.name!=f.name AND (h.age=f.age OR h.type not like 'fuga.type')) LEFT JOIN bar b ON h.bar_id=b.id
 $query->join(
     [ INNER_JOIN, '-and',
         [ 'hoge.fuga_id' => 'fuga.id' ],
         [ '!=', 'hoge.name' => 'fuga.name' ],
         [ '-or',
             [ 'hoge.age' => 'fuga.age' ],
             [ 'not like', 'hoge.type' => \'fuga.type' ],
         ],
     ],
     [ LEFT_JOIN, 'hoge.bar_id' => 'bar.id' ],
     {
         hoge    => 'h',
         fuga    => 'f',
         bar     => 'b',
     },
 );

=head2 UNION

 my $w1 = new Wiz::DB::SQL::Where::MySQL([ -and => [[ 'like', 'name', '%hoge%' ]]]);
 my $q1 = new Wiz::DB::SQL::Query::MySQL(table => 'hoge', fields => [qw(id)], where => $w1);
 my $q2 = new Wiz::DB::SQL::Query::MySQL(table => 'fuga', fields => [qw(id)], where => $w1);;
 my $w2 = new Wiz::DB::SQL::Where::MySQL({ id => 2 });
 
 # (SELECT id FROM hoge WHERE name like '%hoge%') UNION (SELECT id FROM fuga WHERE name like '%hoge%') WHERE id='2
 union($q1, $q2, $w2),

=head2 SUBQUERY

 my $sub_query = new Wiz::DB::SQL::Query(type => DB_TYPE_MYSQL, table => 'hoge');
 $sub_query->where(new Wiz::DB::SQL::Where({ id => 1 }));
 
 $query->sub_query($sub_query);
 
 # SELECT * FROM (SELECT * FROM hoge WHERE id=?) a
 $query->select;
 
 $query->sub_query($sub_query, 'a')
 
 # SELECT * FROM (SELECT * FROM hoge WHERE id=?) a
 $query->select;

=cut

use Carp qw(confess);
use Scalar::Util qw(blessed);

use base qw(Class::Accessor::Fast);

use Wiz qw(get_hash_args);
use Wiz::ConstantExporter [qw(union)];

use Wiz::Constant qw(:common);
use Wiz::Util::Hash qw(args2hash create_ordered_hash array2ordered_hash);
use Wiz::Util::Array qw(args2array);
use Wiz::DB qw(db_type2class_name sanitize is_sql_operator sql_operator2part is_null_clause);
use Wiz::DB::Constant qw(:common);
use Wiz::DB::SQL::Constant qw(:common);
use Wiz::DB::SQL::Where;
use Wiz::DB::SQL::Where::MySQL;
use Wiz::DB::SQL::Where::PostgreSQL;

=head1 ACCESSORS

 type
 alias
 distinct

=cut

__PACKAGE__->mk_accessors(qw(type alias distinct));

use constant {
    JOIN_NEST_CNT   => 0,
    JOIN_PARTS_NUM  => 1,
    JOIN_LOOP_CNT   => 2,
};

=head1 CONSTRUCTOR

=head2 new(%data or \%data)

 my $query = new Wiz::DB::SQL::Query(table => 'TEXT_TABLE', type => DB_TYPE_MYSQL);

This method can get the following hash keys and values.

 table: table name
 fields: list reference of column's name
 where: WHERE clause string or Wiz::DB::SQL::Where
 type: DATABASE TYPE(Wiz::DB::Constant's DB_TYPE_)

=cut

sub new {
    my $self = shift;
    my $conf = get_hash_args(@_);

    defined $conf->{fields} or $conf->{fields} = [];

    my $pkg_name = __PACKAGE__;
    if (defined $conf->{type}) {
        $pkg_name .= '::' . db_type2class_name($conf->{type});
    }

    my $instance = bless {
        table       => $conf->{table},
        fields      => $conf->{fields},
        alias       => undef,               # for sub query
        data        => undef,
        where       => $conf->{where},
        type        => $conf->{type},
        sub_query   => undef,
        distinct    => FALSE,
        join        => undef,
    }, $pkg_name;

    return $instance;
}

=head1 METHODS

=cut

=head2 table($table or $query)

Accessor of the table name data.

=cut

sub table {
    my $self = shift;

    if (@_) { $self->{table} = shift; $self->{alias} = shift; }
    return $self->{sub_query} ? 
        '(' . $self->{sub_query}->select . ')' . (defined $self->{alias} and " $self->{alias}") : 
            defined $self->{join} ? $self->{join} : $self->{table};
}

=head2 sub_query($sub_query, $alias)

Accessor of the data for sub_query.

=cut

sub sub_query {
    my $self = shift;
    my ($sub_query, $alias) = @_;

    defined $sub_query and $self->{sub_query} = $sub_query;
    defined $alias and $self->{alias} = $alias;

    return defined $self->{sub_query} ?
            '(' . $self->{sub_query}->select . ')' . 
            (defined $self->{alias} and ' ' . $self->{alias}) : '';
}

=head2 where(@args or $where)
h


Accessor of the where data.

$args, @args is the data for Wiz::DB::SQL::Where.
$where is Wiz::DB::SQL::Where.

=cut

sub where {
    my $self = shift;
    my ($param) = args2hash @_;
    if (defined $param) {
        if (blessed $_[0] and $_[0]->isa('Wiz::DB::SQL::Where')) {
            $self->{where} = $_[0];
        }
        else {
            $self->{where} = new Wiz::DB::SQL::Where($param);
        }
        $self->{where}->type($self->{type});
    }
    return $self->{where};
}

=head2 type($db_type)

Set DB_TYPE into the instance.

=cut

sub type {
    my $self = shift;
    my ($type) = @_;
    $self->{type} = $type;
    my $class_name = db_type2class_name($self->{type});
    if ($class_name) {
        bless $self, __PACKAGE__ . '::' . $class_name;
    }
    if (defined $self->{where}) {
        $self->{where}->type($self->{type});
    }
    return $self->{type};
}

=head2 fields(\@args or @args)

Accessor of fields.

=cut

sub fields {
    my $self = shift;
    my $args = args2array(@_);

    if (defined $args)  {
        $self->{fields} = $args;
    }

    return $self->{fields};
}

=head2 set(\%args or %args)

Set query data.

=cut

sub set {
    my $self = shift;
    my $args = args2hash(@_);

    defined $self->{data} or $self->{data} = create_ordered_hash;
    for (keys %$args) {
        $self->{data}{$_} = $args->{$_};
    }
}

=head2 get($field)

Returns the data of $field.

=cut

sub get {
    my $self = shift;

    defined $self->{data} or return undef;
    return $self->{data}{+shift};
}

=head2 remove($field)

Delete the data of $field.

=cut

sub remove {
    my $self = shift;

    defined $self->{data} or return undef;
    delete $self->{data}{+shift};
}

=head2 clear

Delete all data owned by the instance.

=cut

sub clear {
    my $self = shift;

    $self->{data} = undef;
    $self->{fields} = [];
    $self->{alias} = undef;
    $self->{where} = undef;
    $self->{sub_query} = undef;
    $self->{distinct} = FALSE;
}

=head2 set_data($data or \%data or \@data)

=cut

sub set_data {
    my $self = shift;
    my ($data) = @_;

    my $r = ref $data;
    if ($r eq 'HASH') {
        $self->{data} = $data;
    }
    elsif ($r eq 'ARRAY') {
        $self->{data} = array2ordered_hash $data;
    }
}

=head2 exists($field)

Returns TRUE when $field data exists.

=cut

sub exists {
    my $self = shift;

    defined $self->{data} or return FALSE;
    exists $self->{data}{+shift};
}

=head2 count

Returns count query with place holder.

=cut

sub count {
    my $self = shift;
    return $self->_count(
        $self->_get_params4count_and_select(ref $_[0] eq 'ARRAY' ? @_ : args2hash @_));
}

=head2 count_dump

Returns count query(for debug).

=cut

sub count_dump {
    my $self = shift;
    return $self->_count(
        $self->_get_params4count_and_select(ref $_[0] eq 'ARRAY' ? @_ : args2hash @_), TRUE);
}

=head2 select

Returns select query with place holder.

=cut

sub select {
    my $self = shift;
    return $self->_select(
        $self->_get_params4count_and_select(ref $_[0] eq 'ARRAY' ? @_ : args2hash @_));
}

=head2 select_dump

Returns select query(for debug).

=cut

sub select_dump {
    my $self = shift;
    return $self->_select(
        $self->_get_params4count_and_select(ref $_[0] eq 'ARRAY' ? @_ : args2hash @_), TRUE);
}

=head2 insert

Returns insert query with place holder.

=cut

sub insert {
    my $self = shift;
    my ($values) = $self->_get_params4insert(args2hash @_);
    $values or return;
    $self->_exists_self_tablename;
    my $m = _scalar_ref_map($values);
    my $n = @$values;
    my $query = 'INSERT INTO ' . $self->table;
    $query .= ' (' . sanitize($values->[0]);
    for (my $i = 2; $i < $n; $i+=2) { $query .= ',' . sanitize($values->[$i]) }
    $query .= ') VALUES (' . join ',', map { exists $m->{$_} ? $m->{$_} : '?' } (0..($n / 2 - 1));
    return $query . ')';
}

=head2 insert_dump

Returns insert query(for debug).

=cut

sub insert_dump {
    my $self = shift;
    my ($values) = $self->_get_params4insert(args2hash @_);
    $values or return;
    $self->_exists_self_tablename;
    my $m = _scalar_ref_map($values);
    my $query = 'INSERT INTO ' . $self->table;
    my $n = @$values;
    $query .= " ($values->[0]";
    for (my $i = 2; $i < $n; $i+=2) { $query .= ",$values->[$i]" }
    $query .= ') VALUES (' . join ',',
        map { exists $m->{$_} ? "'" . $m->{$_} . "'" : "'" . $values->[$_*2+1] . "'" } (0..($n / 2 - 1));
    return $query . ')';
}

=head2 update

Returns update query with place holder.

=cut

sub update {
    my $self = shift;
    my ($values, $where) = $self->_get_params4update(args2hash @_);
    $self->_exists_self_tablename;
    my $m = _scalar_ref_map($values);
    my $query = 'UPDATE ' . $self->table . ' SET ';
    my $n = @$values;
    $query .= join ',', map { sanitize($values->[$_*2]) . '=' . (exists $m->{$_} ? $m->{$_} : '?') } (0..($n / 2 - 1));
    if ($where) { $query .= ' ' . $where->to_string; $self->{where} = $where; }
    return $query;
}

=head2 update_dump

Returns update query(for debug).

=cut

sub update_dump {
    my $self = shift;
    my ($values, $where) = $self->_get_params4update(args2hash @_);
    $self->_exists_self_tablename;
    my $m = _scalar_ref_map($values);
    my $query = 'UPDATE ' . $self->table . ' SET ';
    my $n = @$values;
    $query .= join ',', map {
        sanitize($values->[$_*2]) . '=' . (exists $m->{$_} ? $m->{$_} : "'" . sanitize($values->[$_*2+1]) . "'")
    } (0..($n / 2 - 1));
    if ($where) { $query .= ' ' . $where->to_exstring; $self->{where} = $where; }

    return $query;
}

=head2 delete

Returns delete query with place holder.

=cut

sub delete {
    my $self = shift;
    return $self->_delete($self->_get_params4delete(args2hash @_));
}

=head2 delete_dump

Returns delete query(for debug).

=cut

sub delete_dump {
    my $self = shift;
    return $self->_delete($self->_get_params4delete(args2hash @_), TRUE);
}

=head2 force_delete

=cut

sub force_delete {
    my $self = shift;
    my ($where) = args2hash @_;

    $where = $self->where($where);

    $self->_exists_self_tablename;
    my $query = 'DELETE FROM ' . $self->table;
    $where and $query .= ' ' . $where->to_string;

    return $query;
}

=head2 truncate

Retruns truncate query.

=cut

sub truncate {
    my $self = shift;

    $self->_exists_self_tablename;
    return 'TRUNCATE ' . $self->table;
}

=head2 join(\@args or @args)

Accessor of the data for join.

=cut

sub join {
    my $self = shift;
    my $args = args2array @_;

    my $join = undef;
    my $alias = pop @$args if ref $args->[$#$args] eq 'HASH';
    if (ref $args->[0]) {
        my $cnt = [ 0, $#$args, 0 ];
        my $i = 0;
        for (@$args) {
            $cnt->[JOIN_LOOP_CNT] = $i;
            $join .= $self->_join($_, $alias, $cnt);
            ++$i
        }
    }
    else { $join = $self->_join($args, $alias, [0,0,0]); }
    $self->{join} = $join;
}

=head2 values

Returns the data to bind with place holder.

=cut

sub values {
    my $self = shift;

    my @ret = ();
    if ($self->{data}) {
        for (values %{$self->{data}}) {
            ref $_ or push @ret, $_;
        }
    }
    if ($self->{where}) {
        push @ret, @{$self->{where}->values};
    }
    return @ret ? \@ret : undef;
}

=head2 clean_where

Delete the data for where.

=cut

sub clean_where {
    my $self = shift;
    $self->{where} = undef;
}

#----[ static ]-------------------------------------------------------

=head2 union(@queries)

Returns the query unioned.

=cut

sub union {
    my @ret = ();
    my $where = undef;
    if ((ref $_[$#_]) =~ /^Wiz::DB::SQL::Where/) {
        $where = pop @_;
    }

    for (@_) { push @ret, '(' . $_->select_dump . ')'; }
    return (CORE::join ' UNION ', @ret) . 
        (defined $where ? ' ' . $where->to_exstring : '');
}

#----[ private ]------------------------------------------------------
sub _count {
    my $self = shift;
    my ($fields, $where, $exflag) = @_;

    $self->_exists_self_tablename;

    my $query = 'SELECT COUNT(' .
        (@$fields ? CORE::join ',', map { sanitize($_) } @$fields : '*') .
        ') AS count FROM ' . $self->table;

    if ($where) {
        my $w = $exflag ? $where->to_exstring4count : $where->to_string4count;
        $w and $query .= ' ' . $w;
        $self->{where} = $where;
    } 

    return $query;
}

sub _select {
    my $self = shift;
    my ($fields, $where, $exflag) = @_;

    $self->_exists_self_tablename;
    my $query ='SELECT ' . ($self->{distinct} ? 'DISTINCT ' : '') .
        (@$fields ? CORE::join ',', map { ref $_ ? $$_ : sanitize($_) } @$fields : '*') . 
        ' FROM ' . $self->table;
    if ($where) {
        $query .= ' ' .  ($exflag ? $where->to_exstring : $where->to_string);
        $self->{where} = $where;
    }

    return $query;
}

sub _delete {
    my $self = shift;
    my ($where, $exflag) = @_;

    $self->_exists_self_tablename;

    defined $where or confess "delete can't execute without where clause";

    my $query = 'DELETE FROM ' . $self->table . ' ' . 
        ($exflag ? $where->to_exstring : $where->to_string);
    $self->{where} = $where;

    return $query;
}

sub _join {
    my $self = shift;
    my ($args, $alias, $cnt) = @_;

    my $type = shift @$args;
    if ($type == CROSS_JOIN) { return $self->_cross_join($args, $alias); }
    else {
        return $self->_any_join($args, $alias, $type, $cnt);
    }
}

sub _any_join {
    my $self = shift;
    my ($args, $alias, $type, $cnt, $ignore_on) = @_;

    my $ret = '';
    if (not $ignore_on and $cnt->[JOIN_LOOP_CNT] == 0) {
        $ret = '(' x $cnt->[JOIN_PARTS_NUM];
    }

    if ($type == DIRECT_JOIN) {
        if ($cnt->[JOIN_LOOP_CNT] == 0) {
            $ret .= $self->table;
        }
        $ret .= " $args->[0]";
        ++($cnt->[JOIN_NEST_CNT]);
    }
    elsif ($args->[0] =~ /^-/) {
        $ret .= $self->_any_join($args->[1], $alias, $type, $cnt, TRUE);
        $ret .= ' ON ' . $self->_any_join_and_or($args, $alias);
        ++($cnt->[JOIN_NEST_CNT]);
    }
    elsif (ref $args->[0] and $args->[0][0] =~ /^-/) {
        $ret .= $self->_any_join($args->[0][1], $alias, $type, $cnt, TRUE);
        $ret .= ' ON ' . $self->_any_join_and_or($args->[0], $alias);
        ++($cnt->[JOIN_NEST_CNT]);
    }
    else {
        $args->[0] = _replace_included_dataio($args->[0]);
        $args->[1] = _replace_included_dataio($args->[1]);

        $cnt->[JOIN_LOOP_CNT] or $ret .= _table_alias($args->[0], $alias);
        $ret .= _join_type2label($type) . _table_alias($args->[1], $alias);
        $ignore_on or $ret .= ' ON ' . _replace_join_field($args->[0], $alias) . '=' . 
            _replace_join_field($args->[1], $alias);
        $ignore_on or ++($cnt->[JOIN_NEST_CNT]);
    }

    if (not $ignore_on) {
        if ($cnt->[JOIN_NEST_CNT]) {
            $cnt->[JOIN_NEST_CNT] <= $cnt->[JOIN_PARTS_NUM] and $ret .= ')';
        }
        else {
            $cnt->[JOIN_PARTS_NUM] > 0 and
                $ret = '(' x ($cnt->[JOIN_PARTS_NUM] - $cnt->[JOIN_NEST_CNT]) . $ret . ')';
        }
    }

    return $ret;
}

sub _any_join_and_or {
    my $self = shift;
    my ($args, $alias) = @_;

    my ($delimiter) = (shift @$args) =~ /^-(.*)/;
    $delimiter = ' ' . uc $delimiter . ' ';
    my @ret = ();
    for (@$args) {
        if ($_->[0] =~ /^-/) {
            push @ret, '(' . $self->_any_join_and_or($_, $alias) . ')';
        }
        else {
            $self->__any_join_and_or($_, $alias, \@ret);
        }
    }

    return CORE::join $delimiter, @ret;
}

sub __any_join_and_or {
    my $self = shift;
    my ($args, $alias, $ret) = @_;

    if (ref $args->[1] eq 'CODE') { push @$ret, is_null_clause($args->[0], $args->[1]); }
    else {
        my $ope = is_sql_operator($args->[0]) ? (shift @$args) : '=';
        push @$ret, _replace_join_field($args->[0], $alias) . sql_operator2part($ope) .
            _replace_join_field($args->[1], $alias);
    }
}

sub _exists_self_tablename {
    my $self = shift;
    defined $self->{table} or confess "table name isn't defined";
}

sub _modify_fields {
    my ($self, $fields) = @_;
    if (ref $fields eq 'HASH') {
        my @fields;
        foreach my $t (keys %$fields) {
            push @fields, map $t . '.' . $_ . ' AS ' . $t . '_' . $_,
                (ref $fields->{$t} ? @{$fields->{$t}} : $fields->{$t});
        }
        return @fields;
    } elsif (ref $fields eq 'ARRAY') {
        my @fields = map {
            $self->_modify_fields($_);
        } @$fields;
        return @fields;
    } else {
        return $fields;
    }
}

sub _get_params4count_and_select {
    my $self = shift;
    my ($args) = @_;

    my ($fields, $where) = ($self->{fields}, $self->{where});
    if (ref $args eq 'HASH' and $args->{fields}) {
        $args->{fields} = [$self->_modify_fields($args->{fields})];
        push @$fields, ref $args->{fields} ? @{$args->{fields}} : $args->{fields};
        $self->{fields} = $fields;
        if (defined $args->{where}) {
            my $where_class = $self->get_where_class;
            $where = _is_wiz_db_where($args->{where}) ?
                $args->{where} : $where_class->new($args->{where});
            $self->{where} = $where;
        }
    }
    elsif (defined $args) {
        $where = $self->_get_where_from_args($args);
        $self->{where} = $where;
    }

    if (defined $where) {
        $where->{type} or $where->type($self->{type});
    }

    return ($fields, $where);
}

sub _get_params4insert {
    my $self = shift;
    my ($args) = @_;

    if (ref $args->{data}) {
        $self->set_data($args->{data});
        return $self->_get_data($args->{data});
    }
    else {
        %$args and $self->set_data($args);
        return $self->_get_data($args);
    }
}

sub _get_data {
    my $self = shift;
    my ($data) = @_;

    my $r = ref $data;
    if ($r eq 'HASH' and %{$data}) {
            my @d = map { $_ => $data->{$_} } keys %$data;
            return \@d;
    }
    elsif ($r eq 'ARRAY' and @$data) {
        return $data;
    }
    else {
        if (defined $self->{data} and %{$self->{data}}) {
            return $self->_get_data($self->{data});
        }
    }
}

sub _get_params4update {
    my $self = shift;
    my ($args) = @_;

    my ($data, $where) = (undef, $self->{where});
    if (ref $args->{data}) {
        $self->set_data($args->{data});
        $data = $self->_get_data($args->{data});
    }
    else {
        $data = $self->_get_data;
    }
    $where = $self->_get_where_from_args($args);
    return ($data, $where);
}

sub _get_params4delete {
    my $self = shift;
    return $self->_get_where_from_args(@_); 
}

sub _get_where_from_args {
    my $self = shift;
    my ($args) = @_;
    defined $args or return undef;
    my $where = undef;
    my $r = ref $args;
    my $where_class = $self->get_where_class;
    if (_is_wiz_db_where($args)) { $where = $args; }
    elsif ($r eq 'HASH') {
        if ($args->{where}) { $where = $where_class->new($args->{where}); }
        elsif (%$args) { $where = $where_class->new($args); }
    }
    elsif ($r eq 'ARRAY') {
        @$args and $where = $where_class->new($args);
    }
    if (defined $where) {
        $where->{type} or $where->type($self->{type});
    }
    return $where;
}

sub get_where_class {
    my $self = shift;
    "Wiz::DB::SQL::Where::" . db_type2class_name($self->{type})
}

#----[ private static ]-----------------------------------------------
sub _replace_included_dataio {
    my ($args) = @_;

    if (ref $args eq 'ARRAY') {
        if (blessed $args->[0] and $args->[0]->isa('Wiz::DB::DataIO')) {
            return $args->[0]->table . '.' . $args->[1];
        }
        else {
            if (ref $args->[0]) {
                return $args;
            }
            else {
                return "$args->[0].$args->[1]";
            }
        }
    }
    else {
        return $args;
    }
}

sub _table_alias {
    my ($field, $alias) = @_;

    my ($t, $a) = _get_tn_and_alias($field, $alias);
    return defined $a ? "$t $a" : $t;
}

sub _replace_join_field {
    my ($field, $alias) = @_;

    my $r = ref $field;
    if ($r eq 'SCALAR') { return "'" . sanitize($$field) . "'"; }
    defined $alias or return $field;
    (my $new_field = $field) =~ s/^(.*)(\..*)$/$2/;
    return exists $alias->{$1} ? $alias->{$1} . $new_field : $field;
}

sub _get_tn_and_alias {
    my ($field, $alias) = @_;

    ref $field and return undef;
    $field =~ /^(.*)\./;
    return exists $alias->{$1} ? ($1, $alias->{$1}) : ($1, undef); 
}

sub _cross_join {
    my $self = shift;
    my ($args, $alias) = @_;

    my $ret = _cross_join_table_alias($args->[0], $alias);
    if (ref $args->[1] eq 'ARRAY') {
        for (@{$args->[1]}) {
            $ret .= _join_type2label(CROSS_JOIN) . _cross_join_table_alias($_, $alias);
        }
    }
    else {
        $ret .= _join_type2label(CROSS_JOIN) . _cross_join_table_alias($args->[1], $alias);
    }
    return $ret;
}

sub _join_type2label {
    my ($type) = @_;

    if ($type == CROSS_JOIN) { return ' CROSS JOIN '; }
    elsif ($type == INNER_JOIN) { return ' INNER JOIN '; }
    elsif ($type == LEFT_JOIN) { return ' LEFT JOIN '; }
    elsif ($type == RIGHT_JOIN) { return ' RIGHT JOIN '; }
}

sub _cross_join_table_alias {
    my ($table_name, $alias) = @_;

    defined $alias or return $table_name;
    exists $alias->{$table_name} or return $table_name;
    return "$table_name " . $alias->{$table_name};
}

sub _is_wiz_db_where {
    my ($arg) = shift;
    my $r = ref $arg;
    return $r =~ /^Wiz::DB/;
}

sub _scalar_ref_map {
    my ($values) = @_;
    my %m = ();
    my $n = @$values;
    for (my $i = 0; $i < $n; $i+=2) {
        ref $values->[$i+1] eq 'SCALAR' and
            $m{$i/2} = ${$values->[$i+1]};
    }
    return \%m;
}

=head1 SEE ALSO

L<Wiz::DB::SQL::Query>

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

