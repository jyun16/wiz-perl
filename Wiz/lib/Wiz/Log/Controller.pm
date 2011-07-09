package Wiz::Log::Controller;

use strict;
use warnings;

=head1 NAME

Wiz::Log::Controller

=head1 VERSION

version 1.0

=cut

=head1 SYNOPSIS

 my $logs_dir = '/var/log/wiz_log_test/'
 
 my $lc = new Wiz::Log::Controller({
     level   => DEBUG,
     logs    => {
         log1    => { # Adawys::Log configuration
             path    => "$logs_dir/log1.log",
         },
         log2    => { # Adawys::Log configuration
             path    => "$logs_dir/log2.log",
         },
     }
 });

 my $log1 = $lc->log('log1');
 $log1->error('foobar');

$log1 is Wiz::Log object.
And, The error string "foobar" output to /var/log/wiz_log_test/log1.log

 my $log2 = $lc->log('log2');
 $log2->error('foobar');

The error string "foobar" output to /var/log/wiz_log_test/log2.log

The config under the logs is same Wiz::Log's config.

=head1 DESCRIPTION

This can hanlde Wiz::Log objects.
You can use multiple log configuration properly.

=cut

use Carp qw(confess);

use Wiz qw(get_hash_args);
use Wiz::Constant qw(:common);
use Wiz::Log;

=head1 METHODS

=head2 $obj = new(\%conf)

Configuration is as nearly same as L<Wiz::Log> except key C<'logs'>.
C<'logs'> is hash ref, their values are L<Wiz::Log> cofiguration.

=cut

sub new {
    my $self = shift;
    my $args = get_hash_args(@_);

    my $logs = $args->{logs};
    if (defined $logs) {
        for my $c (@Wiz::Log::CONFS) {
            for my $l (keys %{$logs}) {
                if (defined $args->{$c}) {
                    defined $logs->{$l}{$c} or 
                        $logs->{$l}{$c} = $args->{$c};
                }
            }
        }
    }
    else {
        my %args = %$args;
        $args = {};
        $args->{logs}{default} = \%args;
    }

    return bless { conf => $args, logs => {} }, $self;
}

sub log {
    my $self = shift;
    my ($label) = @_;

    defined $label or $label = 'default';
    exists $self->{conf}{logs}{$label} or $label = 'default';

    if (defined $self->{logs}{$label}) {
        return $self->{logs}{$label};
    }

    my $log = new Wiz::Log($self->{conf}{logs}{$label});
    $self->{logs}{$label} = $log;

    return $log;
}

=head1 SEE ALSO

L<Wiz::Log>

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
