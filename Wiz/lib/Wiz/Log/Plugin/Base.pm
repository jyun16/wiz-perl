package Wiz::Log::Plugin::Base;

use strict;
use warnings;

use Carp;
use Wiz::Constant qw(:all);
use Wiz::Log qw(:all);

=head1 NAME

Wiz::Log::Plugin::Base - Base class for Wiz::Log plugins

=head1 VERSION

version 1.0

=cut

our $VERSION = '1.0';

=head1 SYNOPSIS

 use Wiz::Log::Plugin::Base;
 
 my $foo = Wiz::Log::Plugin::Base->new;
 ...

=head1 DESCRIPTION

This is a base class for Wiz::Log plugins.
This class should not be used directly. Use appropriate subclass instead.

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

=head2 new

Caution: This method should never be called directly!

=cut

sub new {
    my $invocant = shift;
    my $class    = ref $invocant || $invocant;
    my $options  = shift;
    
    if ($class eq __PACKAGE__) {
        confess "Never use 'base' as a log type!!";
    }

    if (!defined( $options->{_output_flag} )) {
        $options->{_output_flag} = TRUE;
    }
    my $self = bless $options, $class;
    $self->_initialize;
    return $self;
}

=head2 $get_level = level($set_level)

Accessor for log level.

=cut

sub level {
    my $self = shift;
    my $level = shift;
    
    defined $level and $self->{level} = $level;
    return $self->{level};    
}

=head2 output_on()

Set the switch of log output on.

=cut

sub output_on {
    my $self = shift;
    $self->{_output_flag} = TRUE;   
}

=head2 output_off()

Set the switch of log output off.

=cut

sub output_off {
    my $self = shift;
    $self->{_output_flag} = FALSE;
}

=head2 autoflush($switch)

=head2 flush($switch)

=head2 sync($switch)

=cut

sub autoflush {}
sub flush {}
sub sync {}

=head2 close()

Closes log file handle.

=cut

sub close {}

sub _isdef {
    my ($self, $key) = @_;
    
    if ( !defined($self->{$key}) ) {
        confess "$key must be specified.\n";   
    }
}

sub _default {
    my ($self, $key, $default_value) = @_;
    
    $self->{$key} = $default_value
        if ( !defined( $self->{$key} ) );
}

sub _initialize {
    #  Override this function if you need to set default values in option.
    my $self = shift;
    
    $self->_default( 'level', ERROR );
}

=head2 output($msg, $stack_dump, $lv)

Outputs the log message, only when $lv is equal or higher than the predefined log level.

=cut

sub output {
    my ($self, $msg, $stack_dump, $lv) = @_;

    return if ($self->{_output_flag} == FALSE);
    return if ($self->{level} < $lv);
    defined $stack_dump and $msg .= $stack_dump;
    $self->_output($msg, $lv);
}

sub _output {
    my ($self, $msg, $lv) = @_;
    
    die;
    #  Override this inner method to generate an actual output.    
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

1; # End of Wiz::Log::Plugin::Base

__END__


