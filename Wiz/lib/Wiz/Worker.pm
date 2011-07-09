package Wiz::Worker;

=head1 NAME

Wiz::Worker

=head1 VERSION

version 1.0

=cut

our $VERSION = '1.0';

=head1 SYNOPSIS

=head2 CREATE TABLE

 CREATE TABLE job (
     id                      BIGINT UNSIGNED    AUTO_INCREMENT PRIMARY KEY,
     args                    TEXT,
     status                  TINYINT UNSIGNED    DEFAULT 0,
     try_count               INTEGER UNSIGNED    DEFAULT 0,
     result                  TEXT,
     error_message           VARCHAR(2048),
     created_time            DATETIME            NOT NULL,
     last_modified           TIMESTAMP
 ) ENGINE=innodb DEFAULT CHARACTER SET utf8 COLLATE utf8_bin;

=head2 SAMPLE WORKER PACKAGE

Create worker implemented Wiz::Worker.

 package SampleWorker;
 
 use Wiz::Noose;
 
 with 'Wiz::Worker';
 
 sub job {
     my $self = shift;
     my ($args, $data) = @_;
     if ($args->{fuga}) {
         die 'DIE DIE DIE';
     }
     return 'SUCCESS!!!';
 }

 sub succeed {
     my $self = shift;
     my ($args, $data) = @_;
 }

 sub fail {
     my $self = shift;
     my ($args, $data) = @_;
 }

=head2 SAMPLE CLIENT

 my $worker = new SampleWorker(
     type    => 'mysql',
     host    => 'localhost',
     db      => 'worker',
     user    => 'root',
     passwd  => '',
 );
 $worker->register(hoge => 'HOGE');
 $worker->commit;

You can give a Wiz::DB::Connection object to the worker's constructor.

 my $worker = new SampleWorker(
     dbc => new Wiz::DB::Connection($conf->{db}),
 );

Register arguments for the worker job.

 $worker->register(hoge => 'HOGE');

Commit the job.

 $worker->commit;

If you want to do not auto commit, then give a auto_commit flag to the Wiz::DB::Connection parameter,
or do this:

 my $worker = new SampleWorker(
     dbc => new Wiz::DB::Connection($conf->{db}),
     auto_commit => TRUE,
 );

Table name default is "job". You can change it name:

 my $worker = new SampleWorker(
     dbc => new Wiz::DB::Connection($conf->{db}),
     table => 'NEW_TABLE_NAME',
 );

=head2 SAMPLE WORKER

 my $worker = new SampleWorker(
     dbc => new Wiz::DB::Connection($conf->{db}),
 );
 $worker->run;
 $worker->commit;

 $worker->run;

It is possible to use multiprocessing. 

 $self->multi_run(5);

or

 my $worker = new SampleWorker(
     dbc => new Wiz::DB::Connection($conf->{db}),
     process => 5,
 );
 $self->run;

or

 $self->process(5);
 $self->run;

Default behavior of the worker is to delete finished jobs data.

 $worker->delete_on_success(FALSE);

Data is not deleted when making it like the above-mentioned. 

To loop it, it only has to do as follows. 

 $worker->create_connection(sub {
     return new Wiz::DB::Connection($conf->{db});
 });
 $worker->work;

or

 my $worker = new SampleWorker(
     dbc => new Wiz::DB::Connection(auto_commit => TRUE, some configuration...),
 );
 $worker->work;

Default of try is 3 times, you can change this.

 $worker->try_count(5);

=head1 DESCRIPTION

=cut

=head1 EXPORTS

=cut

use Storable qw(thaw nfreeze);
use MIME::Base64;
use Proc::Fork;

use Wiz qw(ourv);
use Wiz::Noose;
use Wiz::Constant qw(:common);
use Wiz::Util::Array qw(array_divide);
use Wiz::Util::Hash qw(args2hash);
use Wiz::Util::System qw(hostname);
use Wiz::DB::Connection;
use Wiz::DB::DataIO;
use Wiz::DateTime;

use Wiz::ConstantExporter {
    JOB_STATUS_READY    => 0,
    JOB_STATUS_FINISHED => 1,
    JOB_STATUS_RETRY    => 2,
    JOB_STATUS_ERROR    => 3,
    JOB_STATUS_LOCKED   => 4,
}, 'job_status';

has dao                 => (is => 'rw');
has table               => (is => 'rw', default => 'job');
has auto_commit         => (is => 'rw', default => TRUE);
has process             => (is => 'rw', default => 1);
has try_count           => (is => 'rw', default => 3);
has timer               => (is => 'rw', default => 5);
has delete_on_success   => (is => 'rw', default => TRUE);
has create_connection   => (is => 'rw');
has per_host            => (is => 'rw', default => FALSE);

requires 'job';

sub BUILD {
    my $self = shift;
    my ($args) = @_;
    if (my $table_name = $self->ourv('TABLE')) { $self->table($table_name); }
    if ($args->{dbc}) { $self->dbc($args->{dbc}); }
    else { $self->dbc(new Wiz::DB::Connection($args)); }
}

sub dbc {
    my $self = shift;
    my ($dbc) = @_;
    if ($dbc) {
        $self->{dbc} = $dbc;
        $self->dao(new Wiz::DB::DataIO($dbc, $self->table));
    }
    return $self->{dbc};
}

sub register {
    my $self = shift;
    my ($args) = args2hash @_;
    my $now = new Wiz::DateTime;
    my %data = (
        args            => (encode_base64 nfreeze $args),
        try_count       => $self->try_count || 1,
        created_time    => $now->to_string,
    );
    if ($self->per_host) {
        $data{host} = hostname;
    }
    for (keys %{$self->{appended_data}}) {
        $data{$_} = $self->{appended_data}{$_};
    }
    $self->dao->set(%data);
    my $ret = $self->dao->insert;
    $self->auto_commit and $self->dbc->commit;
    return $ret;
}

sub _search_param {
    my $self = shift;
    my $ret = {
        -in => {
            status => [ JOB_STATUS_READY, JOB_STATUS_RETRY ],
        },
        try_count   => [ '>', 0 ],
    };
    if ($self->per_host) {
        $ret->{host} = hostname;
    }
    return $ret;
}

sub run {
    my $self = shift;
    if ($self->process > 1) {
        $self->multi_run($self->process);
    }
    else {
        $self->dao->clear;
        my $rs = $self->dao->select($self->_search_param);
        while ($rs->next) {
            $self->_run($rs->data);
        }
    }
}

sub multi_run {
    my $self = shift;
    my ($process) = @_;
    my @data = $self->dao->select($self->_search_param);
    my @ids = ();
    my $divided_data = array_divide(\@data, 2);
    my @child_ids = ();
    for my $list (@$divided_data) {
        run_fork {
            child {
                $self->dbc($self->create_connection->());
                for (@$list) {
                    $self->_run($_);
                }
                exit;
            }
            parent {
                push @child_ids, shift;
            }
        };
    }
    for (@child_ids) { waitpid $_, 0; }
}

sub _run {
    my $self = shift;
    my ($data) = @_;
    my $result = '';
    eval {
        $result = $self->job(thaw(decode_base64 $data->{args}), $data);
    };
    my $dao = $self->dao;
    $dao->clear;
    if ($@) {
        --$data->{try_count};
        my $status = JOB_STATUS_RETRY;
        $dao->set(
            error_message   => $@,
            try_count       => $data->{try_count},
            status          => $data->{try_count} > 0 ? JOB_STATUS_RETRY : JOB_STATUS_ERROR,
        );
        $dao->update(id => $data->{id});
        $self->fail(thaw(decode_base64 $data->{args}), $data);
    }
    else {
        if ($self->delete_on_success) {
            $dao->delete(id => $data->{id});
        }
        else {
            $dao->set(
                result          => $result,
                status          => JOB_STATUS_FINISHED,
            );
            $dao->update(id => $data->{id});
        }
        $self->succeed(thaw(decode_base64 $data->{args}), $data);
    }
    $self->auto_commit and $self->dbc->commit;
}

sub work {
    my $self = shift;
    while (1) {
        $self->run;
        select undef, undef, undef, $self->timer;
        $self->dbc->rollback;
    }
}

sub succeed {
    my $self = shift;
    my ($args, $data) = @_;
}

sub fail {
    my $self = shift;
    my ($args, $data) = @_;
}

sub commit {
    my $self = shift;
    $self->dbc->commit;
}

sub app_data {
    my $self = shift;
    if (@_ > 1) {
        my %args = @_;
        for (keys %args) {
            $self->{app_data}{$_} = $args{$_};
        }
    }
    else {
        return $self->{app_data}{$_[0]};
    }
}

sub clear_app_data {
    my $self = shift;
    $self->{app_data} = {};
}

sub appended_data {
    my $self = shift;
    if (@_ > 1) {
        my %args = @_;
        for (keys %args) {
            $self->{appended_data}{$_} = $args{$_};
        }
    }
    else {
        return $self->{appended_data}{$_[0]};
    }
}

sub clear_appended_data {
    my $self = shift;
    $self->{appended_data} = {};
}

=head1 AUTHOR

Junichiro NAKAMURA, C<< <jyun16@gmail.com> >>

Toshihiro MORIMOTO C<< dealforest.net@gmail.com >>

=head1 COPYRIGHT & LICENSE

Copyright 2009,2010 The Wiz Project. All rights reserved.

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
