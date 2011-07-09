package Wiz::HTTP::Request::Upload;

use strict;

=head1 NAME

Wiz::HTTP::Request::Upload

=head1 VERSION

version 1.0

=cut

use Carp qw(cluck);
use IO::Scalar;
use File::MimeInfo::Magic;

use Wiz::Noose;
use Wiz::Constant qw(:common);
use Wiz::Util::Hash qw(args2hash);

has 'filename' => (is => 'rw');
has 'mimetype' => (is => 'rw');
has 'type' => (is => 'rw');
has 'size' => (is => 'rw');
has 'fh' => (is => 'rw');
has 'data' => (is => 'rw', required => 1);

my %MIME_IMAGE_EXT = (
    'image/gif'     => 'gif',
    'image/jpeg'    => 'jpg',
    'image/pjpeg'   => 'jpg',
    'image/png'     => 'png',
);

sub BUILD {
    my $self = shift;
    my ($args) = args2hash @_;
    my $data = $args->{data};
    $self->size(length $data);
    my $fh = new IO::Scalar(\$data);
    my $mimetype = File::MimeInfo::Magic::mimetype($fh);
    my ($type) = split /\//, $mimetype;
    $self->mimetype($mimetype);
    $self->type($type);
    seek $fh, 0, 0;
    $self->fh($fh);
}

*copy = 'copy_to';

sub ext {
    my $self = shift;
    return $MIME_IMAGE_EXT{$self->mimetype};
}

sub copy_to {
    my $self = shift;
    my ($to, $overwrite) = @_;
    if (!$overwrite and -f $to) { cluck "File already exist $to"; return FAIL; }
    open my $f, '>', $to or do { cluck "Can't open $to"; return FAIL; };
    print $f $self->data;
    close $f;
    return SUCCESS;
}

sub link_to { return 0; }

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
