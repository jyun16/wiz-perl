package Wiz::Aggregator;

use strict;
use warnings;

=head1 NAME

Wiz::Aggregator

=head1 VERSION

version 1.0

=cut

our $VERSION = '1.0';

=head1 SYNOPSIS

=head1 DESCRIPTION

=head2 

=cut

use Carp qw(confess);
use POSIX qw(:sys_wait_h);
use Proc::Fork;

use Wiz qw(ourv);
use Wiz::Noose;
use Wiz::Constant qw(:common);
use Wiz::Util::File qw(fix_path);
use Wiz::Util::Hash qw(args2hash);

has errmsg              => (is => 'rw', default => []);
has debug               => (is => 'rw', default => 0);
has force_cleanup       => (is => 'rw', default => 0);
has log                 => (is => 'rw');
has path                => (is => 'rw');
has renice              => (is => 'rw');
has renice_child        => (is => 'rw');
has parse_regex         => (is => 'rw');
has process             => (is => 'rw', default => 3);
has try_count           => (is => 'rw', default => 3);

requires 'job';
requires 'summarize';

sub BUILD {
    my $self = shift;
    my $args = args2hash @_;
    ref $args->{path} eq 'ARRAY' or $args->{path} = [ $args->{path} ];
    my @filepath;
    for (@{$args->{path}}) { 
        my $file = fix_path($_);
        -f $file or confess "not find file : ($file)";
        push @filepath, $file;
    }
    $self->path(\@filepath);
    $self->errmsg([]);

    $self->process > 0 or confess 'process value is not in the right.';
    for (($self->renice, $self->renice_child)) {
        defined $_ or next;
        unless (-20 <= $_ && $_ <= 19) { confess 'renice value range error.' }
    }
    if (defined $self->renice) {
        my $cmd = sprintf "renice %d -p %d", $self->renice, $$;
        `$cmd`;
        defined $self->renice_child or $self->renice_child($self->renice);
    }
}

sub _prepare_parse_data { }
sub _prepare_end_check { }
sub _prepare_job { shift; }
sub _before_job { }
sub _after_job { }
sub _before_summarize { }
sub _after_summarize { }
sub fail { }
sub succeed { }
sub cleanup { }

sub prepare { 
    my $self = shift;
    @{$self->path} == 0 and return FAIL;

    my $cnt = 0;
    my $log_handles = $self->bulk_open;
    for my $path (@{$self->path}) {
        open my $fh, '<', $path or confess $!;
        while (<$fh>) {
            my $parse_data = $self->_prepare_parse_data($_);
            $self->_prepare_end_check($parse_data) and last;
            $self->_prepare_job($parse_data) or next;
            my $fw = $log_handles->[$cnt];
            print $fw $_;
            ++$cnt >= $self->process and $cnt = 0;
        }
    }
    for (@$log_handles) { close $_; }
    SUCCESS;
}

sub bulk_open {
    my $self = shift;
    my @handles;
    for (1..$self->process) {
        open my $fh, '>', $self->tmp_dir. $self->_key($self->sep_prefix, $_) or confess $!;
        push @handles, $fh;
    }
    \@handles;
}

sub run {
    my $self = shift;
    $self->cleanup;
    if ($self->prepare) {
        if ($self->process > 1) { $self->_multi_run; }
        else { $self->_run(1); }
        @{$self->errmsg} > 0 or $self->finish;
        $self->force_cleanup and $self->cleanup;
    }
    else {
        $self->stack_error("run : failed execute 'prepare'");
        return FAIL;
    }
    $self->debug and warn $self->print_error;
    return SUCCESS;
}

sub _multi_run {
    my $self = shift;
    my ($process) = @_;

    defined $process or $process = [1..$self->process];
    my (%retry_process, @child_ids);
    for my $id (@$process) {
        run_fork {
            child {
                if (defined $self->renice_child) {
                    my $cmd = sprintf "renice %d -p %d", $self->renice_child, $$;
                    `$cmd`;
                }
                exit $self->_run($id);
            }
            parent {
                my $pid = shift;
                $retry_process{$pid} = $id;
                push @child_ids, $pid;
            }
        };
    }
    for (@child_ids) {
        local $?;
        waitpid $_, WUNTRACED;
        WEXITSTATUS($?) == 0 and delete $retry_process{$_};
    }
    if (keys %retry_process > 0) { 
        if ($self->try_count($self->try_count - 1) <= 0) {
            my $msg = join ', ', values %retry_process;
            $self->stack_error("_multi_run : over than try_count!! error id :". $msg);
            return;
        }
        $self->_multi_run([values %retry_process]);
    }
    
    $self->succeed('multi_run');
}

sub _run {
    my $self = shift;
    my ($id) = @_;

    my $args = $self->_before_job($id);
    eval { $self->job(@$args, $id); };
    $self->_after_job($args);

    if ($@) {
        $self->stack_error('_run : '. $@);
        if ($self->try_count($self->try_count - 1) > 0) {
            $self->log 
                and $self->log->fatal("_run : ovar than try_count! id => $id, process_id => $$");
        }
        else {
            $self->log 
                and $self->log->warn("_run : failed run! id => $id, process_id => $$");
            $self->fail('job');
        }
        return 1;
    }
    else {
        $self->succeed('job');
    }
    return 0;
}

sub finish { 
    my $self = shift;

    my $result;
    my $args = $self->_before_summarize;
    eval { $result = $self->summarize($args); };
    $self->_after_summarize($args, $result);

    if ($@) {
        $self->stack_error('finish : try_count('. $self->try_count. ') : '. $@);

        if ($self->try_count($self->try_count - 1) > 0) {
            $self->stack_error("finish : ovar than try_count!");
            return $self->finish;
        }
        else {
            $self->fail('finish');
        }
        return FAIL;
    }
    else {
        $self->succeed('finish');
    }
    return SUCCESS;
}

sub stack_error {
    my $self = shift;
    my ($msg) = @_;
    push @{$self->errmsg}, $msg;
}

sub error2str {
    my $self = shift;
    my ($delimiter) = @_;
    $delimiter |= "\n";
    @{$self->errmsg} > 0 or return;
    join $delimiter, @{$self->errmsg};
}

sub print_error {
    my $self = shift;
    print "-------------[ AGGREGATOR ERROR ]-------------\n";
    print $self->error2str;
    print "\n----------------------------------------------\n";
}

sub _key {
    my $self = shift;
    my ($prefix, $index) = @_;
    $prefix. '.'. $index;
}

=head1 AUTHOR

Toshihiro MORIMOTO C<< dealforest.net@gmail.com >>

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
