package Wiz::SWF::Memory;

use strict;
use warnings;

use Wiz::SWF::Constant qw(:default_swf_header);

use base 'SWF::File';

our $VERSION = '0.001';

sub new {
    my ($class, $swf_data, $file, %header) = @_;
    my $stream = SWF::BinStream::Memory::Write->new($file, $header{Version}, $swf_data);
    my $self = $stream->sub_stream;
    bless $self, ref $class || $class;

    $self->{_header_CompressFlag} = 0;
    $self->FrameRate($header{FrameRate} || DEFAULT_FRAME_RATE);
    $self->FrameSize($header{FrameSize} || [0, 0, DEFAULT_FRAME_SIZE_X, DEFAULT_FRAME_SIZE_Y]);
    $self;
}

1;

package SWF::BinStream::Memory::Write;

use strict;
use warnings;

use IO::Scalar;

use base 'SWF::BinStream::File::Write';

sub new {
    my ($class, $file, $version, $swf_data) = @_;
    my $self = $class->SUPER::new($version);
    $self->SUPER::autoflush(1024, \&_writefile);
    $self->open($file, $swf_data);
}

sub open {
    my ($self, $file, $swf_data) = @_; 
    defined $self->{_file} and $self->close;
    $self->{_file} = ($file and $file =~ /^\*[\w:]+$/) ? $file : IO::Scalar->new($swf_data);
    $self;
}

1;

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
