package Wiz::DB::SQL::Where;

use strict;

=head1 NAME

Wiz::DB::SQL::Where - Generate SQL WHERE clause from Perl data structures

=head1 VERSION

version 1.0

=cut

our $VERSION = '1.0';

=head1 SYNOPSIS

This module like the SQL::Abstract.

 use Wiz::DB::SQL::Where;
 
 my $w = new Wiz::DB::SQL::Where(
     -and    => [
         [qw(= hoge HOGE)],
         [qw(!= fuga FUGA)],
     ],
 );
 
 $w->to_string;

The above instance will give you the following.

 WHERE hoge=? AND fuga!=?

If you want to get to bind value, do the following.

 $w->values

Then this method return

 [ 'HOGE', 'FUGA' ]

If you want a query that value is already binded

 # WHERE hoge='HOGE' AND fuga!='FUGA'
 $w->to_exstring;

You can omit the equal operator.

 my $w = new Wiz::DB::SQL::Where(
     -and    => [
         [qw(hoge HOGE)],
         [qw(!= fuga FUGA)],
     ],
 );

You can put the list reference value.

 my $w = new Wiz::DB::SQL::Where([
     -and    => [
         [qw(hoge HOGE)],
         [qw(!= fuga FUGA)],
     ],
 ]);

You Can use set method.

 $w->set(
     -and    => [
         [qw(hoge HOGE)],
         [qw(!= fuga FUGA)],
     ],
 );

And, you can write the following too.

 my $w = new Wiz::DB::SQL::Where(
     {
         hoge    => 'HOGE',
         fuga    => 'FUGA',
     },
 );

That is very simple writing pattern.
If you will use not AND but OR:

 my $w = new Wiz::DB::SQL::Where(
     [
         hoge    => 'HOGE',
         fuga    => 'FUGA',
     ],
 );

As the above, put the data of list reference.

When you use operator, 'IS NULL' clause, then you do that the following.

 my $w = new Wiz::DB::SQL::Where({
     hoge    => ['!=', 'HOGE'],
     fuga    => 'FUGA',
     foo     => IS_NULL,
     bar     => IS_NOT_NULL,
 });

 $w->to_string;     # WHERE bar IS NOT NULL AND fuga=? AND foo IS NULL AND hoge!=?
 $w->to_exstring;   # WHERE bar IS NOT NULL AND fuga='FUGA' AND foo IS NULL AND hoge!='HOGE'

Sanitization is default.

 my $w = new Wiz::DB::SQL::Where(
     -or    => [
         [qw(hoge HO'GE)],
         [qw(!= fuga FU'GA)],
         ['NOT LIKE', 'foo', q|%FO'O%|],
         ['bar', IS_NULL],
     ],
 );
 $w->to_string;     # WHERE hoge like ? OR fuga NOT LIKE ? OR foo IS NULL
 $w->to_exstring;   # WHERE hoge='HO\'GE' OR fuga!='FU\'GA' OR foo NOT LIKE '%FO\'O%' OR bar IS NULL

The following is other pattern.

=head2 BETWEEN

 $w->set(
     '-between' => {
         'hoge' => [ 10, 30 ],
     },
 );

 $w->to_string;     # WHERE hoge BETWEEN ? AND ?

=head2 IN
 
 $w->set(
     -in => {
         'hoge' => [ 10, 20, 30 ],
     },
 );

 $w->to_string;     # WHERE hoge IN(?,?,?)

=head2 NOT IN
 
 $w->set(
     -not_in => {
         'hoge' => [ 10, 20, 30 ],
     },
 );

 $w->to_string;     # WHERE hoge NOT IN(?,?,?)

=head2 LIMIT, ORDER BY, GROUP BY

If you want to use LIMIT, ORDER BY or GROUP BY then

 $w->set(
     -and    => [
         [qw(= hoge HOGE)],
         [qw(!= fuga FUGA)],
     ],
     -limit => [0, 10],
     -order => ['hoge DESC', 'fuga', 'foo DESC', 'bar'],
     -group => [qw(hoge fuga foo bar)],
 );

 # WHERE hoge=? AND fuga!=? ORDER BY hoge DESC,fuga,foo DESC,bar GROUP BY hoge,fuga,foo,bar LIMIT 0,10
 $w->to_string;

Other way,

 $w->set_offset_limit(0, 10);

 $w->set_order('hoge DESC', 'fuga');
 $w->append_order_desc('foo');
 $w->append_order('bar');

 $w->set_group(qw(hoge fuga));
 $w->append_group(qw(foo bar));

=head2 DIRECT VALUE, NULL

 $w->set(-and => [
     ['hoge', \'HOGE' ],
     -in => {
         hoge    => [1, 2, 3, \'NULL'],
     },
 ]);
 $w->to_string       # WHERE hoge=? AND (hoge IN(?,?,?,NULL))
 $w->to_exstring     # WHERE hoge=HOGE AND (hoge IN('1','2','3',NULL))

=head2 LIKE

 $w->set(-and => [
     ['like', 'foo', prelike q|foo%'bar|],
     -in => {
         hoge    => [qw(1 2 3)],
     },
 ]);
 
 $w->to_string; # WHERE foo like ? AND (hoge IN(?,?,?))
 $w->to_exstring; # WHERE foo like 'fu\%\'ga%' AND (hoge IN('1','2','3'))

prelike is return 'foo\%'bar%' in the case.

=head2 IS NULL

 $w->set([
     -and    => [
         [qw(hoge HO'GE)],
         [qw(!= fuga FU'GA)],
         ['NOT LIKE', 'foo', q|%FO'O%|],
         ['bar', IS_NULL],
     ],
 ]);
 
 $w->to_string;     # WHERE hoge=? AND fuga!=? AND foo NOT LIKE ? AND bar IS NULL 

=head2 ONLY ORDER, LIMIT

 $w->set({
     -order  => ['hoge'],
     -limit  => [0, 10],
 });
 
 $w->to_string; # ORDER BY hoge LIMIT 0,10

=head2 NEST

 my $w = new Wiz::DB::SQL::Where::MySQL;
 $w->set(
     -and    => [
         [qw(= hoge HOGE)],
         [qw(!= fuga FUGA)],
         -or    => [
             [qw(= foo FOO)],
             [qw(!= bar BAR)],
             -and    => [
                 [qw(= xxx XXX)],
                 [qw(!= yyy YYY)],
             ],
         ],
         -in => {
             'hoge' => [ 10, 20, 30 ],
         },
     ],
 );

It's a just simple...orz...

=head2 SUBQUERY

 my $w = new Wiz::DB::SQL::Where::MySQL;
 my $foo = new Wiz::DB::SQL::Query::MySQL(table => 'foo');
 my $bar = new Wiz::DB::SQL::Query::MySQL(table => 'bar');
 
 $foo->where({ id => 'FOO' });
 $bar->where({ id => 'BAR' });
 
 $w->set([        -and    => [
         ['foo', $foo],
         ['!=', 'bar', $bar],
     ],
 ]);

 # WHERE foo=(SELECT * FROM foo WHERE id='FOO') AND bar!=(SELECT * FROM bar WHERE id='BAR')
 $w->to_exstring;

=cut

use base qw(Class::Accessor::Fast);

use Scalar::Util qw(blessed);

use Wiz::Constant qw(:common);
use Wiz::Util::Array qw(args2array);
use Wiz::Util::Hash qw(create_ordered_hash);
use Wiz::DB qw(db_type2class_name is_sql_operator sql_operator2part sanitize is_null_clause);
use Wiz::DB::SQL::Constant qw(:common);

=head2 ACCESSOR

 limit
 offset
 order
 group

=cut

__PACKAGE__->mk_accessors(qw(limit offset order group));

=head1 OPERATOR OVERLOAD 

=head2 ""

called to_string method

=cut

use overload '""' => sub {
    my $self = shift;
    return $self->to_string;
};

=head1 CONSTRUCTOR

=head2 new(%data or \%data)

see SYNOPSIS

=cut

sub new {
    my $self = shift;

    my $where_data = [ @_ ];
    my $instance = bless {
        limit           => undef,
        offset          => undef,
        order           => [],
        group           => [],
        where_data      => $where_data,
        where_values    => undef,
    }, $self;
    $instance->create_where_values($where_data);

    return $instance;
}

=head1 METHODS

=cut

=head2 type($db_type)

Set DB_TYPE into the instance.

=cut

sub type {
    my $self = shift;
    my ($type) = @_;

    $self->{type} = $type;
    $self->{type} or return;
    my $class_name = db_type2class_name($self->{type});

    if ($class_name) {
        bless $self, __PACKAGE__ . '::' . $class_name;
    }

    return $self->{type};
}

=head2 set(@args)

Set the where data.
This method clear the data for to create where part owned by itself.

=cut

sub set {
    my $self = shift;
    $self->{where_data} = [ @_ ];
    $self->create_where_values($self->{where_data});
}

=head2 set_offset_limit($offset, $limit)
=head2 set_offset_limit($limit)

=cut

sub set_offset_limit {
    my $self = shift;
    if (@_ > 1) { $self->{offset} = $_[0]; $self->{limit} = $_[1] }
    elsif (@_ == 1) { $self->{limit} = $_[0]; }
}

=head2 set_order(@list or \@list)

It sets value for 'ORDER BY'.
The values holded by this instance is deleted by it when this method is called.

=cut

sub set_order {
    my $self = shift;
    $self->{order} = args2array(@_);
}

=head2 append_order(@list or \@list)

It has a different function from set_order.
This method don't delete the holding values.

=cut

sub append_order {
    my $self = shift;
    push @{$self->{order}}, @_;
}

=head2 append_order_desc(@list or \@list)

It add the values that had been appended the string of ' DESC'.

=cut

sub append_order_desc {
    my $self = shift;
    push @{$self->{order}}, map { $_ . ' DESC' } @_;
}

=head2 set_group(@list or \@list)

It differ from set_order in that @list is 'ORDER BY'

=cut

sub set_group {
    my $self = shift;
    $self->{group} = args2array(@_);
}

=head2 append_group(@list or \@list)

=cut

sub append_group {
    my $self = shift;
    push @{$self->{group}}, @_;
}

=head2 $values = values

Returns array reference value for bind to place holder.

=cut

sub values {
    my $self = shift;

    my $wv = $self->{where_values};
    my @ret = ();
    for (@$wv) {
        my $r = ref $_;
        if ($r =~ /^Wiz::DB::SQL::Query/) { push @ret, @{$_->values}; }
        else { push @ret, $_; }
    }

    return \@ret;
}

=head2 $query = to_string

create SQL where clause

=cut

sub to_string {
    my $self = shift;
    my ($flag) = @_;
    $self->_to_string($flag, FALSE, FALSE);
}

sub to_string4count {
    my $self = shift;
    my ($flag) = @_;
    $self->_to_string($flag, FALSE, TRUE);
}

=head2 $query = to_exstring

create SQL where clause that binded values

=cut

sub to_exstring {
    my $self = shift;
    my ($flag) = @_;
    $self->_to_string($flag, TRUE, FALSE);
}

sub to_exstring4count {
    my $self = shift;
    my ($flag) = @_;
    $self->_to_string($flag, TRUE, TRUE);
}

=head2 clear

Delete values owned by itself.

=cut

sub clear {
    my $self = shift;

    $self->{limit} = undef;
    $self->{offset} = undef;
    $self->{where_data} = undef;
    $self->{where_values} = undef;
    $self->{order} = [];
    $self->{group} = [];
}

=head2 create_where($expand_flag)

Don't call.
This is abstract method.

=cut

sub create_where {
    my $self = shift;
    my ($exflag) = @_;

    my $wd = $self->{where_data}->[0];
    my @ret = ();
    my $r = ref $wd;
    if ($r eq 'HASH') {
        for (sort keys %$wd) {
            $self->_create_where(\@ret, $_, $wd->{$_}, $exflag);
        }
        return @ret ? join ' AND ', @ret : '';
    }
    elsif ($r eq 'ARRAY') {
        for (my $i = 0; $i < @{$wd}; $i++) {
            $self->_create_where(\@ret, $wd->[$i], $wd->[$i+1], $exflag);
            ref $wd->[$i] ne 'ARRAY' and ++$i;
        }
        return @ret ? join ' OR ', @ret : '';
    }
    else {
        $self->_create_where_normal($self->{where_data}, $exflag);
    }
}

=head2 create_where_values($lwd)

Don't call.
This is abstract method.

=cut

sub create_where_values {
    my $self = shift;
    my ($lwd) = @_;

    my @ret = ();
    my $wd = $lwd->[0];
    my $r = ref $wd;
    if ($r eq 'HASH') {
        for (sort keys %$wd) {
            $self->_create_where_values(\@ret, $_, $wd->{$_});
        }
    }
    elsif ($r eq 'ARRAY') {
        for (my $i = 0; $i < @{$wd}; $i++) {
            $self->_create_where_values(\@ret, $wd->[$i], $wd->[$i+1]);
            ref $wd->[$i] ne 'ARRAY' and ++$i;
        }
    }
    else {
        $self->_create_where_values_normal(\@ret, $self->{where_data});
    }

    $self->{where_values} = \@ret;
    return \@ret;
}

=head2 create_order

Don't call.
This is abstract method.

=cut

sub create_order {
    my $self = shift;

    $self->{order} or return;
    return join ',', map { sanitize $_ } @{$self->{order}};
}

=head2 create_where_values($lwd)

Don't call.
This is abstract method.

=cut

sub create_group {
    my $self = shift;

    $self->{group} or return;
    return join ',', map { sanitize $_ } @{$self->{group}};
}

=head2 create_limit

Don't call.
This is interface.

=cut

sub create_limit {
    my $self = shift;
    die "override create_limit";
}

sub _create_where_values {
    my $self = shift;
    my ($ret, $key, $val) = @_;
    if (ref $key eq 'ARRAY') {
        push @$ret, is_sql_operator($val->[0]) ? $val->[1] : $val->[0];
    }
    else {
        if ($key =~ /^-/) {
            my $q = $self->_create_where_values_core($ret, $key, $val);
            defined $q and $q ne '' and push @$ret, $q;
        }
        else {
            my $rr = ref $val;
            if ($rr eq 'CODE') {}
            elsif ($rr eq 'ARRAY') {
                push @$ret, is_sql_operator($val->[0]) ? $val->[1] : $val->[0];
            }
            else {
                push @$ret, $val;
            }
        }
    }
}

sub _create_where_values_core {
    my $self = shift;
    my ($ret, $key, $val) = @_;
    if (my ($k) = $key =~ /^-(.*)/) {
        if ($k eq 'and' or $k eq 'or') {
            return $self->_create_where_values_and_or($ret, $val);
        }
        elsif ($k eq 'between') {
            my $r = ref $val;
            if ($r eq 'ARRAY') {
                push @$ret, ($val->[1][0], $val->[1][1]);
            }
            elsif ($r eq 'HASH') {
                for (keys %$val) {
                    push @$ret, ($val->{$_}[0], $val->{$_}[1]);
                }
            }
        }
        elsif ($k eq 'in' or $k eq 'not_in') {
            for (keys %$val) {
                for (@{$val->{$_}}) {
                    ref $_ and next;
                    push @$ret, $_;
                }
            }
        }
        else {
            $self->_create_where_values_other($ret, $key, $val);
        }
    }
    return undef;
}

sub _create_where_values_normal {
    my $self = shift;
    my ($ret, $wd) = @_;

    my $n = @$wd;
    for (my $i = 0; $i < $n; $i += 2) {
        $self->_create_where_values_core($ret, $wd->[$i], $wd->[$i+1]);
    }
}

sub _create_where_values_and_or {
    my $self = shift;
    my ($ret, $val) = @_;
    my $n = @$val;
    for (my $i = 0; $i < $n; $i++) {
        if (ref $val->[$i] eq 'ARRAY') {
            if (is_sql_operator($val->[$i][0])){
                ref $val->[$i][2] or push @$ret, $val->[$i][2];
            }
            else {
                if (ref $val->[$i][1] eq 'ARRAY') {
                    ref $val->[$i][1][1] or push @$ret, $val->[$i][1][1];
                }
                else {
                    ref $val->[$i][1] or push @$ret, $val->[$i][1];
                }
            }
        }
        else {
            $self->_create_where_values_core($ret, $val->[$i], $val->[$i+1]);
            $i++;
        }
    }
}

sub _create_where_values_other {}

sub _create_where {
    my $self = shift;
    my ($ret, $key, $val, $exflag) = @_;
    if (ref $key eq 'ARRAY') {
        push @$ret, is_sql_operator($val->[0]) ?
            $self->_field_and_value($val->[1], $val->[0], $val->[2], $exflag) :
            $self->_field_and_value($val->[0], '=', $val->[1], $exflag);
    }
    else {
        if ($key =~ /^-/) {
            my $q = $self->_create_where_core($key, $val, $exflag);
            $q ne '' and push @$ret, $q;
        }
        else {
            push @$ret, $self->_field_and_value($key, '=', $val, $exflag);
        }
    }
}

sub _to_string {
    my $self = shift;
    my ($flag, $exflag, $cnt_flag) = @_;
    $flag ||= SQL_QUERY_WHERE;
    my $query = undef;
    my $where = $self->create_where($exflag);
    if ($where) {
        if (!$flag & SQL_QUERY_WHERE_NONE) { $query = 'WHERE '; }
        $query .= $where;
    }
    my $group = $self->create_group;
    if ($group) { $query and $query .= ' '; $query .= "GROUP BY $group"; }
    if (!$cnt_flag) {
        my $order = $self->create_order;
        if ($order) { $query and $query .= ' '; $query .= "ORDER BY $order"; }
        my $limit = $self->create_limit;
        if ($limit) { $query and $query .= ' '; $query .= $limit; }
    }
    return $query;
}

sub _create_where_normal {
    my $self = shift;
    my ($wd, $exflag) = @_;
    my $w = undef;
    my $n = @$wd;
    for (my $i = 0; $i < $n; $i += 2) {
        $w .= $self->_create_where_core($wd->[$i], $wd->[$i+1], $exflag); 
    }
    return $w;
}

sub _create_where_core {
    my $self = shift;
    my ($key, $val, $exflag) = @_;
    if (my ($k) = $key =~ /^-(.*)/) {
        if ($k eq 'and' or $k eq 'or') {
            return $self->_create_where_core_and_or($k, $val, $exflag);
        }
        elsif ($k eq 'between') {
            my $r = ref $val;
            if ($r eq 'ARRAY') {
                return $exflag ? "$val->[0] BETWEEN " . $self->_get_sanitized_value($val->[1][0]) . 
                                    " AND " . $self->_get_sanitized_value($val->[1][1]) :
                                 "$val->[0] BETWEEN ? AND ?"; 
            }
            elsif ($r eq 'HASH') {
                for (sort keys %$val) {
                    return $exflag ? "$_ BETWEEN " . $self->_get_sanitized_value($val->{$_}[0]) . 
                                        " AND " .  $self->_get_sanitized_value($val->{$_}[1]) :
                                     "$_ BETWEEN ? AND ?";
                }
            }
        }
        elsif ($k eq 'in') {
            return $self->_create_where_core_in($val, $exflag);
        }
        elsif ($k eq 'not_in') {
            return $self->_create_where_core_in($val, $exflag, TRUE);
        }
        elsif ($k eq 'limit') {
            if (@$val > 1) { $self->{offset} = $val->[0]; $self->{limit} = $val->[1]; }
            elsif (@$val == 1) { $self->{limit} = $val->[0]; }
            return '';
        }
        elsif ($k eq 'order') {
            $self->{order} = $val;
            return '';
        }
        elsif ($k eq 'group') {
            $self->{group} = $val;
            return '';
        }
    }
}

sub _create_where_core_in {
    my $self = shift;
    my ($val, $exflag, $notflag) = @_;
    for (sort keys %$val) {
        return sprintf '%s%s IN(%s)', $_, ($notflag ? ' NOT' : ''),
            join ',', @{$self->_values_filter($val->{$_}, $exflag)};
    }
}

sub _create_where_core_and_or {
    my $self = shift;
    my ($key, $val, $exflag) = @_;
    my @w = ();
    my $n = @$val;
    for (my $i = 0; $i < $n; $i++) {
        if (ref $val->[$i] eq 'ARRAY') {
            push @w, $self->_join_value($val->[$i], $exflag);
        }
        else {
            push @w, '(' . $self->_create_where_core($val->[$i], $val->[$i+1], $exflag) . ')';
            $i++;
        }
    }

    my $jk = sprintf ' %s ', uc $key;
    return join $jk, @w;
}

sub _get_sanitized_value {
    my $self = shift;
    my ($val) = @_;
    if (blessed $val and $val->isa('Wiz::DB::SQL::Query')) {
        return '(' . $val->select_dump . ')';
    }
    elsif (ref $val eq 'SCALAR') { return $$val; }
    elsif (ref $val) { return $val; }
    else { return "'" . sanitize($val) . "'" }
}


sub _field_and_value {
    my $self = shift;
    my ($field, $ope, $value, $exflag) = @_;
    my $r = ref $value;
    if ($r eq 'CODE') {
        return is_null_clause($field, $value);
    }
    elsif ($r eq 'ARRAY') {
        ($ope, $value) = is_sql_operator($value->[0]) ?
            ($value->[0], $value->[1]) : ('=', $value->[0]);
    }

    return $exflag ?
        sanitize($field) . sql_operator2part($ope) . $self->_get_sanitized_value($value) :
            (ref $value eq 'SCALAR' ?
                sanitize($field) . sql_operator2part($ope) . $$value : 
                sanitize($field) . sql_operator2part($ope) . '?');
}

sub _join_value {
    my $self = shift;
    my ($val, $exflag) = @_;
    return is_sql_operator($val->[0]) ?
        $self->_field_and_value($val->[1], $val->[0], $val->[2], $exflag) :
        $self->_field_and_value($val->[0], '=', $val->[1], $exflag);
}

sub _values_filter {
    my $self = shift;
    my ($vals, $exflag) = @_;
    return $exflag ?
        [ map $self->_get_sanitized_value($_), @$vals ] :
        [ map { ref $_ ? $$_ : '?' } @$vals ];
}

=head1 SEE ALSO

L<Wiz::DB::SQL::Constant>, L<Wiz::DB::SQL::Where>

=head1 AUTHOR

Junichiro NAKAMURA, C<< <jyun16@gmail.com> >>

=head1 COPYRIGHT & LICENSE

Copyright 2008,2009,2010 The Wiz Project. All rights reserved.

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
