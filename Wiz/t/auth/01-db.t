#!/usr/bin/perl

use strict;
use warnings;

use lib qw(../../lib);

use Wiz::Test qw(no_plan);
use Wiz::Constant qw(:all);
use Wiz::DB::Constant qw(:all);
use Wiz::DB::Connection;
use Wiz::Auth;
use Wiz::Auth::Constant qw(:status);

chtestdir;

my %conf = (
    tables    => {
        user => "wiz_test_user",
        user_role => "wiz_test_authz",
        role => "wiz_test_role",
    },
);

my %mysql_param = (
	type  	=> DB_TYPE_MYSQL,
	db      => 'test', 
	user    => 'root',
	die     => TRUE,
	log     => {
		stderr      => TRUE,
		stack_dump  => TRUE,
		level       => 'warn',
	},
);

sub main {
	my $conn = new Wiz::DB::Connection(%mysql_param);

    create_table($conn);
    create_test_data($conn);

	my $auth = Wiz::Auth->new(
        use_role        => TRUE,
		db              => $conn,
        use_email_auth  => TRUE,
        password_type   => 'plain',
        table_names     => {
            user            => $conf{tables}{user},
            role            => $conf{tables}{role},
            user_role       => $conf{tables}{user_role},
        },
        fields          => {
            user => {
                id              => 'id',
                userid          => 'userid',
                password        => 'password',
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

    is_undef $auth->execute({ userid => 'xxx', password => 'yyy' }), q|login fail|;
    is_defined $auth->execute({ userid => 'teston@xxxx.xxx.xx', password => 'papas01' });

    my $teston = $auth->execute({userid => 'teston', password => 'papas01'});
    is($teston->userid, 'teston', q|login user object(teston)|);
    ok !$teston->has_role('read'), q|!has_role('read')|;
    is $teston->check_status(AUTH_ACTIVE), 1, q|$teston->check_status(AUTH_ACTIVE)|;

    my $testan = $auth->execute({userid => 'testan', password => 'papas02'});
    is $testan->has_role('read'), 1, q|has_role('read')|;
    is $testan->has_role('write'), 0, q|has_role('write')|;
    is $testan->has_role(['read']), 1, q|has_role(['read'])|;
    is $testan->has_role({read => 1}), 1, q|has_role({read => 1})|;
    is $testan->has_role(-and => ['read']), 1, q|has_role(-and => ['read'])|;
    is $testan->has_role(-and => ['read', 'xxx']), 0, q|has_role(-and => ['read', 'xxx'])|;
    is $testan->has_role(-or => ['read']), 1, q|has_role(-or => ['read'])|;
    is $testan->has_role(-or => ['read', 'xxx']), 1, q|has_role(-or => ['read', 'xxx'])|;

    my $testee = $auth->execute({userid => 'testee', password => 'papas03'});
    is $testee->has_role('read'), 1, q|has_role('read')|;
    is $testee->has_role('write'), 1, q|has_role('write')|;
    is $testee->has_role({ read => 1, write => 1 }), 1,
        q|has_role({ read => 1, write => 1 })|;
    is $testee->has_role({ read => 1, write => 1, xxx => 1 }), 0,
        q|has_role({ read => 1, write => 1, xxx => 1 })|;
    is $testee->has_role(['read']), 1, q|has_role(['read'])|;
    is $testee->has_role(-and => ['read', 'write']), 1, q|has_role(-and => ['read'])|;
    is $testee->has_role(-and => ['read', 'write', 'xxx']), 0,
        q|has_role(-and => ['read', 'write', 'xxx'])|;
    is $testee->has_role(-or => ['read']), 1, q|has_role(-or => ['read'])|;

    my $auth_use_prefix = Wiz::Auth->new(
        prefix      => 'hoge_',
    );
    is $auth_use_prefix->{conf}{table_names}{user}, 'hoge_' . $conf{tables}{user};

    return 0;
}

sub create_test_data {
    my ($conn) = @_;

    create_user($conn, 'teston', 'teston@xxxx.xxx.xx', 'papas01');
    update_user_status($conn, 'teston', AUTH_ACTIVE);
    create_user($conn, 'testan', 'testan@xxxx.xxx.xx', 'papas02');
    create_user($conn, 'testee', 'testee@xxxx.xxx.xx', 'papas03');
    create_role($conn, 'read');
    create_role($conn, 'write');
    create_user_role($conn, 'testan', 'read');
    create_user_role($conn, 'testee', 'read');
    create_user_role($conn, 'testee', 'write');
    $conn->commit;
}

sub create_table {
    my ($conn) = @_;

    if ($conn->table_exists($conf{tables}{user})) {
        $conn->execute_only("DROP TABLE $conf{tables}{user}");
    }

    $conn->execute_only(<<"EOS");
CREATE TABLE $conf{tables}{user} (
    id          INT PRIMARY KEY AUTO_INCREMENT,
    userid      VARCHAR(32) NOT NULL UNIQUE,
    email       VARCHAR(32) NOT NULL UNIQUE,
    password    VARCHAR(86) NOT NULL,
    status      INTEGER     DEFAULT 0,
    delete_flag TINYINT(1)  DEFAULT 0
) TYPE=InnoDB;
EOS

    if ($conn->table_exists($conf{tables}{user_role})) {
        $conn->execute_only("DROP TABLE $conf{tables}{user_role}");
    }

    $conn->execute_only(<<"EOS");
CREATE TABLE $conf{tables}{user_role} (
    id          INT PRIMARY KEY AUTO_INCREMENT,
    user_id     INT REFERENCES user(id),
    role_id     INT REFERENCES role(id),
    UNIQUE(user_id, role_id)
) TYPE=InnoDB;
EOS

    if ($conn->table_exists($conf{tables}{role})) {
        $conn->execute_only("DROP TABLE $conf{tables}{role}");
    }

    $conn->execute_only(<<"EOS");
CREATE TABLE $conf{tables}{role} (
    id          INT PRIMARY KEY AUTO_INCREMENT,
    name        VARCHAR(64) NOT NULL UNIQUE
) TYPE=InnoDB;
EOS
}

sub create_user {
    my ($conn, $userid, $email, $password) = @_;

    $conn->retrieve(qq|SELECT COUNT(id) AS count FROM $conf{tables}{user} WHERE userid='$userid'|)->{count} and return;
    $conn->execute_only(qq|INSERT INTO $conf{tables}{user} (userid, email, password) VALUES ('$userid', '$email', '$password')|);
}

sub update_user_status {
    my ($conn, $userid, $status) = @_;

    my $user_id = $conn->retrieve(qq|SELECT id FROM $conf{tables}{user} WHERE userid='$userid'|)->{id};
    $conn->execute_only(qq|UPDATE $conf{tables}{user} SET status=$status WHERE id=$user_id|);
}

sub create_role {
    my ($conn, $name) = @_;

    $conn->retrieve(qq|SELECT COUNT(id) AS count FROM $conf{tables}{role} WHERE name='$name'|)->{count} and return;
    $conn->execute_only(qq|INSERT INTO $conf{tables}{role} (name) VALUES ('$name')|);
}

sub create_user_role {
    my ($conn, $userid, $role_name) = @_;

    my $user_id = $conn->retrieve(qq|SELECT id FROM $conf{tables}{user} WHERE userid='$userid'|)->{id};
    my $role_id = $conn->retrieve(qq|SELECT id FROM $conf{tables}{role} WHERE name='$role_name'|)->{id};
    $conn->retrieve(qq|SELECT COUNT(id) AS count FROM $conf{tables}{user_role} WHERE user_id='$user_id' AND role_id='$role_id'|)->{count} and return;
    $conn->execute_only(qq|INSERT INTO $conf{tables}{user_role} (user_id, role_id) VALUES ($user_id, $role_id)|);
}

exit main;

