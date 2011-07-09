package Wiz::DB::Cluster::Controller;

use strict;
no warnings;

=head1 NAME

Wiz::DB::Cluster::Controller - Controll clusters

=head1 VERSION

version 1.0

=cut

our $VERSION = '1.0';

=head1 SYNOPSIS

 my %mysql_param = (
     db          => 'test',
     user        => 'HOGEHOGE',
     clusters    => {
         cluster01   => \%mysql_param01,
         cluster02   => \%mysql_param02,
     },
 );
 
 my $cc = new Wiz::DB::Cluster::Controller(%mysql_param);

\%mysql_param01, \%mysql_param02 are config of Wiz::DB::Cluster.

You can get each cluster's connection holded by $cc.

 my $master_conn_01 = $cc->get_master('cluster01');
 my $master_conn_02 = $cc->get_master('cluster02');

=head1 DESCRIPTION

This modules controll clusters.
It read cofifuration of L<Wiz::DB::Cluster> and handle connection of each cluster.

=head1 HOW TO CONFIGURE CLUSTER CONTROLLER?

There are some exapmles how to configure Wiz::Cluster::Controller.
Basic config structure is the following.

 my %mysql_param = (
     db          => 'test',
     user        => 'HOGEHOGE',
     clusters    => {
         cluster01   => \%mysql_param01,
         cluster02   => \%mysql_param02,
         # ...
     },
 );

db is database name. user is database user name.
clusters is hash ref; key is the name of cluster and value is cluster configuration.
If cluster configuration has no db and/or user,
user and db in Cluster::Controller's configuration are used.

=head2 ALL CONFIG DATA IN THE SCRIPT

 my %mysql_param01 = (
     db                  => 'test',
     user                => 'root',
     type                => DB_TYPE_MYSQL,
     priority_flag       => ENABLE,
     read_priority_flag  => ENABLE,
     pooling             => TRUE,
     log => {
         stderr  => 1,
         path    => 'logs/cluster01.log',
     },
     master  => [
         {
             host            => '192.168.0.1',
             min_idle        => 4,
             priority        => 10,
             read_priority   => 10,
         },
     ],
     slave   => [
         {
             host            => '192.168.0.2',
             min_idle        => 2,
             priority        => 10,
         },
         {
             host            => '192.168.0.3',
             user            => 'root',
             min_idle        => 2,
             priority        => 1,
         },
     ],
 );
 
 my %mysql_param02 = (
     db                  => 'test',
     user                => 'root',
     type                => DB_TYPE_MYSQL,
     priority_flag       => ENABLE,
     read_priority_flag  => ENABLE,
     pooling             => FALSE,
     log => {
         stderr  => 1,
         path    => 'logs/cluster02.log',
     },
     master  => [
         {
             host            => '192.168.0.4',
             min_idle        => 4,
         },
     ],
     slave   => [
         {
             host            => '192.168.0.5',
             min_idle        => 2,
         },
         {
             host            => '192.168.0.6',
             min_idle        => 2,
         },
     ],
 );

=head2 CLUSTER CONFIG DATA IN OUTER FILE

You can write the config in files.

 my %mysql_param_by_file = (
     type        => DB_TYPE_MYSQL,
     db          => 'test',
     user        => 'root',
     log => {
         stderr  => 1,
         path    => 'logs/cluster_controller.log',
     },
     clusters    => {
         cluster01   => 'conf/cluster01.pdat',
         cluster02   => 'conf/cluster02.pdat',
     },
 );

=head2 ALL CONFIG DATA IN OUTER FILE

Of course, you can write all config data in file.
 
 my $cc = new Wiz::DB::Cluster::Controller(_conf => 'conf/cluster.pdat');

=head3 conf/cluster.pdat example

 {
     type        => 'mysql',
     db          => 'test',
     user        => 'root',
     log => {
         stderr  => 1,
         path    => 'logs/cluster_controller.log',
     },
     clusters    => {
         cluster01   => 'conf/cluster01.pdat',
         cluster02   => 'conf/cluster02.pdat',
     },
 }

=head2 USE CACHE

 my %mysql_param01 = (
     db                  => 'test',
     user                => 'root',
     type                => DB_TYPE_MYSQL,
     priority_flag       => ENABLE,
     read_priority_flag  => ENABLE,
     pooling             => FALSE,
     log => {
         stderr  => 1,
         path    => 'logs/cluster01.log',
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
             min_idle        => 2,
         },
     ],
     cache   => {
         type    => 'Memcached::libmemcached',
         conf    => {
             servers => [qw(
                 127.0.0.1:12345
             )],
         },
     },
 );

=head2 CLUSTER GROUP

If you need grouping clusters, do the following.

 my %mysql_param = (
     type        => DB_TYPE_MYSQL,
     db          => 'test',
     user        => 'root',
     log => {
         stderr  => 1,
         path    => 'logs/cluster_controller.log',
     },
     clusters    => {
         footstamp01    => 'conf/footstamp01.pdat',
         footstamp02    => 'conf/footstamp02.pdat',
         article01      => 'conf/article01.pdat',
         article02      => 'conf/article02.pdat',
     },
     group      => {
        footstamp  => [qw(footstamp01 footstamp02)],
        article => [qw(article01 article02)],
     },
 );
 my $cc = new Wiz::DB::Cluster::Controller(%mysql_param);
 my $master = $cc->get_master_in_group($label);
 my $slave = $cc->get_slave_in_group($label);

You can omit "group" definition.

You will give name the following,

    footstamp01
    footstamp02
    footstamp03
    ....

then the module treat as same group name "footstamp".

=head2 CLUSTER GROUP AND PRIORITY

 my %mysql_param = (
     type                => DB_TYPE_MYSQL,
     db                  => 'test',
     user                => 'root',
     priority_flag       => ENABLE,
     log => {
         stderr  => 1,
         path    => 'logs/cluster_controller.log',
     },
     clusters    => {
         footstamp01    => {
             priority   => 10,
             _conf  => 'conf/footstamp01.pdat',
         },
         footstamp02    => {
             priority   => 5,
             'conf/footstamp02.pdat',
         }
         article01      => 'conf/article01.pdat',
         article02      => 'conf/article02.pdat',
     },
 );

In the case, when you call "get_master_in_group('footstamp')",
you get the footstamp01 at a rate of 2/3, footstamp02 is 1/3.

When you use the function, don't forget to define priority_flag = TRUE.

=head2 CLUSTERS DEFINITION INTO FILE

 my %mysql_param = (
     type        => DB_TYPE_MYSQL,
     db          => 'test',
     user        => 'root',
     log => {
         stderr  => 1,
         path    => 'logs/cluster_controller.log',
     },
     clusters    => [qw(
        conf/footstamp.pdat conf/article.pdat
     )],
     group      => {
        footstamp  => [qw(footstamp01 footstamp02)],
        article => [qw(article01 article02)],
     },
 );

=head3 conf/footstamp.pdat example

 {
     footstamp01   => {
         log => {
             stderr  => 1,
             path    => 'logs/cluster01.log',
         },
         master  => [
             {
                 host            => '192.168.0.1',
                 min_idle        => 4,
                 priority        => 10,
                 read_priority   => 10,
             },
         ],
         slave   => [
             {
                 host            => '192.168.0.2',
                 min_idle        => 2,
                 priority        => 10,
             },
             {
                 host            => '192.168.0.3',
                 min_idle        => 2,
                 priority        => 1,
             },
         ],
     },
     footstamp02   => {
         log => {
             stderr  => 1,
             path    => 'logs/cluster02.log',
         },
         master  => [
             {
                 host            => '192.168.0.4',
                 min_idle        => 4,
             },
         ],
         slave   => [
             {
                 host            => '192.168.0.5',
                 min_idle        => 2,
             },
             {
                 host            => '192.168.0.6',
                 min_idle        => 2,
             },
         ],
     },
 }

=cut

use base qw(Wiz::DB::Base);

use Wiz qw(get_hash_args get_log_from_conf);
use Wiz::Constant qw(:common);
use Wiz::Util::Array qw(array_sum array_random array_random_with_priority);
use Wiz::Util::File qw(file_data_eval);
use Wiz::DB::Constant qw(:all);
use Wiz::DB::Cluster;

my %quota = (
    max_priority        => 10,
);

sub new {
    my $self = shift;
    my $conf = get_hash_args(@_);
    _complement_conf($conf);
    my %clusters = ();
    if (exists $conf->{clusters}) {
        my %cs = %{$conf->{clusters}};
        for (keys %cs) {
            if (ref $cs{$_}) {
                $conf->{log_base_dir} and $conf->{base_dir} = $conf->{log_base_dir};
                defined $conf->{base_dir} and $cs{$_}{base_dir} = $conf->{base_dir};
                $clusters{$_} = new Wiz::DB::Cluster($cs{$_});
            }
            else {
                $clusters{$_} = new Wiz::DB::Cluster(_conf => $cs{$_});
            }
        }
    }
    else {
        return new Wiz::DB::Cluster($conf);
    }
    my $group = defined $conf->{group} ? $conf->{group} : _get_group(\%clusters);
    my $priority = _get_priority($conf, $group);
    return bless {
        clusters        => \%clusters,
        group           => $group,
        priority        => $priority,
        priority_sum    => _get_priority_sum($priority),
        use_priority    => $conf->{priority_flag},
    }, $self;
}

=head1 METHOD

=head2 $conn = get_master($label)

Returns master connection.

=cut

sub get_master {
    my $self = shift;
    my ($label) = @_;
    $label ||= 'default';
    my $cluster = $self->{clusters}{$label};
    defined $cluster or $self->write_error(q|don't have clusters|);
    my $conn = $cluster->get_master;
    $conn->label($label);
    return $conn;
}

=head2 $conn = get_slave($label)

Returns slave connection.

=cut

sub get_slave {
    my $self = shift;
    my ($label) = @_;
    $label ||= 'default';
    my $cluster = $self->{clusters}{$label};
    defined $cluster or $self->write_error(q|don't have clusters|);
    my $conn = $cluster->get_slave;
    $conn->label($label);
    return $conn;
}

=head2 $conn = get_master_or_slave($label)

Returns master or slave connection, when read_priority_flag == ENABLE and priority_flag == ENABLE

=cut

sub get_master_or_slave {
    my $self = shift;
    my ($label) = @_;
    $label ||= 'default';
    my $cluster = $self->{clusters}{$label};
    defined $cluster or $self->write_error(q|don't have clusters|);
    my $conn = $cluster->get_master_or_slave;
    $conn->label($label);
    return $conn;
}

=head2 $conn = get_master_in_group($group_label)

Returns master connection.

=cut

sub get_master_in_group {
    my $self = shift;
    my ($group_label) = @_;
    my $choose = $self->get_label_by_group($group_label);
    my $cluster = $self->{clusters}{$choose};
    if (!defined $cluster) {
        $self->write_error(q|don't have clusters|);
        return;
    }
    else {
        $cluster->label($choose);
        return $cluster->get_master;
    }
}

=head2 $conn = get_slave_in_group($group_label)

Returns slave connection.

=cut

sub get_slave_in_group {
    my $self = shift;
    my ($group_label) = @_;

    my $choose = $self->get_label_by_group($group_label);
    my $cluster = $self->{clusters}{$choose};
    if (!defined $cluster) {
        $self->write_error(q|don't have clusters|);
        return;
    }
    else {
        $cluster->label($choose);
        return $cluster->get_slave;
    }
}

=head2 $conn = get_master_or_slave_in_group($group_label)

Returns master or slave connection, when read_priority_flag == ENABLE and priority_flag == ENABLE

=cut

sub get_master_or_slave_in_group {
    my $self = shift;
    my ($group_label) = @_;

    my $choose = $self->get_label_by_group($group_label);
    my $cluster = $self->{clusters}{$choose};
    if (!defined $cluster) {
        $self->write_error(q|don't have clusters|);
        return;
    }
    else {
        $cluster->label($choose);
        return $cluster->get_master_or_slave;
    }
}

=head2 $label = get_label_by_group($group_label)

Returns cluster label from group label.

=cut

sub get_label_by_group {
    my $self = shift;
    my ($group_label) = @_;

    return $self->{use_priority} ?  
        array_random_with_priority($self->{group}{$group_label}, $self->{priority}{$group_label}, $self->{priority_sum}{$group_label}) :
        array_random($self->{group}{$group_label});
}

=head2 $cache = cache($label)

Retruns cache.

=cut

sub cache {
    my $self = shift;
    my ($label) = @_;
    my $cluster = $self->{clusters}{$label};
    defined $cluster or $self->write_error(q|don't have clusters|);
    $cluster->cache;
}

=head2 close

Closes all cluster owned by myself.

=cut

sub close {
    my $self = shift;

    my $cs = $self->{clusters};
    for (keys %$cs) {
        $self->{clusters}{$_}->close;
    }
}

=head2 status_dump

For debug

=cut

sub status_dump {
    my $self = shift;

    my $cs = $self->{clusters};
    for (keys %$cs) {
        print "====[ CLUSTERS ]: $_====\n";
        $self->{clusters}{$_}->status_dump;
    }
}

sub is_controller {
    return TRUE;
}

sub DESTROY {
    my $self = shift;
    $self->close;
}

#----[ private ]------------------------------------------------------


#----[ private static ]-----------------------------------------------
sub _complement_conf {
    my $conf = shift;

    exists $conf->{clusters} or return;

    my @confs = (
        @Wiz::DB::Connection::CONFS,
        @Wiz::DB::ConnectionPool::CONFS,
        @Wiz::DB::ConnectionFactory::CONFS,
        @Wiz::DB::Cluster::CONFS,
    );

    my $cs = $conf->{clusters};
    if (ref $cs eq 'ARRAY') {
        my $new_cs = {};
        for (@$cs) {
            my $d = file_data_eval $_;
            for (keys %$d) {
                $new_cs->{$_} = $d->{$_};
            }
        }
        $conf->{clusters} = $new_cs;
        $cs = $new_cs;
    }

    for my $k (keys %$cs) {
        for (@confs) {
            if (ref $cs->{$k}) {
                defined $cs->{$k}{$_} or $cs->{$k}{$_} = $conf->{$_};
            }
            else {
                $cs->{$k} = file_data_eval $cs->{$k};
                for (@confs) {
                    defined $cs->{$k}{$_} or $cs->{$k}{$_} = $conf->{$_};
                }
            }
        }
    }
}

sub _get_group {
    my ($clusters) = @_;
    my %ret = ();
    for (sort keys %$clusters) {
        if ($_ =~ /([^\d]*)\d*/) {
            if (defined $ret{$1}) {
                push @{$ret{$1}}, $_;
            }
            else {
                $ret{$1} = [$_];
            }
        }
    }
    return \%ret;
}

sub _get_priority {
    my ($conf, $group) = @_;

    my %ret = ();
    for my $gk (keys %$group) {
        my @priority = ();
        for my $g (@{$group->{$gk}}) {
            my $c = $conf->{clusters}{$g};
            my $p = $c->{priority} || $quota{max_priority};
            push @priority, $p > $quota{max_priority} ?  $quota{max_priority} : $p;
        }
        $ret{$gk} = \@priority;
    }
    return \%ret;
}

sub _get_priority_sum {
    my ($priority) = @_;

    my %ret = ();
    for (keys %$priority) {
        $ret{$_} = array_sum($priority->{$_});
    }
    return \%ret;
}

=head1 SEE ALSO

L<Wiz::DB::Cluster>

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
