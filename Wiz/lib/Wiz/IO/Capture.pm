package Wiz::IO::Capture;

=head1 NAME

Wiz::IO::Capture

=head1 VERSION

version 1.0

=cut

our $VERSION = '1.0';

=head1 SYNOPSIS

=head2 CAPTURE STDOUT

use Wiz::IO::Capture qw(:capture_target);
 
 my $cap = new Wiz::IO::Capture(target => CAPTURE_TARGET_STDOUT);
 print "[STDOUT] 1\n";
 $cap->start;
 print "[STDOUT] 2 - captured\n";
 $cap->stop;
 print "[STDOUT] 3\n";
 
 # [STDOUT] 2 - captured\n
 is $cap->stdout;

=head2 CAPTURE STDERR
 
 my $cap = new Wiz::IO::Capture(target => CAPTURE_TARGET_STDERR);
 print STDERR "[STDERR] 1\n";
 $cap->start;
 print STDERR "[STDERR] 2 - captured\n";
 $cap->stop;
 print STDERR "[STDERR] 3\n";
 
 # [STDERR] 2 - captured\n
 $cap->stderr;

=head2 CAPTURE WARN

 my $cap = new Wiz::IO::Capture(target => CAPTURE_TARGET_WARN);
 warn "[WARN] 1";
 $cap->start;
 warn "[WARN] 2 - captured";
 $cap->stop;
 warn "[WARN] 3";
 
 # [WARN] 2 - captured
 $cap->warn;

=head2 CAPTURE ALL

 my $cap = new Wiz::IO::Capture(target => CAPTURE_TARGET_STDOUT | CAPTURE_TARGET_STDERR | CAPTURE_TARGET_WARN);

=head1 DESCRIPTION

=cut

=head1 EXPORTS

=cut

use Wiz::Noose;

use Wiz::ConstantExporter {
    CAPTURE_TARGET_STDOUT => 1,
    CAPTURE_TARGET_STDERR => 2,
    CAPTURE_TARGET_WARN   => 4,
}, 'capture_target';

has target => (is => 'rw');

sub start {
    my $self = shift;
    my $target = $self->target;
    $target & CAPTURE_TARGET_STDOUT and $self->_start_stdout;
    $target & CAPTURE_TARGET_STDERR and $self->_start_stderr;
    $target & CAPTURE_TARGET_WARN and $self->_start_warn;
}

sub _start_stdout {
    my $self = shift;
    open my $saved_stdout, '>&STDOUT';
    my $message = '';
    close STDOUT;
    open STDOUT, '>', \$message;
    $self->{saved_stdout} = $saved_stdout;
    $self->{stdout} = \$message;
}

sub _start_stderr {
    my $self = shift;
    open my $saved_stderr, '>&STDERR';
    my $message = '';
    close STDERR;
    open STDERR, '>', \$message;
    $self->{saved_stderr} = $saved_stderr;
    $self->{stderr} = \$message;
}

sub _start_warn {
    my $self = shift;
    $self->{saved_warn} = $SIG{__WARN__};
    my $message = '';
    $SIG{__WARN__} = sub {
        my ($args) = @_;
        chomp $args;
        $message = $args;
    };
    $self->{warn} = \$message;
}

sub stop {
    my $self = shift;
    my $target = $self->target;
    $target & CAPTURE_TARGET_STDOUT and $self->_stop_stdout;
    $target & CAPTURE_TARGET_STDERR and $self->_stop_stderr;
    $target & CAPTURE_TARGET_WARN and $self->_stop_warn;
}

sub _stop_stdout {
    my $self = shift;
    open STDOUT, '>&', $self->{saved_stdout};
}

sub _stop_stderr {
    my $self = shift;
    open STDERR, '>&', $self->{saved_stderr};
}

sub _stop_warn {
    my $self = shift;
    $SIG{__WARN__} = $self->{saved_warn};
}

sub stdout {
    my $self = shift;
    return ${$self->{stdout}};
}

sub stderr {
    my $self = shift;
    return ${$self->{stderr}};
}

sub warn {
    my $self = shift;
    return ${$self->{warn}};
}

=head1 AUTHOR

Junichiro NAKAMURA, C<< <jyun16@gmail.com> >>

=head1 COPYRIGHT & LICENSE

Copyright 2010 The Wiz Project. All rights reserved.

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
