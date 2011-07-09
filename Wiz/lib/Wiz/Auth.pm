package Wiz::Auth;

use strict;
use warnings;

=head1 NAME

Wiz::Auth - Handles Authentication and Authorization

=head1 VERSION

version 1.0

=cut

our $VERSION = '1.0';

=head1 SYNOPSIS

 use Wiz::Auth;
 
 my $auth = Wiz::Auth->new(
                 db      => $dbh, 
                 _conf   => 'realm.yml',
                 session => $c->session
            );
            
 #  In login page...
 #  check login
 my $user = $auth->execute( { user => $username, password => $password } );
 if ( $user ) {
     print "Login success.";   
 }
 else {
     print "Login failed.";
 }
 
 #  check user's role
 if ( $user->has_role('edit') ) { 
     print "You can edit this data.";
 }
 else {
     print "You aren't authorized editing this data.";
 }
 
 # check multiple roles
 $user->has_role('-all', qw/ tech admin /); # requires a role 'tech' and 'admin'
 $user->has_role('-or', qw/ tech admin /); # requires a role 'tech' or 'admin' 

 # the following is same the avobe.
 $user->has_role({ tech => 1, admin => 1}); 
 $user->has_role([qw(tech, admin)]); 
 
 #  logout
 $auth->logout;

=head1 DESCRIPTION

Handles Authentication and Authorization.

=head2 authentication with database

Configuration must be specified with a hash or a hashref like the followings, 
and be passed to constructor.
A part of the configuration can be specified by a configuration file like YAML or PDAT,
in which case the file name must be specified by $config->{_conf}.

Caution: When you use a YAML file, you can't use the constants 'TRUE' nor 'FALSE'.
Instead of using them, use '1' or '0'.

 $config = {
     db                 => $dbh,
     session            => $session,
     use_role           => TRUE,
     prefix             => undef,
     use_delete_flag    => TRUE,
     use_mobile_auth    => FALSE,
     password_type   => 'sha-512_base64',
     table_names      => {
         user        => 'user',
         user_role   => 'user_role',
         role        => 'role',
     },
     fields    => {
         user       => {
            id              => 'id', 
            userid          => 'userid',
            password        => 'password',
            mobile_uid      => 'mobile_uid',
            status          => 'status',
            delete_flag     => 'delete_flag',
         },
         user_role => {
            user_id         => 'user_id',
            role_id         => 'role_id',            
         },
         role       => {
            id              => 'id', 
            name            => 'name',             
         },
     },
     _conf               => $config_file_name,     #  when using external config file
 };

=over 4

=item db

A database handle. (only needed when using database for authentication)

=item session

A session object.

=item use_role

If you want to use multiple role, set this to TRUE(1).
(ex. There are normal members and premium members, and you want to differenciate what they can do
in your website.)

=item prefix

A common prefix for table name.
(ex. smart_user, smart_rss  ->  'smart_' is the prefix.)

You need not specify this value, or you may specify it explicitly with undef, 
when you don't use a common prefix.

=item use_delete_flag

If you're using delete_flag in tables, set this to TRUE(1).

=item tables

Table information. 
If you don't specify anything in I<tables>, default table/column names will be used.
(See %DEFAULT)

The only value in I<tables> is password_type in hashref I<user>.
If you want to store digested password(for example, md5, sha-1), specify this value.

Avairable digest methods are...
 md5 sha-1 sha-256 sha-384 sha-512
 
and avairable formats are...
 hex base64
 
Concatenate methods and formats with underscore(_), like
 sha-1_hex
 
As to table definition, refer to the following SQLs for table creation.

 CREATE TABLE user (
     id          INT PRIMARY KEY AUTO_INCREMENT,
     userid      VARCHAR(32) NOT NULL UNIQUE,
     password    VARCHAR(86) NOT NULL
 ) TYPE=InnoDB;
 
 CREATE TABLE user_role (
     id          INT PRIMARY KEY AUTO_INCREMENT,
     user_id     INT REFERENCES user(id),
     role_id     INT REFERENCES role(id),
     UNIQUE(user_id, role_id)
 ) TYPE=InnoDB;
 
 CREATE TABLE role (
     id          INT PRIMARY KEY AUTO_INCREMENT,
     name        VARCHAR(64) NOT NULL UNIQUE
 ) TYPE=InnoDB;

=back

=cut

use Carp;
use Digest;
use Clone qw(clone);

use Wiz qw(get_hash_args);
use Wiz::Constant qw(:all);
use Wiz::Util::Hash qw(override_hash);
use Wiz::DB::Constant qw(:all);
use Wiz::DB::Connection;
use Wiz::DB::DataIO;
use Wiz::DB::PreparedStatement;
use Wiz::DB::ResultSet;
use Wiz::DB::SQL::Constant qw(:all);
use Wiz::DB::SQL::Query;
use Wiz::DB::DataIO;
use Wiz::Auth::User;
use Wiz::Util::Validation qw(is_email_address);

#  Default database configuration.
#  If you want to use different table/column name, 
#  override it with configuration passed to constructor.
our %DEFAULT = (
    use_role        => FALSE,
    prefix          => undef,
    use_email_auth  => FALSE,
    use_delete_flag => TRUE,
    use_mobile_auth => FALSE,
    password_type   => 'sha-512_base64',
    table_names     => {
        user        => 'user',
        user_role   => 'user_role',
        role        => 'role',
    },
    fields          => {
        user        => {
            id              => 'id', 
            userid          => 'userid',
            email           => 'email',
            password        => 'password',
            mobile_uid      => 'mobile_uid',
            status          => 'status',
            delete_flag     => 'delete_flag',
        },
        user_role => {
            user_id         => 'user_id',
            role_id         => 'role_id',
        },
        role => {
            id              => 'id', 
            name            => 'name',
        },
    }
); 

our @CONFS = (keys %DEFAULT);

=head1 METHODS

=head2 $obj = new(db => $dbh, config => $config, session => $session)

Constructor.

 $dbh - database handle
 $config - configuration with a hash
 $session - session object

=head2 $obj = new(db => $dbh, _conf => $filename, session => $session)

Constructor.

 $dbh - database handle
 $filename - configuration YAML file name which contains information for authentication and authorization
 $session - session object

=cut

sub new {
    my $invocant = shift;
    my $class = ref $invocant || $invocant;
    my $args = get_hash_args(@_);

    my $conf = override_hash({ %DEFAULT }, $args);
    defined $conf->{prefix} and _append_prefix($conf);

    return bless {
        conf    => $conf,
        db      => $args->{db},
        session => $args->{session},
    }, $class;
}

=head2 $user_obj = execute($userinfo)

Try authentication using $userinfo.
If succeed, returns an instance of Wiz::Auth::User.
Otherwise returns undef.

Password can be recorded into database not only with a plain text,
but also with a digested and encrypted value.
In that case, password_type in $config must be specified with a string that represents
the digestion/encryption method like 'md5'. 

$userinfo has two keys, userid and password.

 $userinfo = {
     userid   => (userid),
     password => (plain/digested password)
 };

=cut

sub execute {
    my $self = shift;
    my $userinfo = get_hash_args(@_);

    return $self->{db} ?
        $self->_execute($userinfo) : $self->_execute_from_config($userinfo);
}

=head2 $roles_rh = role($user)

Retrieves roles of a specied user.
$user is an instance of Wiz::Auth::User.

Return value is a hashref which contains key-value pairs.
'key' represents a role name, and value is always 1.

For example, if the user has roles 'role1' and 'role2', the content of the return value is

 $roles_rh = {
     role1  => 1,
     role2  => 1
 };

=cut

sub role {
    my $self = shift;
    my ($user) = @_;

    defined $user or return;
    $self->{conf}{use_role} or return;

    my $q = new Wiz::DB::SQL::Query(
        type    => DB_TYPE_MYSQL, 
        table   => $self->{conf}{table_names}{user},
    );

    my $userid = $user->{userid};
    $q->join(
        [ INNER_JOIN, "-and", 
            [ $self->_tab_col(user => 'id') => $self->_tab_col(user_role => 'user_id') ],
            [ $self->_tab_col(user => 'userid') => \$userid ],
        ],
        [ INNER_JOIN, $self->_tab_col(user_role => 'role_id') => $self->_tab_col(role => 'id') ],
    );

    my $rs = $self->{db}->execute($q->select);
    my %roles = ();
    while ($rs->next) { $roles{$rs->get('name')} = 1 }
    return \%roles;
}

sub digest_password {
    my $self = shift;
    my ($password, $type) = @_;

    $type ||= $self->{conf}{password_type};

    return $password if (!defined($type) || $type eq '' || $type eq 'plain');

    my ($alg, $format);
    if ($type !~ m/^([0-9a-zA-Z\-]+)[_-](hex|base64)$/msx) {
        confess "Digest type is invalid: $type";
    }
    else {
        $alg = uc($1);
        $format = $2;
        $alg =~ s/^SHA([0-9])/SHA-$1/i;
    }
    my $digest = Digest->new($alg);
    $digest->add($password);
    return ($format eq 'hex') ? $digest->hexdigest : 
           ($format eq 'base64') ? $digest->b64digest :
                confess "Digest format is invalid: $format";
}

sub _execute {
    my $self = shift;
    my ($userinfo) = @_;
    my $conf = $self->{conf};
    my $u = new Wiz::DB::DataIO($self->{db}, $conf->{table_names}{user});
    my $user = undef;
    if ($conf->{use_mobile_auth}) {
        eval <<'EOS';
            use HTTP::MobileAgent;
            use HTTP::MobileUserID;
            my $param = {};
            my $mobile_user = new HTTP::MobileUserID(new HTTP::MobileAgent);
            $param->{$self->_col(user => 'mobile_uid')} = $mobile_user->id;
            $user = $u->retrieve($param);
EOS
    }
    my $param = {};
    unless ($user) {
        if ($conf->{use_email_auth} and is_email_address($userinfo->{userid})) {
            $param->{$self->_col(user => 'email')} = $userinfo->{userid};
        }
        else {
            $param->{$self->_col(user => 'userid')} = $userinfo->{userid};
        }
        $param->{$self->_col(user => 'password')} =
            $self->digest_password($userinfo->{password});
        $conf->{use_delete_flag} and
            $param->{$self->_col(user => 'delete_flag')} = 0;
        $user = $u->retrieve($param);
    }
    my $login_mode;
    if (!$user and $conf->{use_hidden_password}) {
        delete $param->{$self->_col(user => 'password')};
        for (keys %{$conf->{use_hidden_password}}) {
            $param->{$_} =
                $self->digest_password($userinfo->{password});
            $user = $u->retrieve($param);
            delete $param->{$_};
            if ($user) { 
                $login_mode = $conf->{use_hidden_password}{$_};
                last;
            }
        }
    }
    defined $user or return undef;
    if ($conf->{use_email_auth} and is_email_address($userinfo->{userid})) {
        $user->{userid} = $userinfo->{userid};
    }
    my $ret = new Wiz::Auth::User(
        $self->_purify_user($user),
        $self->_purify_role($self->role($user)),
    );
    $login_mode and $ret->login_mode($login_mode);
    return $ret;
}

sub force_get_user {
    my $self = shift;
    my ($userinfo) = @_;
    my $u = new Wiz::DB::DataIO($self->{db}, $self->{conf}{table_names}{user});
    my $param = {};
    $param->{$self->_col(user => 'id')} = $userinfo->{id};
    my $user = $u->retrieve($param);
    return new Wiz::Auth::User(
        $self->_purify_user($user),
        $self->_purify_role($self->role($user)),
    );
}

sub _purify_user {
    my $self = shift;
    my ($user) = @_;
    defined $user or return;
    my $table_name = $self->{conf}{table_names}{user};
    my $user_col = $self->{conf}{fields}{user};
    for (qw(id userid delete_flag status)) {
        unless (defined $user->{$_}) {
            $user->{$_} = $user->{$user_col->{$_}};
            delete $user->{$user_col->{$_}};
        }
    }
    delete $user->{$table_name}{password};
    delete $user->{$table_name}{password_type};
    my $conf = $self->{conf};
    if ($conf->{use_hidden_password}) {
        for (keys %{$conf->{use_hidden_password}}) {
            delete $user->{$_};
        }
    }
    $user->{label} = $self->{conf}{label};
    return $user;
}

sub _purify_role {
    my $self = shift;
    my ($role) = @_;
    defined $role or return;
    my $role_col = $self->{conf}{fields}{role};
    for (qw(id name)) {
        unless (defined $role->{$_}) {
            $role->{$_} = $role->{$role_col->{$_}};
            delete $role->{$role_col->{$_}};
        }
    }
    return $role;
}

sub _execute_from_config {
    my $self = shift;
    my ($userinfo) = @_;
    no warnings 'uninitialized';
    my $userid = $userinfo->{userid};
    my $password = $self->digest_password($userinfo->{password});
    return 0 if (!defined($userid) | !defined($password));
    my $user = clone $self->{conf}{user}{$userid};
    if (defined $user and $password eq $user->{password}) {
        $user->{userid} = $userid;
        return Wiz::Auth::User->new(
            $self->_purify_user($user), $self->_purify_role($user->{roles}));
    }
    return undef;
}

sub _append_prefix {
    my ($conf) = @_;
    for (keys %{$conf->{table_names}}) {
        $conf->{table_names}{$_} = $conf->{prefix} . $conf->{table_names}{$_};
    }
}

sub _col {
    my $self = shift;
    my ($table, $column) = @_;
    return $self->{conf}{fields}{$table}{$column}; 
}

sub _tab_col {
    my $self = shift;
    my ($table, $column) = @_;
    my $conf = $self->{conf};
    return $conf->{table_names}{$table} . '.' . $conf->{fields}{$table}{$column}; 
}

1;

=head1 AUTHOR

Junichiro NAKAMURA, C<< <jyun16@gmail.com> >>

Egawa Takashi, C<< <egawa.takashi@adways.net> >>

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
