package Wiz::Log::Plugin::Syslog;
use base 'Wiz::Log::Plugin::Base';

use Wiz::Constant qw(:all);
use Sys::Syslog qw(:standard :macros);

my @level_to_syslog = qw/ 
        LOG_CRIT
        LOG_ERR
        LOG_WARNING
        LOG_NOTICE
        LOG_INFO
        LOG_DEBUG
/;

=head1 NAME

Wiz::Log::Plugin::Syslog - Wiz::Log plugins for syslog

=head1 VERSION

version 1.0

=cut

our $VERSION = '1.0';

=head1 SYNOPSIS

 use Wiz::Log::Plugin::Syslog;
 
 my $foo = Wiz::Log::Plugin::Syslog->new;
 ...

=head1 DESCRIPTION

This is a plugin for Wiz::Log which enables log output to syslog.

 ### output a message to syslog when message level is 'INFO' or above.
 syslog       => { 
     ident        => 'work1',
     facility     => 'local0',
     level        => INFO,
     open         => TRUE,
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
    
    $self->_isdef( 'ident' );
    $self->_isdef( 'facility' );
    $self->_default( 'level', ERROR );
    $self->_default( 'open',  TRUE );
    
    if ( $self->{open} == TRUE ) {
        $self->open();
    }   
}


sub _output {
    my ($self, $msg, $lv) = @_;
    
    syslog($level_to_syslog[$lv], $msg);
}


=head2 open()

Opens syslog file.

=cut

sub open {
    my $self = shift;

    openlog $self->{ident}, $self->{logopt}, $self->{facility}; 
}

=head2 close()

Closes syslog file.

=cut

sub close {
    my $self = shift;
    
    closelog;   
}

sub DESTROY {
        my $self = shift;

    $self->close;
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

1; # End of Wiz::Log::Plugin::Syslog

__END__

