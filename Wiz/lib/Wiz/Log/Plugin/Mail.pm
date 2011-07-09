package Wiz::Log::Plugin::Mail;
use strict;
use base 'Wiz::Log::Plugin::Base';

use Carp;

use Wiz::Mail;

=head1 NAME

Wiz::Log::Plugin::Mail - Wiz::Log plugins for mail

=head1 VERSION

version 1.0

=cut

our $VERSION = '1.0';

=head1 SYNOPSIS

 use Wiz::Log::Plugin::Mail;
 
 my $foo = Wiz::Log::Plugin::Mail->new;
 ...

=head1 DESCRIPTION

This is a plugin for Wiz::Log which enables log output to a specified mail address.

 ### send a mail using a configuration in 'logmail.conf'
 ### to admin@adways.net when a message level is 'FATAL'
 mail         => {
     _conf        => 'logmail.conf',
     config       => { To => 'admin@adways.net' },
     level        => FATAL, 
 },


=head1 EXPORTS

=cut

use base qw(Exporter);

our @EXPORT_SUB = qw();
our @EXPORT_CONST = qw();
our @EXPORT_OK = (@EXPORT_SUB, @EXPORT_CONST);

our %EXPORT_TAGS = (
    'sub'       => \@EXPORT_SUB,
    'const'     => \@EXPORT_CONST,
    'all'       => \@EXPORT_OK,
);


=head1 METHODS


=cut

sub _initialize {
    my $self = shift;
    
    my $mailconf = {};
    if ( defined($self->{_conf}) ) { 
        open my $FH, '<', $self->{_conf} 
            or confess "Can't open config file $self->{_conf}: $!";
        $mailconf = do { local $/; <$FH> };
        close $FH;
    }
    
    for my $key (keys %{$self->{config}}) {
        $mailconf->{$key} = $self->{config}->{$key};   
    }
    
    $self->{mail} = Wiz::Mail->new( %$mailconf );
}


sub _output {
    my ($self, $msg) = @_;
    
    my $mail = $self->{mail};
    $mail->data($msg);
    $mail->send();
}

=head1 SEE ALSO

L<Wiz::Log>

=head1 AUTHOR

Egawa Takashi, C<< <egawa.takashi@adways.net> >>

[Base idea & modify] Junichiro NAKAMURA, C<< <jyun16@gmail.com> >>

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

1; # End of Wiz::Log::Plugin::Mail

__END__
