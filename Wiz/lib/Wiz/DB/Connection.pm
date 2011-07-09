package Wiz::DB::Connection;

use strict;
use warnings;

no warnings 'uninitialized';

=head1 NAME

Wiz::DB::Connection - Simplifies DB Connection

=head1 VERSION

version 1.0

=cut

our $VERSION = '1.0';

=head1 SYNOPSIS

 use Wiz::DB::Constant qw(:all);
 use Wiz::DB::Connection qw(:all);
 use Wiz::DB::ResultSet;
 
 my %conf = (
     type        => DB_TYPE_MYSQL,
     host        => 'localhost',
     db          => 'test',
     user        => 'test',
     passwd      => 'test',
     auto_commit => TRUE,
     log     => {
         path    => 'logs/db/error.log',
         stderr  => TRUE,
     },
     cache   => {
         # Cache::xxx module of CPAN.
         type    => 'Memcached::XS',
         conf    => {
             servers => [qw(127.0.0.1:11211)],
         },
     },
 );

The config of log is same L<Wiz::Log>.

 my $dbc = new Wiz::DB::Connection(%conf);
 
 $dbc->execute_only(
     q|CREATE TABLE hoge (id INT AUTO_INCREMENT PRIMARY KEY, name VARCHAR(32)), lastmodify timestamp|);
 $dbc->execute_only(q|INSERT INTO hoge (name) VALUES ('hoge')|);
 
 my $rs = $dbc->execute(q|SELECT * FROM hoge|);
 
 while($rs->next) {
     warn $rs->get('id');
     warn $rs->get('name');
     warn $rs->get('lastmodify');
 }
 
 $rs->close;
 $dbc->close;

Configuration can be specified by external file.

Write the following data in conf/mysql.pdat

 {
     type        => 'mysql',
     host        => 'localhost',
     db          => 'test',
     user        => 'test',
     passwd      => 'test',
     auto_commit => 1,
     log     => {
         path    => 'logs/db/error.log',
         stderr  => 1,
     },
     cache   => {
         type    => 'Memcached',
         conf    => {
             servers => [qw(127.0.0.1:11211)],
         },
     },
 }
    
To use it, 

 my $dbc = new Wiz::DB::Connection(conf => 'conf/mysql.pdat');

HandlerSocket

 my $conf = {
     type            => 'mysql',
     host            => '192.168.10.1',
     db              => 'test',
     user            => 'root',
     handler_socket  => {
         read    => 9998,
         write   => 9999,
     },
 };
 my $conn = new Wiz::DB::Connection($conf);
 my $hs = $conn->handler_socket('tweet', 'PRIMARY', [qw(id text)]) or die $conn->handler_socket_error;
 my @data = $hs->select('>=', 1, 0, 100);

 my $whs = $conn->handler_socket('tweet', 'PRIMARY', [qw(id text)]) or die $conn->writable_handler_socket_error;

=cut

use DBI;

use base qw(Wiz::DB::Base);

use Wiz qw(get_hash_args get_log_from_conf);
use Wiz::Constant qw(:common);
use Wiz::ReturnCode qw(:all);
use Wiz::Log;
use Wiz::DB qw(db_type2label db_label2type);
use Wiz::DB::Constant qw(:type);
use Wiz::DB::ResultSet;
use Wiz::DB::PreparedStatement;
use Wiz::DB::HandlerSocketFactory;

=head1 ACCESSORS

 type
 db
 user
 passwd
 host
 port
 sid
 log
 driver
 cache
 die
 dbh
 is_slave
 label

=cut

our @CONFS = qw(type db user passwd host port sid log driver cache hs whs die charset mysql_socket handler_socket);

__PACKAGE__->mk_accessors(@CONFS, qw(dbh is_slave label));

=head1 CONSTRUCTOR

=head2 new(%conf) or new(\%conf)

 my %conf = (
     type    =>        # DB_TYPE_POSTGRESQL, DB_TYPE_MYSQL, DB_TYPE_ORACLE, 
                       # DB_TYPE_ODBC, DB_TYPE_ODBC_MYSQL, DB_TYPE_MSSQL
     db      =>        # database name
     user    =>        # database access user
     passwd  =>        # user password
     host    =>        # database host
     port    =>        # database listen port
     sid     =>        # ORACLE sid
     log     =>        # log config or Wiz::Log instance
     driver  =>        # driver name
     cache   =>        # cache config (CPAN's Cache::XXX modules config)
 );

'type' can be specified by a string, like 'postgresql', 'mysql' and 'oracle'.

When $conf->{log} is specified, error messages generated during execution of this class will be sent to it.

my $dbc = new Wiz::DB::Connection(%conf);

$conf{conf} specifies the config file path.

We can't use 'error' method for detecting connection error, though error message will be output to log file only when specified $conf->{log}.
In addition, instance of this class won't be created in case of connection error.

=cut

sub new {
    my $self = shift;
    my $conf = get_hash_args(@_);
    $conf->{type} !~ /^\d*$/ and $conf->{type} = db_label2type($conf->{type});
    my $log = get_log_from_conf($conf);
    my $instance = bless {
        type        => $conf->{type},
        log         => $log,
        rs          => undef,                       # result set managing table
        pstmt       => undef,                       # prepared statement managing table
        error       => undef,
        auto_commit => $conf->{auto_commit},
        die         => $conf->{die},
        is_slave    => FALSE,
        conf        => $conf,
        label       => undef,
    }, $self;
    my $dbh = $instance->_connect_db;
    return_code_is($dbh, undef) and return $dbh;
    $instance->{dbh} = $dbh;
    $instance->_init_cache;
    $instance->_init_handler_socket;
    $instance->auto_commit($conf->{auto_commit});
    return $instance;
}

=head1 METHODS

=head2 $hash_data = retrieve($query)

Executes $query, and returns a hash reference data of result.

=cut

sub retrieve {
    my $self = shift;
    my ($query, $values) = @_;

    my $sth = $self->prepare($query);

    $values ?  $sth->execute(@$values) : $sth->execute;
    my $err = $sth->errstr;
    if ($err) {
        $self->write_error($err, [ caller ]);
        return undef;
    }
    else { $self->clear_error; }

    my $rs = new Wiz::DB::ResultSet($self, $sth);
    $rs->next or return undef;
    return $rs->data;
}

=head2 $result_set = execute($query)

Executes $query, and returns instance of Wiz::DB::ResultSet.

=cut

sub execute {
    my $self = shift;
    my ($query, $values) = @_;

    my $sth = $self->prepare($query);

    $values ? $sth->execute(@$values) : $sth->execute;
    my $err = $sth->errstr;
    if ($err) {
        $self->write_error($err, [ caller ]);
        return undef;
    }
    else { $self->clear_error; }

    return new Wiz::DB::ResultSet($self, $sth);
}

=head2 $line_no = execute_only($query)

Simply executes $query.

$line_no: the number of lines affected by the execution.

=cut

sub execute_only {
    my $self = shift;
    my ($query, $values) = @_;

    my $sth = $self->prepare($query);
    my $ret = $values ? $sth->execute(@$values) : $sth->execute;

    my $err = $sth->errstr;
    if ($err) {
        $self->write_error($err, [ caller ]);
        return undef;
    }

    $sth->finish;
    $err = $sth->errstr;
    if ($err) {
        $self->write_error($err, [ caller ]);
        return undef;
    }
    $self->clear_error;

    $ret eq '0E0' and return 0;
    return $ret;
}

=head2 $prepared_statement = prepared_statement($query)

Returns an instance of Wiz::DB::PreparedStatement for placeholder.

$prepared_statement: Instance of Wiz::DB::PreparedStatement

=cut

sub prepared_statement {
    my $self = shift;
    my ($query) = @_;

    return new Wiz::DB::PreparedStatement($self, $query);
}

=head2 $sth = prepare($query, $ra_caller)
    
Same as 'prepare' in DBI.
$ra_caller is needed only for internal use. It will be used for logging.

=cut

sub prepare {
    my $self = shift;
    my ($query) = @_;

    $self->{_query_} = $query;

    my $sth = $self->{dbh}->prepare($query);
    my $err = $sth->errstr;
    if ($err) {
        $self->write_error($err, [ caller ]);
        return undef;
    }
    $self->clear_error;

    return $sth;
}

=head2 $bool = rollback

=cut

sub rollback {
    my $self = shift;

    $self->{auto_commit} and return;
    return $self->{dbh}->rollback;
}

=head2 $bool = commit

=cut

sub commit {
    my $self = shift;

    $self->{auto_commit} and return;
    $self->is_slave and return;
    return $self->{dbh}->commit;
}

=head2 auto_commit($flag)

If $flag is TRUE, auto commit is set to on, otherwise to off.
Default state is off.

=cut

sub auto_commit {
    my $self = shift;
    my ($auto_commit) = @_;

    $self->{auto_commit} = $auto_commit;
    $self->{dbh}{AutoCommit} = $auto_commit;
}

=head2 table_exists($table)

Returns TRUE if table exists.

=cut

sub table_exists {
    my $self = shift;
    my ($table) = @_;

    if ($self->{type} == DB_TYPE_MYSQL) {
        my $sth = $self->prepare("DESC $table");
        $sth->execute;
        my $err = $sth->errstr;
        return (defined $err and $err =~ /doesn't exist$/) ? FALSE : TRUE;
    }
    else {
        $self->write_error("self function is not mounted yet");
    }
}

sub close_statement_handle {
    my $self = shift;

    my $rs = $self->{rs};
    for (keys %$rs) { $rs->{$_}->close(); }

    my $pstmt = $self->{pstmt};
    for (keys %$pstmt) { $pstmt->{$_}->close(); }
}

=head2 $dsn_data = get_dsn_data

Returns a data for dsn.

    {
        driver  => 'any',
        db      => 'any',
        host    => 'any',
        port    => 'any',
        user    => 'any',
        passwd  => 'any',
        type    => 'type',
    }

=cut

sub get_dsn_data {
    my $self = shift;
    my %ret = ();
    my $conf = $self->{conf};
    for (qw(driver db host port user passwd type)) {
        defined $conf->{$_} and $ret{$_} = $conf->{$_};
    }
    return \%ret;
}

=head2 set_dsn_data($dsn_data)

Sets a data for dsn.

=cut

sub set_dsn_data {
    my $self = shift;
    my ($dsn_data) = @_;
    my $conf = $self->{conf};
    for (qw(driver db host port user passwd type)) {
        defined $dsn_data->{$_} and
            $conf->{$_} = $dsn_data->{$_};
    }
}

=head2 $cache = cache

Returns cache instance.

=cut

sub cache {
    shift->{cache};
}

sub handler_socket {
    my $self = shift;
    $self->{hs} or return;
    $self->{hs}->open(@_);
}

sub handler_socket_error {
    my $self = shift;
    $self->{hs} or return;
    $self->{hs}->error;
}

sub writable_handler_socket {
    my $self = shift;
    $self->{hs} or return;
    $self->{whs}->open(@_);
}

sub writable_handler_socket_error {
    my $self = shift;
    $self->{hs} or return;
    $self->{whs}->error;
}

=head2 $bool = close

Closes DB connection.
This method is called from DESTROY for connection closing. 
It is needed only on the situation for explicitly closing.

=cut

sub close {
    my $self = shift;
    $self->_close();
}

sub DESTROY {
    my $self = shift;
    $self->close();
}

#----[ static ]-------------------------------------------------------
#----[ private ]------------------------------------------------------
sub _close {
    my $self = shift;

    if (defined $self->{dbh}) {
        local $@ = undef;
        eval { $self->{dbh}->disconnect; };
        if ($@) {
            $self->write_error($@, [ caller ]);
            $@ = ''; return FALSE;
        }
    }
    return TRUE;
}

#----[ private static ]-----------------------------------------------
sub _connect_db {
    my $self = shift;

    my $conf = $self->{conf};
    my $type = $conf->{type};
    $type or return;
    my $dbh = undef;

    $conf->{host} ||= 'localhost';

    if ($type == DB_TYPE_ORACLE) {
        $dbh = $self->_connect_db_oracle;
    }
    elsif ($type == DB_TYPE_ODBC or $type == DB_TYPE_ODBC_MYSQL or $type == DB_TYPE_ODBC_MSSQL) {
        $dbh = $self->_connect_db_odbc;
    }
    else {
        $dbh = $self->_connect_db_any;
    }

    # thread unsafe. but this message isn't very important.
    if (not defined $dbh) {
        $self->write_error("DB connect failed:DBI->connect: $DBI::errstr");
        return return_code(undef, $DBI::errstr);
    }

    return $dbh;
}

sub _connect_db_odbc {
    my $self = shift;
    my $conf = $self->{conf};
    my $type = 'ODBC';
    my $dsn = undef;
    if ($conf->{type} == DB_TYPE_ODBC_MYSQL) {
        $conf->{driver} ||= 'MySQL ODBC 3.51 Driver';
    }
    elsif ($conf->{type} == DB_TYPE_ODBC_MSSQL) {
        $conf->{driver} ||= 'SQL Server';
    }
    $dsn = "driver={$conf->{driver}};Server=$conf->{host};database=$conf->{db};";
    if ($conf->{port}) {
        $dsn .= "port=$conf->{port};";
    }
    return DBI->connect("dbi:$type:$dsn", $conf->{user}, $conf->{passwd},
            { RaiseError => FALSE, PrintError => TRUE, AutoCommit => FALSE });
}

sub _connect_db_any {
    my $self = shift;
    my $conf = $self->{conf};
    my $type = $conf->{type};
    if ($conf->{type} == DB_TYPE_MYSQL) {
        $type = db_type2label($conf->{type});
    }
    elsif ($conf->{type} == DB_TYPE_POSTGRESQL) { $type = 'Pg'; }
    else {
        $self->write_error("invalid database type");
    }
    if (not defined $conf->{port}) {
        if ($conf->{type} eq DB_TYPE_POSTGRESQL) { $conf->{port} = 5432; }
        elsif ($conf->{type} eq DB_TYPE_MYSQL) { $conf->{port} = 3306; }
    }
    my $dsn = "dbname=$conf->{db};host=$conf->{host};port=$conf->{port}";
    for (qw(mysql_socket)) {
        $conf->{$_} and $dsn .= ";$_=$conf->{$_}";
    }
    local $@ = undef;
    my $dbh = eval {
        DBI->connect("dbi:$type:$dsn", $conf->{user}, $conf->{passwd},
            { RaiseError => TRUE, PrintError => FALSE, AutoCommit => FALSE });
    };
    if ($@) { $self->write_error($@); return; }
    $self->{type} == DB_TYPE_MYSQL and $conf->{charset} and $dbh->do("SET NAMES $conf->{charset}");
    return $dbh;
}

sub _connect_db_oracle {
    my $self = shift;
    my $conf = $self->{conf};
    $conf->{port} ||= 1521;
    my $tnsname = qq{$conf->{user}/$conf->{passwd}@(
            DESCRIPTION=(
                ADDRESS=(PROTOCOL=TCP)(HOST=$conf->{host})(PORT=$conf->{port})
            )(CONNECT_DATA=(SID=$conf->{sid})))};
    my $dbh = DBI->connect('dbi:Oracle:', $tnsname,
            { RaiseError => FALSE, PrintError => TRUE, AutoCommit => FALSE });
    return $dbh;
}

sub _init_cache {
    my $self = shift;
    my $conf = $self->{conf}{cache};
    defined $conf or return;
    my $cache = undef;
    my $eval_str = 
        sprintf 'use Cache::%s; $cache = Cache::%s->new($conf->{conf})',
            $conf->{type}, $conf->{type};
    local $@ = undef;
    eval $eval_str;
    $@ and $self->write_error($@);
    defined $cache and $self->{cache} = $cache;
    return $cache;
}

sub _init_handler_socket {
    my $self = shift;
    my $conf = $self->{conf};
    if ($conf->{handler_socket}) {
        if ($conf->{handler_socket}{read}) {
            $self->{hs} = new Wiz::DB::HandlerSocketFactory(
                { host => $conf->{host}, port => $conf->{handler_socket}{read}, db => $conf->{db} }
            );
        }
        if ($conf->{handler_socket}{write}) {
            $self->{whs} = new Wiz::DB::HandlerSocketFactory(
                { host => $conf->{host}, port => $conf->{handler_socket}{write}, db => $conf->{db} }
            );
        }
    }
}

=head1 SEE ALSO

L<Wiz::Log>, L<Wiz::DB::Base>, L<Wiz::DB::Constant>

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

