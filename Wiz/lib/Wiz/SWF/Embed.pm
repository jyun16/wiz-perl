package Wiz::SWF::Embed;

use Wiz::Noose;

use Wiz::SWF::Constant qw(:hex_action_tag);
use Wiz::Constant qw(:common);
use Wiz::Util::Hash qw(args2hash);

our $VERSION = '0.001';

has data        => (is => 'rw');
has file        => (is => 'rw');
has output_file => (is => 'rw');

sub _prepare_embed_vars { }
sub _tail_embed_vars { }

sub init {
    my $self = shift;
    $self->data(undef);
}

sub embed_vars {
    my $self = shift;
    my $vars = args2hash @_;
    my $file = $self->file or return FALSE;

    unless ($vars) {
        open my $fh, '<', $file or die $!;
        binmode $fh;
        $self->data(join '', <$fh>);
        $self->output;
        return $self->data;
    }

    $self->init;
    $self->_prepare_embed_vars;
    my $tag_doaction = _make_tag_doaction($vars); 
    my $append_length = length $tag_doaction;

    my ($headtmp, $headtmp2, $tail);
    open my $fh, '<', $file or die $!;
    binmode $fh;
    read $fh, $headtmp, 9;
    my $headlen = _calclen_header($headtmp);
    read $fh, $headtmp2, $headlen - 9;
    my $header = $headtmp. $headtmp2;
    my $filesize = (stat $file)[7];
    read $fh, $tail, $filesize - $headlen;
    close $fh;

    $self->_tail_embed_vars(\$tail);
    my $data = substr($header, 0, 4)
        .h32($filesize + $append_length)
        .substr($header, 8)
        .$tag_doaction. $tail;
    $self->data($data);
    $self->output;
    $data;
}

sub _calclen_header {
    my ($header) = @_;
    $header or return 0;
    my $rb = ord(substr($header, 8, 1)) >> 3;
    int((((8 - (($rb * 4 + 5) & 7) ) & 7)+ $rb * 4 + 5) / 8) + 12 + 5;
}

sub _calclen_tag {
    my ($vars) = @_;
    $vars or return 0;
    my $ret = 0;
    for (keys %$vars) { defined $vars->{$_} and $ret += length($_) + length($vars->{$_}) + 11; }
    $ret + 1;
}

sub _make_tag_doaction {
    my ($vars) = @_;
    my $tag = "\x3f\x03". h32(_calclen_tag($vars));
    for (keys %$vars) {
        defined $vars->{$_} or next;
        $tag .= _make_tag_actionpush($_);
        $tag .= _make_tag_actionpush($vars->{$_});
        $tag .= "\x1d";
    }
    $tag. HEX_ACTION_END;
}

sub _make_tag_actionpush {
    my $v = shift;
    defined $v or return 0;
    HEX_ACTION_PUSH. h16(length($v) + 2). HEX_ACTION_END. $v. HEX_ACTION_END;
}

sub output {
    my $self = shift;
    $self->data or return;
    my $p = (@_ == 1) ? { file => $_[0] } : args2hash(@_);
    my $file = defined $p->{file} ? $p->{file} : $self->output_file;
    $file or return;
    open my $fw, '>', $file or die $!;
    print $fw $self->data;
    close $fw;
    TRUE;
}

sub h16 { pack 'v', shift; }
sub h32 { pack 'V', shift; }

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
