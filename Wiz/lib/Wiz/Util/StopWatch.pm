package Wiz::Util::StopWatch;

use strict;
use warnings;

use Time::HiRes;

=head1 NAME

Wiz::Util::StopWatch

=head1 VERSION

version 1.0

=cut

our $VERSION = '1.0';

=head1 SYNOPSIS

 use Data::Dumper;
 use Wiz::Util::StopWatch;
 
 my $sw = new Wiz::Util::StopWatch;
 
 $sw->start;
 select undef, undef, undef, 0.2;
 $sw->stop_print;
 
 sleep 1;
 
 $sw->start;
 select undef, undef, undef, 0.2;
 $sw->stop_print;
 
 $sw->start;
 select undef, undef, undef, 0.2;
 $sw->stop_print;
 
 $sw->start;
 
 select undef, undef, undef, 0.2;
 $sw->lap;
 print $sw;
 
 $sw->stop;
 
 print Dumper $sw->lap_history;

Result of the abobe:

 [1] 0.200578927993774 (lap: 0.200578927993774)
 [2] 0.400559902191162 (lap: 0.199980974197388)
 [3] 0.600438833236694 (lap: 0.199878931045532)
 [4] 0.800288677215576 (lap: 0.199849843978882)
 $VAR1 = [
           '0.200578927993774',
           '0.199980974197388',
           '0.199878931045532',
           '0.199849843978882',
           '0.200010776519775'
         ];

=head1 DESCRIPTION

=cut

=head1 CONSTRUCTOR

=cut 

sub new {
    my $self = shift;
    my %args = @_;

    my $now = Time::HiRes::time;
    my $instance = bless {
        started             => 0,
        now                 => $now,
        old                 => $now,
        lap                 => 0,
        total_time          => 0,
        cnt                 => 0,
        label               => '',
        lap_history         => [],
    }, $self;
    return $instance;
}

=head1 METHODS

=cut

sub start {
    my $self = shift;

    my $now = Time::HiRes::time;
    if (!$self->{started}) {
        $self->{now} = $now;
        $self->{old} = $now;
        $self->{started} = 1;
    }
}

sub lap {
    my $self = shift;
    my $label = shift;

    my $now = Time::HiRes::time;
    if ($self->{started}) {
        $self->{lap} = $now - $self->{old};
        $self->{total_time} += $self->{lap};
        $self->{old} = $self->{now};
        $self->{now} = $now;
        $self->{label} = defined $label ? $label . ' ' : '';
        ($self->{cnt})++;
        push @{$self->{lap_history}}, $self->{lap};
    }
}

sub stop {
    my $self = shift;
    my $label = shift;

    my $now = Time::HiRes::time;
    if ($self->{started}) {
        $self->{lap} = $now - $self->{old};
        $self->{total_time} += $self->{lap};
        $self->{old} = $self->{now};
        $self->{now} = $now;
        $self->{started} = 0;
        ($self->{cnt})++;
        push @{$self->{lap_history}}, $self->{lap};
    }
}

sub reset {
    my $self = shift;

    my $now = Time::HiRes::time;
    $self->{started} = 0;
    $self->{now} = $now;
    $self->{old} = $now;
    $self->{total_time} = 0;
    $self->{cnt} = 0;
    $self->{label} = '';
    $self->{lap_history} = []; 
}

sub get {
    my $self = shift;

    my $ret = "[$self->{cnt}] $self->{label}" . $self->{total_time};
    $ret .= " (lap: " . $self->{lap} . ")\n";
}

sub lap_history {
    shift->{lap_history};
}

sub print {
    print shift->get;
}

sub stop_print {
    my $self = shift;
    $self->stop(shift);
    $self->print;
}

use overload '""' => sub {
    return shift->get;
};

=head1 AUTHOR

Junichiro NAKAMURA, C<< <jyun16@gmail.com> >>
modified by ktat C<< <ktat@gmail.com> >>

=head1 COPYRIGHT & LICENSE

Copyright 2008,2009 The Wiz Project. All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice,
self list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright
notice, self list of conditions and the following disclaimer in the
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
We welcome anyone who cooperates with us in developing self software.

We'll invite you to self project's member.

=cut

1;

__END__
