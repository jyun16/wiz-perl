package Wiz::Util::System;

use strict;
use warnings;

=head1 NAME

Wiz::Util::System

=head1 VERSION

version 1.0

=cut

our $VERSION = '1.0';

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut

use Carp;
use Proc::ProcessTable;
use Sys::Hostname;
use IO::Interface::Simple;

use Wiz::IO::Capture qw(:capture_target);
use Wiz::Constant qw(:common);
use Wiz::Util::Hash qw(args2hash);

=head1 EXPORTS

 $WARNING - output warning message.

 get_pid
 get_uid
 get_euid
 get_gid
 get_egid
 check_multiple_execute
 hostname
 ip_address

=cut

use Wiz::ConstantExporter [qw(
    get_pid
    get_uid
    get_euid
    get_gid
    get_egid
    check_multiple_execute
    trylock
    unlock
    hostname
    ip_address
)]; 

our $WARNING = TRUE;

use Wiz::ConstantExporter {
    LOCK_SUCCEEDED      => 0,
    LOCK_FAILED         => 1,
    LOCK_TIMEOUT        => 2,
    LOCK_FATALS_ERROR   => 3,
    UNLOCK_SUCCEEDED    => 0,
    UNLOCK_FAILED       => 1,
}, 'lock';

my %DEFAULT = (
    lock    => {
        waittime    => 1,
        blocking    => 1,
        retry       => 10,
        expire      => 60,
        lockdir     => '_lock_',
        tmp_lockdir => '_lock_tmp',
    },
);

=head1 FUNCTIONS

=cut

=head2 $pid = get_pid

get current process id

=cut

sub get_pid {
    return $$;
}

=head2 $uid = get_uid

get real user id of current process

=cut

sub get_uid {
    return $<;
}

=head2 $euid = get_euid

get effective user id of current process

=cut

sub get_euid {
    return $>;
}

=head2 $gid = get_gid

get real group id of current process

=cut

sub get_gid {
    return $(;
}

=head2 $egid = get_egid

get effective group id of current process

=cut

sub get_egid {
    return $);
}

=head2 $scrpit_name = get_script_name 

=cut

sub get_script_name {
    return $0;
}

=head2 $bool = check_multiple_execute($lock_file)

=cut

sub check_multiple_execute {
    my $lock_file = shift;
    defined $lock_file or confess "plz give me lock file path";
    $^O eq 'cygwin' and return FALSE;
    my $locked_pid = undef;
    if (-f $lock_file) {
        open LOCK, '<', $lock_file or confess "can't open $lock_file ($!)";
        $locked_pid = <LOCK>;
        close LOCK;
        my $pt = new Proc::ProcessTable;
        my $cap = new Wiz::IO::Capture(target => CAPTURE_TARGET_WARN);
        $cap->start;
        for my $p (@{$pt->table}) {
            my $pid = $p->pid;
            if ($pid == $locked_pid) {
                return FALSE;
            }
        } 
        $cap->stop;
        if ($cap->warn !~ /^Ran into unknown state/) {
            $cap->warn and warn $cap->warn;
        }
    }
    open LOCK, '>', $lock_file or confess "can't open $lock_file ($!)";
    print LOCK $$;
    close LOCK;
    return TRUE;
}

=head2 get_package_version 1.0

Returns aversion 1.0of a perl module.

=cut

sub get_package_version{
    my ($package) = @_;
    local ($@, $!);
    eval "require $package";
    if ($@) { return undef; }
    else { $package->VERSION; }
}

=head2 trylock

Provides simple lock mechanism with mkdir.

    if (!trylock) {

        ... do any atomic operation

        unlock;
    }

    trylock can take the following value that is hash or hash reference.
    # This sample have default values.
    trylock(
        waittime    => 1,
        blocking    => 1,
        retry       => 10,
        expire      => 60,
        lockdir     => '_lock_',
        tmp_lockdir => '_lock_tmp',
    )

    "waittime" is sleep time(second) to take a lock.
    "retry" is number of retry to take a lock.
    "expire" is expire of lock.
    "lockdir" is name of directory for lock.
    "tmp_lockdir" is name of directory to cleanup dead lock.

    If "blocking" has false value, return immediately when lock failed.

=cut

sub trylock {
    my ($conf) = args2hash @_;

    if (defined $conf->{lockdir} and not defined $conf->{tmp_lockdir}) {
        $conf->{tmp_lockdir} = $conf->{lockdir} . '_tmp';
    }
    for (keys %{$DEFAULT{lock}}) { defined $conf->{$_} or $conf->{$_} = $DEFAULT{lock}{$_}; }
    while (!mkdir($conf->{lockdir}, 0755)) {
        $conf->{blocking} or return LOCK_FAILED;
        if (--$conf->{retry} > 0) {
            if (mkdir($conf->{tmp_lockdir}, 0755)) {
                if ((time - (stat $conf->{lockdir})[10]) > $conf->{expire}) {
                    rename $conf->{tmp_lockdir}, $conf->{lockdir} or return LOCK_FATALS_ERROR;
                }
                else { rmdir $conf->{tmp_lockdir}; }
            }
        }
        else {
            return LOCK_TIMEOUT;
        }
        sleep $conf->{waittime};
    }
    return LOCK_SUCCEEDED;
}

sub unlock {
    my ($conf) = args2hash @_;

    if (defined $conf->{lockdir} and not defined $conf->{tmp_lockdir}) {
        $conf->{tmp_lockdir} = $conf->{tmp_lockdir} .= '_tmp';
    }
    for (keys %{$DEFAULT{lock}}) { defined $conf->{$_} or $conf->{$_} = $DEFAULT{lock}{$_}; }
    for (qw(lockdir tmp_lockdir)) {
        if (-d $conf->{$_}) { rmdir $conf->{$_} or return UNLOCK_FAILED; }
    }
    return UNLOCK_SUCCEEDED;
}

no warnings 'redefine';

sub hostname {
    return Sys::Hostname::hostname;
}

sub ip_address {
    new IO::Interface::Simple(shift || 'eth0')->address;
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
