package Wiz::DB;

use strict;
use warnings;

no warnings 'uninitialized';

=head1 NAME

Wiz::DB - Utilities for Wiz::DB::* modules

=head1 VERSION

version 1.0

=cut

our $VERSION = '1.0';

=head1 SYNOPSIS

 db_type2label
 db_label2type
 db_status2label
 db_label2status
 db_type2class_name
 db_label2class_name
 sanitize
 sanitize_list
 is_sql_operator
 sql_operator2part
 alias
 is_null_clause
 like
 prelike
 suflike
 like_sub

=head1 DESCRIPTION

It provieds utilty functions for Wiz::DB::* moduels.
Wiz::DB::*'s base class is L<Wiz::DB::Base>

=cut

use base qw(Exporter);

use Wiz::Constant qw(:common);
use Wiz::DB::Constant qw(:common);
use Wiz::DB::SQL::Constant qw(IS_NULL IS_NOT_NULL :like);
use Wiz::Util::String qw(named_format);
use Wiz::Util::Array qw(args2array);

use Wiz::ConstantExporter [qw(
db_type2label db_label2type
db_status2label db_label2status
db_type2class_name db_label2class_name
sanitize sanitize_list sanitize_like is_sql_operator sql_operator2part alias is_null_clause
like prelike suflike like_sub
formatted_query
)]; 

my %type2label  = (
    DB_TYPE_MYSQL()             => DB_TYPE_MYSQL_LBL,
    DB_TYPE_POSTGRESQL()        => DB_TYPE_POSTGRESQL_LBL,
    DB_TYPE_ORACLE()            => DB_TYPE_ORACLE_LBL,
    DB_TYPE_MSSQL()             => DB_TYPE_MSSQL_LBL,
    DB_TYPE_ODBC()              => DB_TYPE_ODBC_LBL,
    DB_TYPE_ODBC_MYSQL()        => DB_TYPE_ODBC_MYSQL_LBL,
    DB_TYPE_ODBC_MSSQL()        => DB_TYPE_ODBC_MSSQL_LBL,
);

my %type2class_name = (
    DB_TYPE_MYSQL()             => DB_TYPE_MYSQL_STR,
    DB_TYPE_POSTGRESQL()        => DB_TYPE_POSTGRESQL_STR,
    DB_TYPE_ORACLE()            => DB_TYPE_ORACLE_STR,
    DB_TYPE_ODBC()              => DB_TYPE_ODBC_STR,
    DB_TYPE_ODBC_MYSQL()        => DB_TYPE_MYSQL_STR,
    DB_TYPE_ODBC_MSSQL()        => DB_TYPE_MSSQL_STR,
);

my %label2type = (
    DB_TYPE_MYSQL_LBL()         => DB_TYPE_MYSQL,
    DB_TYPE_POSTGRESQL_LBL()    => DB_TYPE_POSTGRESQL,
    DB_TYPE_POSTGRESQL_LBL2()   => DB_TYPE_POSTGRESQL,
    DB_TYPE_ORACLE_LBL()        => DB_TYPE_ORACLE,
    DB_TYPE_MSSQL_LBL()         => DB_TYPE_MSSQL,
    DB_TYPE_ODBC_LBL()          => DB_TYPE_ODBC,
    DB_TYPE_ODBC_MYSQL_LBL()    => DB_TYPE_ODBC_MYSQL,
    DB_TYPE_ODBC_MSSQL_LBL()    => DB_TYPE_ODBC_MSSQL,
);

my %label2class_name = (
    DB_TYPE_MYSQL_LBL()         => DB_TYPE_MYSQL_STR,
    DB_TYPE_POSTGRESQL_LBL()    => DB_TYPE_POSTGRESQL_STR,
    DB_TYPE_POSTGRESQL_LBL2()   => DB_TYPE_POSTGRESQL_STR,
    DB_TYPE_ORACLE_LBL()        => DB_TYPE_ORACLE_STR,
    DB_TYPE_MSSQL_LBL()         => DB_TYPE_MSSQL_STR,
    DB_TYPE_ODBC_LBL()          => DB_TYPE_ODBC_STR,
    DB_TYPE_ODBC_MYSQL_LBL()    => DB_TYPE_ODBC_MYSQL_STR,
    DB_TYPE_ODBC_MSSQL_LBL()    => DB_TYPE_ODBC_MSSQL_STR,
);

my %sanitize_map = (
    "\\"    => "\\\\",
    "'"     => q|\'|,
    '"'     => q|\"|,
    ';'     => '\;',
    '|'     => '\|',
    "\n"    => '\n',
    "\r"    => '\r',
    "\0"    => '\0',
);

=head1 FUNCTIONS

=head2 $label = db_type2label($type)

Converts a db type constant value to string.

ex)

 DB_TYPE_MYSQL -> 'mysql',
 DB_TYPE_POSTGRESQL -> 'pg',

=cut

sub db_type2label {
    $type2label{+shift};
}

=head2 $type = db_label2type($label)

Converts a db string value to constant.

=cut

sub db_label2type {
    $label2type{lc shift};
}

=head2 $label = db_status2label($status)

Converts a master or slave status constant to string.

ex)

 MASTER -> 'master'
 SLAVE -> 'slave'

=cut

sub db_status2label {
    my $status  = shift;
    if ($status == MASTER) { return 'master'; }
    elsif ($status == SLAVE) { return 'slave'; }
}

=head2 $status = db_label2status($label)

Converts a master or slave status string to constant.

ex)

 'master' -> MASTER
 'slave' -> SLAVE

=cut

sub db_label2status {
    my $label = shift;
    if ($label eq 'master') { return MASTER; }
    elsif ($label eq 'slave') { return SLAVE; }
}

=head2 $class_name = db_type2class_name($type)

Converts a db type constant value to class name.

ex)

 DB_TYPE_POSTGRESQL -> 'PostgreSQL'
 DB_TYPE_MYSQL -> 'MySQL'

=cut

sub db_type2class_name {
    $type2class_name{+shift};
}

=head2 $class_name = db_label2class_name($label)

ex)

 'mysql' -> 'MySQL'
 'pg' -> 'PostgreSQL'
 'postgresql' -> 'PostgreSQL'

=cut

sub db_label2class_name {
    $label2class_name{+shift};
}

=head2 $sanitized_value = sanitize($data or \$data)

SQL query sanitizer.

=cut

sub sanitize {
    my $data = shift;
    my $d = ref $data ? $data : \$data;
    defined $$d or return;
    $$d =~ s#([\\\"\';|\n\r\0])#$sanitize_map{$1}#ge;
    return $$d;
}

sub sanitize_list {
    my $data = args2array @_;
    for (@$data) { $_ = sanitize($_); }
    return $data;
}

=head2 $sanitized_value = like($str or \$str)

SQL query sanitizer for like part.

 like('blah%blah')

returns

 '%blah\%blah%'

=cut

sub like {
    my $str = shift;
    if (ref $str) { $$str =~ s/%/\\%/g; $$str = "\%$$str\%"; }
    else { $str =~ s/%/\\%/g; return "\%$str\%"; }
}

=head2 $sanitized_value = prelike($str or \$str)

 like('blah%blah')

returns

 'blah\%blah%'

=cut

sub prelike {
    my $str = shift;
    if (ref $str) { $$str =~ s/%/\\%/g; $$str = "$$str\%"; }
    else { $str =~ s/%/\\%/g; return "$str\%"; }
}

=head2 $sanitized_value = suflike($str or \$str)

 like('blah%blah')

returns

 '%blah\%blah'

=cut

sub suflike {
    my $str = shift;
    if (ref $str) { $$str =~ s/%/\\%/g; $$str = "\%$$str"; }
    else { $str =~ s/%/\\%/g; return "\%$str"; }
}

sub sanitize_like {
    my $data = shift;
    my $d = ref $data ? $data : \$data;
    defined $$d or return;
    sanitize($d);
    $$d =~ s/%/\\%/g;
    return $$d;
}

=head2 $bool = is_sql_operator($str)

If $data is any SQL operator it returns TRUE.

=cut

sub is_sql_operator {
    my $data = shift;
    return $data =~ /^[!=<>]+|LIKE|NOT|NOT LIKE|REGEXP|NOT REGEXP$/i;
}

=head2 $query_part = sql_operator2part($str)

 'LIKE' -> ' LIKE '
 'NOT' -> ' NOT '
 'REGEX' -> ' REGEX'

=cut

sub sql_operator2part {
    my $ope = shift;

    if ($ope =~ /(?-xism:[!=<>]+)/) { return $ope; }
    elsif ($ope =~ /LIKE|NOT|REGEX/i) { return " $ope "; }
    else { return $ope; }
}

=head2 $query_part = is_null_clause($field, $value)

Create null clause.
The IS_NULL, IS_NOT_NULL is constant value.

ex)

 is_null_clause('foo', IS_NULL)
 is_null_clause('foo', IS_NOT_NULL)

returns

 'foo IS NULL'
 'foo IS NOT NULL'

=cut

sub is_null_clause {
    my ($field, $value) = @_;
    my $v = $value->();
    if ($v == IS_NULL->()) { return $field . ' IS NULL'; }
    elsif ($v == IS_NOT_NULL->()) { return $field . ' IS NOT NULL'; }
}

=head2

Returns a subroutine reference of like by constant FULL, PREFIX or SUFFIX.

=cut

sub like_sub {
    my ($type) = @_;
    if ($type == LIKE) { \&Wiz::DB::like; }
    elsif ($type == PRE_LIKE) { \&Wiz::DB::prelike; }
    elsif ($type == SUF_LIKE) { \&Wiz::DB::suflike; }
    elsif ($type == FULL) { \&Wiz::DB::like; }
    elsif ($type == PREFIX) { \&Wiz::DB::prelike; }
    elsif ($type == SUFFIX) { \&Wiz::DB::suflike; }
    else { sub { shift } }
}

sub formatted_query {
    my ($query, $data) = @_;
    for (keys %$data) {
        $data->{$_} = sanitize $data->{$_};
    }
    named_format($query, $data);
}

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
