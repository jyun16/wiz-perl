package Wiz::Log::Plugin::File;

use base 'Wiz::Log::Plugin::Base';

use Carp;
use IO::Handle;
use Data::Dumper;
use Wiz::Constant qw(:all);

=head1 NAME

Wiz::Log::Plugin::File - Wiz::Log plugins for file

=head1 VERSION

version 1.0

=cut

our $VERSION = '1.0';

=head1 SYNOPSIS

 use Wiz::Log::Plugin::File;
 
 my $foo = Wiz::Log::Plugin::File->new;
 ...

=head1 DESCRIPTION

This is a plugin for Wiz::Log which enables log output to a specified file.

 ### output a message to file 'log.dat' when message level is 'WARN' or above.
 file         => {
     path         => 'log.dat', 
     level        => WARN,
     open         => TRUE,
     autoflush    => TRUE,
 }

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
    
    $self->_isdef('path');
    $self->_default('level' =>  ERROR);
    $self->_default('open' => TRUE);
    $self->_default('autoflush' => TRUE);
    if ($self->{open} == TRUE) {
        $self->open;   
    }
}

sub _output {
    my ($self, $msg) = @_;
   
    $self->{file_handle}->print($msg);
}

=head2 open()

In case 'file' is specified as destination, opens file.
Basically, openfile() is not necessary unless 'open => FALSE' is specified explicitly 
in 'file' configuration. 

=cut

sub open {
    my $self = shift;

    $self->close;
    my $path = $self->{path};

    if ($path) {
        my $file_handle = new IO::Handle();
        CORE::open(FILE, '>>', $path) or
            confess "can't open self file -> $path ($!)\n";

        $file_handle->fdopen(fileno(FILE), 'a');
        $self->{file_handle} = $file_handle;
        $self->autoflush($self->{autoflush});
    }
}

=head2 close()

In case 'file' is specified as destination, close file.
closefile is not necessary unless you want to close file explicitly, because the file 
will be closed automatically in DESTROY.

=cut

sub close {
    my $self = shift;

    if (defined $self->{file_handle}) {
        $self->{file_handle}->close;  
        delete $self->{file_handle};  
    }
}

=head2 autoflush($flag)

Enable/disable autoflushing.
Enabled if $flag is TRUE(1), and disabled if $flag is FALSE(0).

=cut

sub autoflush {
    my $self = shift;
    my $flag = shift;

    if (defined $self->{file_handle}) {
        $self->{file_handle}->autoflush($flag); 
        $self->{autoflush} = $flag;
    }
}

=head2 flush
=head2 sync

Flushes buffer.

=cut

sub flush {
    my $self = shift;
    $self->{autoflush} and return;
    defined $self->{file_handle} and $self->{file_handle}->flush;   
}

sub sync {
    my $self = shift;
    $self->{autoflush} and return;
    defined $self->{file_handle} and $self->{file_handle}->sync;    
}

sub DESTROY {
    my $self = shift;
    $self->flush;
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

1; # End of Wiz::Log::Plugin::File

__END__
