package Wiz::DB::Cluster;

use strict;
no warnings;

=head1 NAME

Wiz::DB::Cluster - for DB cluster

=head1 VERSION

version 1.0

=cut

our $VERSION = '1.0';

=head1 SYNOPSIS

 my %mysql_param = (
     type                => DB_TYPE_MYSQL,
     db                  => 'test',
     user                => 'root',
     priority_flag       => ENABLE,
     read_priority_flag  => ENABLE,
     pooling             => TRUE,
     log => {
         stderr => 1,
     },
     master  => [
         {
             host        => 'master01.db',
             min_idle    => 4,
         },
     ],
     slave   => [
         {
             host        => 'slave01.db',
             min_idle    => 2,
         },
         {
             host        => 'slave02.db',
             min_idle    => 2,
         },
     ],
 );
 
 my $cluster = new Wiz::DB::Cluster(%mysql_param);
 
 my $master_conn01 = $cluster->get_master;
 my $slave_conn01 = $cluster->get_slave;
 my $slave_conn02 = $cluster->get_slave;
 my $slave_conn03 = $cluster->get_slave;

=head2 USE CACHE

 my %mysql_param = (
     type                => DB_TYPE_MYSQL,
     db                  => 'test',
     user                => 'root',
     pooling             => TRUE,
     log => {
         stderr => 1,
     },
     master  => [
         {
             host            => '192.168.0.1',
             min_idle        => 4,
         },
     ],
     slave   => [
         {
             host            => '192.168.0.2',
             min_idle        => 2,
         },
         {
             host            => '192.168.0.3',
             host            => '127.0.0.1',
             min_idle        => 2,
         },
     ],
     cache   => {
         type    => 'Memcached::libmemcached',
         conf    => {
             servers => [qw(
                 127.0.0.1:11211
             )],
         },
     },
 );

=cut

use base qw(Class::Accessor::Fast Wiz::DB::Base);

use Wiz qw(get_hash_args get_log_from_conf);
use Wiz::Util::Array qw(array_sum array_random array_random_with_priority);
use Wiz::Constant qw(:common);
use Wiz::DB::Connection;
use Wiz::DB::ConnectionPool;
use Wiz::DB::Constant qw(:all);
use Wiz::DB::ConnectionFactory;

=head1 ACCESSORS

 label

=cut

__PACKAGE__->mk_accessors(qw(label));

my @member_names = qw(
pooling
type
log
max_active
min_idle
max_idle
max_idle_time
max_connection_reuse
blocking_mode
max_try_connection
max_wait_time
);

my %quota = (
    max_priority        => 10,
    max_read_priority   => 10,
);

my %default = (
    priority_flag       => DISABLE,
    read_priority_flag  => DISABLE,
    pooling             => FALSE,
    priority            => 10,
    read_priority       => 10,
);

our @CONFS = keys %default;

=head1 CONSTRUCTOR

=head2 new(%conf) or new(\%conf)

 my %conf = (
     priority_flag   => ENABLE,
     log         => {
         path        => 'logs/db.log',
         stderr      => TRUE,
     },
     master      => [
         {
             type        => DB_TYPE_POSTGRESQL,
             host        => 'master01.db',
             db          => 'test,
             user        => 'test',
             priority    => 10,
         },
         {
             type        => DB_TYPE_POSTGRESQL,
             host        => 'master02.db',
             db          => 'test,
             user        => 'test',
             priority    => 5,
         },
     ],
     slave      => [
         {
             type    => DB_TYPE_POSTGRESQL,
             host    => 'slave01.db',
             db      => 'test,
             user    => 'test',
         },
         {
             type    => DB_TYPE_POSTGRESQL,
             host    => 'slave02.db',
             db      => 'test,
             user    => 'test',
         },
     ],
 )
 
 my $cluster = new Wiz::DB::Cluster(%conf);

If there is no the log's definition under master_db or slave_db, $conf{log} is used as default.
The "priority" can specify the priority when it get connection.
You can use it when machine's spec is different each other.
The value of priority is max = 10, min = 0 and default is 10.
But, you must to set value "priority_flag => ENABLE" when you use "priority".

In the above example, it gets the "master01.db" at a rate of 10/15 and
it gets the "master02.db" at a rate of 5/15.

When you make it read master server, you use the following.

 get_master_or_slave

This method get random connection from master or slave.

In the case too, "priority" enables.

In the example, it give you the master01 at a rate of 10/35, mastre02 is 5/35, slave01 is 10/35.

But the master server's main process is to write.
When you are doing self setting, many processing time spend to read.
Add the following value to config data for constructor when you don't want to do so.

 read_priority_flag = ENABLE
_info
And set "read_priority"

 {
     type            => DB_TYPE_POSTGRESQL,
     host            => 'master01.db',
     db              => 'test,
     user            => 'test',
     priority        => 10,
     read_priority   => 6,
 },
 {
     type            => DB_TYPE_POSTGRESQL,
     host            => 'master02.db',
     db              => 'test,
     user            => 'test',
     priority        => 5,
     read_priority   => 3,
 },

In the case, when you call "get_master_or_slave",
you get the member01 at a rate of 6/29, member02 is 3/29, slave01 is 10/29.

=cut

sub new {
    my $self = shift;
    my $conf = get_hash_args(@_);

    $conf->{log_base_dir} and $conf->{base_dir} = $conf->{log_base_dir};
    my $log = get_log_from_conf($conf);

    _complement_conf($conf);

    my $instance = bless {
        map { $_ => $conf->{$_} ? $conf->{$_} : $default{$_} } keys %default
    }, $self;

    my ($master_factories, $master_priorities, $master_read_priorities) = 
        _get_factories($conf, $log, MASTER);

    my ($slave_factories, $slave_priorities) =
        _get_factories($conf, $log, SLAVE);

    $instance->{conf} = $conf;
    $instance->{log} = $log;
    $instance->{master_factories} = $master_factories;
    $instance->{slave_factories} = $slave_factories;
    $instance->{error} = undef;
    $instance->{cache} = _get_cache($conf, $log);

    $instance->_set_priority_info(
        $conf, $master_factories, $slave_factories, $master_priorities,
        $master_read_priorities, $slave_priorities);

    return $instance;
}

=head1 METHODS

=head2 $dbc = get_master

Returns the db connection of the master server.

=cut

sub get_master {
    my $self = shift;

    my $factory = undef;
    if ($self->{priority_flag} == ENABLE) {
        $factory = array_random_with_priority(
            $self->{master_factories},
            $self->{master_priorities},
            $self->{master_priorities_sum});
    }
    else {
        $factory = array_random($self->{master_factories});
    }
    if (not defined $factory) {
        $self->write_error("not exists master factory");
        return undef;
    }
    if (defined $self->{label}) {
        my $conn = $factory->create;
        $conn->label($self->{label});
        return $conn;
    }
    else {
        return $factory->create;
    }
}

=head2 $dbc = get_slave

Returns the db connection of the slave server.

=cut

sub get_slave {
    my $self = shift;

    my $factory = undef;
    my $slave_flag = TRUE;
    if ($self->{read_priority_flag} == ENABLE) {
        ($factory, my $idx) = array_random_with_priority(
            $self->{factories},
            $self->{priorities},
            $self->{priorities_sum});

        $idx < @{$self->{master_factories}} and $slave_flag = FALSE;
    }
    elsif ($self->{priority_flag} == ENABLE) {
        $factory = array_random_with_priority(
            $self->{slave_factories},
            $self->{slave_priorities},
            $self->{slave_priorities_sum});
    }
    else {
        $factory = array_random($self->{slave_factories});
    }
    if (not defined $factory) { return $self->get_master; }
    my $conn = $factory->create; 
    $conn->{is_slave} = $slave_flag;
    $conn->label($self->{label});
    return $conn;
}

=head2 $dbc = get_master_or_slave

Returns the master or slave connection.

=cut

sub get_master_or_slave {
    my $self = shift;

    ($self->{read_priority_flag} == DISABLE or 
        $self->{priority_flag} == DISABLE) and return undef;
    
    my $factory = array_random_with_priority(
        $self->{factories},
        $self->{priorities},
        $self->{priorities_sum});

    my $conn = $factory->create;
    $conn->{is_slave} = TRUE;
    return $conn;
}

=head2 $dbc = cache

Returns cache.

=cut

sub cache {
    my $cache = shift->{cache};
    defined $cache ? $cache->cache : undef;
}

=head2 close

Closes all connection

=cut

sub close {
    my $self = shift;

    for (@{$self->{master_factories}}) { $_->force_close; }
    for (@{$self->{slave_factories}}) { $_->force_close; }
}

=head2 status_dump

For debugging

=cut

sub status_dump {
    my $self = shift;

    print "[ MASTER DB HANDLE ]\n";
    for (@{$self->{master_factories}}) { $_->status_dump; }

    print "[ SLAVE DB HANDLE ]\n";
    for (@{$self->{slave_factories}}) { $_->status_dump; }
}

sub is_controller {
    return FALSE;
}

sub DESTROY {
    my $self = shift;
    $self->close;
}

#----[ private ]------------------------------------------------------
sub _set_priority_info {
    my $self = shift;
    my ($conf, $master_factories, $slave_factories, 
        $master_priorities, $master_read_priorities, $slave_priorities) = @_;

    $conf->{priority_flag} != ENABLE and return;

    my $master_priorities_sum = array_sum($master_priorities);
    my $slave_priorities_sum = array_sum($slave_priorities);

    if ($conf->{read_priority_flag} == ENABLE) {
        $self->{master_priorities} = $master_read_priorities;
        $self->{master_priorities_sum} = array_sum($master_read_priorities);

        $master_priorities = $master_read_priorities;
    }
    else {
        $self->{master_priorities} = $master_priorities;
        $self->{master_priorities_sum} = array_sum($master_priorities);
    }

    $self->{priority_flag} = ENABLE;

    $self->{slave_priorities} = $slave_priorities;
    $self->{slave_priorities_sum} = array_sum($slave_priorities);

    $self->{factories} = [ @$master_factories, @$slave_factories ]; 
    $self->{priorities} = [ @$master_priorities, @$slave_priorities ];
    $self->{priorities_sum} = 
        $self->{master_priorities_sum} + $self->{slave_priorities_sum};
}

#----[ private static ]-----------------------------------------------
sub _complement_conf {
    my $conf = shift;

    my @confs = (
        @Wiz::DB::Connection::CONFS,
        @Wiz::DB::ConnectionPool::CONFS,
        @Wiz::DB::ConnectionFactory::CONFS,
        'base_dir',
    );

    if (not exists $conf->{master} and not exists $conf->{slave}) {
        my %new = ();
        for (@confs) { $new{$_} = $conf->{$_}; }
        $conf->{master} = [ \%new ];
    }
    elsif (exists $conf->{master} and ref $conf->{master} eq 'HASH') {
        $conf->{master} = [ $conf->{master} ];
    }
    else {
        for my $c (@{$conf->{master}}, @{$conf->{slave}}) {
            for (keys %default) {
                defined $c->{$_} or $c->{$_} = $default{$_};
            }

            for (@confs) {
                defined $c->{$_} or $c->{$_} = $conf->{$_};
            }
        }
    }
}

sub _get_factories {
    my ($conf, $log, $type) = @_;

    my $confs = ($type == MASTER) ? $conf->{master} : $conf->{slave};
    my @ret = ();
    my @priority = ();
    my @read_priority = ();
    for my $c (@$confs) {
        if (defined $c->{log}) { $c->{base_dir} = $conf->{base_dir}; }
        else { $c->{log} = $log; }
        for (@member_names) {
            defined $c->{$_} or $c->{$_} = $conf->{$_};
        }
        push @ret, new Wiz::DB::ConnectionFactory($c);
        if ($conf->{priority_flag}) {
            $c->{priority} eq '' and $c->{priority} = $quota{max_priority};
            push @priority, 
                ($c->{priority} > $quota{max_priority} ? 
                    $quota{max_priority} : $c->{priority});
            if ($conf->{read_priority_flag}) {
                $c->{read_priority} eq '' and $c->{read_priority} = $quota{max_read_priority};
                push @read_priority, 
                    ($c->{read_priority} > $quota{max_read_priority} ? 
                        $quota{max_read_priority} : $c->{read_priority});
            }
        }
    }
    return (\@ret, \@priority, \@read_priority);
}

sub _get_cache {
    my ($conf, $log) = @_;
    defined $conf->{cache} or return;
    $conf->{cache}{log} ||= $log;
    return new Wiz::DB::Connection({
        cache => $conf->{cache}
    });
}

=head1 SEE ALSO

L<Wiz::DB::ConnectionFactory>

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
