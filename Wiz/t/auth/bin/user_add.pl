#!/usr/bin/perl

=head1 NAME

    ($Revision: $)

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 EXAMPLES

=head1 AUTHOR

Junichiro NAKAMURA

=head1 VERSION

=cut

use strict;

use lib qw(../../../lib);

use Wiz::Constant qw(:all);
use Wiz::Args::Simple qw(getopts);
use Wiz::DB::Constant qw(:all);
use Wiz::DB::Connection;
use Wiz::DB::ResultSet;
use Wiz::Auth;

our $VERSION = '1.0';

my $args = init_args(<<'EOS');
v(version)
h(help)
t:
r:
u:
p:
-prefix:
EOS

my $conf = {
    db_param    => {
        type    => DB_TYPE_MYSQL,
        db      => 'wiz_sbm',
        user    => 'root',
        log     => {
            stderr      => TRUE,
            stack_dump  => TRUE,
            level       => 'warn',
        },
    },
    tables      => {
        user        => 'user',
        user_authz  => 'user_authz',
        role        => 'role',
    },
    hash_alg    => 'sha512_base64',
};

sub main {
    my $conn = new Wiz::DB::Connection($conf->{db_param});
    purify_table_name();

    if ($args->{t} eq 'user') {
        my $pw = Wiz::Auth::_digest_password($args->{p}, $conf->{hash_alg});
        create_user($conn, $args->{u}, $pw);
    }
    elsif ($args->{t} eq 'role') {
        create_role($conn, $args->{r});
    }
    elsif ($args->{t} eq 'user_authz') {
        create_user_authz($conn, $args->{u}, $args->{r});
    }
    elsif ($args->{t} eq 'create') {
        create_user_table($conn);   
        create_role_table($conn);   
        create_user_authz_table($conn);   
    }

    $conn->commit;

    return 0;
}

sub purify_table_name {
    for (keys %{$conf->{tables}}) {
        $conf->{tables}{$_} = $args->{prefix} . $conf->{tables}{$_};
    }
}

sub create_user_table {
    my ($conn) = @_;

    my $t = $conf->{tables}{user};
    $conn->retrieve(qq|SELECT COUNT(id) AS count FROM $t|) and return;
    $conn->execute_only(<<EOS);
CREATE TABLE $t (
    id          INT PRIMARY KEY AUTO_INCREMENT,
    userid      VARCHAR(32) NOT NULL UNIQUE,
    password    VARCHAR(86) NOT NULL
) TYPE=InnoDB;
EOS

    print "CREATED: $conf->{tables}{user}\n";
}

sub create_role_table {
    my ($conn) = @_;

    my $t = $conf->{tables}{role};
    $conn->retrieve(qq|SELECT COUNT(id) AS count FROM $t|) and return;
    $conn->execute_only(<<EOS);
CREATE TABLE $t (
    id          INT PRIMARY KEY AUTO_INCREMENT,
    name        VARCHAR(64) NOT NULL UNIQUE
) TYPE=InnoDB;
EOS

    print "CREATED: $conf->{tables}{role}\n";
}

sub create_user_authz_table {
    my ($conn) = @_;

    my $t = $conf->{tables}{user_authz};
    $conn->retrieve(qq|SELECT COUNT(id) AS count FROM $t|) and return;
    $conn->execute_only(<<EOS);
CREATE TABLE $t (
    id          INT PRIMARY KEY AUTO_INCREMENT,
    user_id     INT REFERENCES user(id),
    role_id     INT REFERENCES role(id),
    UNIQUE(user_id, role_id)
) TYPE=InnoDB;
EOS

    print "CREATED: $conf->{tables}{user_authz}\n";
}

sub create_user {
    my ($conn, $userid, $password) = @_;

    my $t = $conf->{tables}{user};
    if ($conn->retrieve(qq|SELECT COUNT(id) AS count FROM $t WHERE userid='$userid'|)->{count}) {
        print "ALREADY EXISTS USER: $userid\n";
        return;
    }
    $conn->execute_only(qq|INSERT INTO $t (userid, password) VALUES ('$userid', '$password')|);
    print "CREATED USER: $userid\n";
}

sub create_role {
    my ($conn, $name) = @_;

    my $t = $conf->{tables}{role};
    if ($conn->retrieve(qq|SELECT COUNT(id) AS count FROM $t WHERE name='$name'|)->{count}) {
        print "ALREADY EXISTS ROLE: $name";
        return;
    }
    $conn->execute_only(qq|INSERT INTO $t (name) VALUES ('$name')|);
    print "CREATED ROLE: $name\n";
}

sub create_user_authz {
    my ($conn, $userid, $role_name) = @_;

    my $ut = $conf->{tables}{user};
    my $rt = $conf->{tables}{role};
    my $t = $conf->{tables}{user_authz};

    my $user_id = $conn->retrieve(qq|SELECT id FROM $ut WHERE userid='$userid'|)->{id};
    my $role_id = $conn->retrieve(qq|SELECT id FROM $rt WHERE name='$role_name'|)->{id};

    my $d = $conn->retrieve(<<"EOS");
SELECT COUNT(id) AS count FROM $t WHERE user_id='$user_id' AND role_id='$role_id'
EOS
    if ($d->{count}) {
        print "ALREADY EXISTS USER_AUTHZ: $userid - $role_name\n";
        return;
    }
    $conn->execute_only(qq|INSERT INTO $t (user_id, role_id) VALUES ($user_id, $role_id)|);
    print "CREATED USER_AUTHZ: $userid - $role_name\n";
}

sub debug {
    my $msg = shift;

    $args->{d} or return;
    my @caller = caller;
    print "[DEBUG] $msg ($caller[1]:$caller[2])\n";
}

sub init_args {
    my $args_pattern = shift;

    my $args = getopts($args_pattern);

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
USAGE: 


EOS
}

exit main;

__END__
