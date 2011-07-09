package Wiz::DB::ConnectionPool;

use strict;
use warnings;

=head1 NAME

Wiz::DB::ConnectionPool - Manages DB Connection Pool

=head1 VERSION

version 1.0

=cut

our $VERSION = '1.0';

=head1 SYNOPSIS

This is a class for managing several works to handle connection pooling.
Retrieving ConnectionPoolObject enables you to use pooled connection.

 use Wiz::DB::Constant qw(:all);
 use Wiz::DB::ConnectionPool;
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
     min_idle    => 2,
     max_idle    => 4,
 );
 
 my $cp = new Wiz::DB::ConnectionPool(%conf);
 my $dbc = $cp->get_connection;
 
 my $rs = $dbc->execute("SELECT * FROM test");
 while ($rs->next) {
     warn $rs->get('id');
 }
 
 $rs->close;                    
 $dbc->close;

=cut

use Time::HiRes qw(usleep);

use base qw(Wiz::DB::Base);

use Wiz qw(get_hash_args get_log_from_conf);
use Wiz::Constant qw(:common);
use Wiz::ReturnCode qw(:all);
use Wiz::DB::Constant qw(:pool);
use Wiz::DB::Connection;
use Wiz::DB::ConnectionPoolObject;

my %default = (
    max_active              => 8,
    min_idle                => 4,
    max_idle                => 8,
    max_idle_time           => 1800,
    max_connection_reuse    => 5,
    blocking_mode           => DB_POOL_NON_BLOCKING,
    max_try_connection      => 10,
    max_wait_time           => 100,
);

=head1 ACCESSOR

 max_active
 min_idle
 max_idle
 max_idle_time
 max_connection_reuse
 blocking_mode
 max_try_connection
 max_wait_time

=head2 about max_wait_time

max_wait_time is handled as msec externally, but as usec internally.
Never manipulate it directly from external. Instead, use accessor. 

=head1 GETTER

 active_count
 idle_count

=cut

our @CONFS = keys %default;

__PACKAGE__->mk_accessors((grep { $_ !~ /max_wait_time/ and $_ } @CONFS),
    qw(conf idle_count idle_objs active_count active_objs));

=head1 CONSTRUCTOR

=head1 new(%conf) or new(\%conf)

$conf: Params required by Wiz::DB::Connection, and in addition the followings.
(the hash value is the default value)

=over 4

=item * max_active => 8

The maximum number of connections being retrieved from connection pool simultaneously.

=item * min_idle => 0

The minimum number of stand-by connections.

=item * max_idle => 8

The maximum number of idle connections in pool

=item * max_idle_time => 1800

The limit of connection lifetime in pool(second).

=item * max_connection_reuse => 5

The maximun time of reusing connection retrieved from pool.

=item * blocking_mode => DB_POOL_NON_BLOCKING,

Blocking mode when there's no idle connection in pool.
(Actually, it depends also on max_active.) 

 DB_POOL_NON_BLOCKING   Non blocking, returns undef immediately.
 DB_POOL_BLOCKING       Continues Blocking until one of connection turns available.

=item * max_try_connection => 10

The maximum number of trial to retrieve connection while blocking.

=item * max_wait_time => 100

Wait time at a time while blocking.

=back

=cut

sub new {
    my $self = shift;
    my $conf = _init_conf(get_hash_args(@_));
    my $log = get_log_from_conf($conf);

    my $instance = bless {
        conf            => $conf,
        log             => $log,
        idle_count      => 0,
        idle_objs       => undef,
        active_count    => 0,
        active_objs     => undef,
    }, $self;

    for (keys %default) {
        $instance->{$_} = defined $conf->{$_} ? $conf->{$_} : $default{$_};
    }

    if ($conf->{min_idle} > 0) {
        for (1..$conf->{min_idle}) { $instance->create_idle; }
    }

    $instance->max_wait_time(19);

    return $instance;
}

=head1 METHODS

=head2 $dbc = get_connection()

Returns ConnectionPoolObject, which is one of the pooled connection.
User of this class may handle it like a normal Connection object.("use Wiz::DB::ConnectionPoolObject" is needed.)  

$dbc: instance of Wiz::DB::ConnectionPoolObject

=cut

sub get_connection {
    my $self = shift;

    $self->clear_error;

    my $cpo = undef;
    if ($self->{active_count} < $self->{max_active}) {
        if ($self->{idle_count} > 0) { $cpo = $self->rent; }
        else { $cpo = $self->create_active; }
    }
    # waiting available connection
    else {
        if ($self->{blocking_mode} == DB_POOL_NON_BLOCKING) {
            $self->write_error("max active over");
        }
        elsif ($self->{blocking_mode} == DB_POOL_BLOCKING) {
            for (my $i = 0; $i < $self->{max_try_connection}; $i++) {
                if ($self->{active_count} < $self->{max_active}) {
                    $cpo = $self->create_active;
                    last;
                }

                usleep($self->{max_wait_time}); 
            }

            $self->write_error(
                "waited $self->{max_try_connection} times but a space not vacant.");
        }
    }

    $self->idle_clean;

    return $cpo;
}

sub max_wait_time {
    my $self = shift;
    my $time = shift;

    return $time ? ($self->{max_wait_time} = $time * 1000) : $self->{max_wait_time} / 1000;
}

=head2 close()

Closes all connections issued by its instance.
It will be called from DESTROY anyway.

=cut

sub close {
    my $self = shift;

    for (keys %{$self->{active_objs}}) {
        my $cpo = $self->{active_objs}{$_};
        defined $cpo and $cpo->force_close;
    }
    $self->{active_objs} = undef;
    $self->{active_count} = 0;

    for (keys %{$self->{idle_objs}}) {
        my $cpo = $self->{idle_objs}{$_};
        defined $cpo and $cpo->force_close;
    }
    $self->{idle_objs} = undef;
    $self->{idle_count} = 0;
}

=head2 status_dump()

Method for debug. Use to check pooling state.

=cut

sub status_dump {
    my $self = shift;

    print <<EOS;
===== [ CONNECTION POOL STATUS DUMP ]==================================
MAX ACTIVE: $self->{max_active}
MIN IDLE: $self->{min_idle}
MAX IDLE: $self->{max_idle}
MAX IDLE TIME: $self->{max_idle_time}
BLOCKING MODE: $self->{blocking_mode}
MAX CONNECTION REUSE: $self->{max_connection_reuse}
MAX TRY CONNECTION: $self->{max_try_connection}
MAX WAIT TIME: $self->{max_wait_time}

ACTIVE COUNT: $self->{active_count}
IDLE COUNT: $self->{idle_count}
=======================================================================

EOS
}

sub DESTROY {
    my $self = shift;
    $self->close;
}

#----[ private ]------------------------------------------------------
sub create_idle {
    my $self = shift;

    my $cpo = new Wiz::DB::ConnectionPoolObject($self->conf, $self);
    if (return_code_is($cpo, undef)) {
        $self->error($cpo->message);
        return $cpo;
    };

    $self->{idle_objs}{$cpo} = $cpo;
    ++($self->{idle_count});
}

sub create_active {
    my $self = shift;

    my $cpo = new Wiz::DB::ConnectionPoolObject($self->conf, $self);
    if (return_code_is($cpo, undef)) {
        $self->error($cpo->message);
        return $cpo;
    };

    $self->{active_objs}{$cpo} = $cpo;
    ++($self->{active_count});
    return $cpo;
}

#  issuing Connection
sub rent {
    my $self = shift;

    $self->idle_clean;

    if ($self->{idle_count} <= 0) { return $self->create_active; }

    --($self->{idle_count});
    ++($self->{active_count});

    for (keys %{$self->{idle_objs}}) {
        my $cpo = $self->{idle_objs}{$_};
        $cpo->increment_used_count;
        delete $self->{idle_objs}{$_};
        $self->{active_objs}{$_} = $cpo;
        return $cpo;
    }

    return undef;
}

#  Freeing or pooling connection 
sub release {
    my $self = shift;
    my $cpo = shift;

    $cpo or return;

    if (exists $self->{idle_objs}{$cpo}) {
        $self->write_error(
            "already close connection pool object. you call close twice.");
        return undef;
    }

    $self->clear_error;

    delete $self->{active_objs}{$cpo};
    --($self->{active_count});

    #  Pooling when there are some idle connection and cpo doesn't reach max.
    if ($self->{idle_count} < $self->{max_idle} and
        $cpo->used_count < $self->{max_connection_reuse}) {

        # Record the time it becomes idle.
        $cpo->date_refresh;
        $self->{idle_objs}{$cpo} = $cpo;
        ++($self->{idle_count});
    }
    else {
        $cpo->force_close;
        --($self->{idle_count});
    }

    $self->idle_clean;
}

sub idle_clean {
    my $self = shift;

    my $now = time;
    for (keys %{$self->{idle_objs}}) {
        my $cpo = $self->{idle_objs}{$_};
        defined $cpo or next;
        if ($now > $cpo->{last_update} + $self->{max_idle_time}) {
            delete $self->{idle_objs}{$_};
            $cpo->force_close;
            --($self->{idle_count});
        }
    }

    my $n = $self->{min_idle} - $self->{idle_count};
    if ($n) { for (1..$n) { $self->create_idle; } }
}

#----[ private ]-------------------------------------------------------
sub _init_conf {
    my $conf = shift;

    for (keys %default) {
        defined $conf->{$_} or $conf->{$_} = $default{$_};

        # microsecond to millisecond
        $_ eq "max_wait_time" and $conf->{$_} *= 1000;
    }

    $conf->{min_idle} > $conf->{max_idle} and
        $conf->{min_idle} = $conf->{max_idle};

    return $conf;
}

=head1 SEE ALSO

L<Wiz::DB::Connection>

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

