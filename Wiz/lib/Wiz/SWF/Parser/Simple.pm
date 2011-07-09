package Wiz::SWF::Parser::Simple;

use Carp qw(confess);
use Compress::Zlib;
use Image::Magick;
use IO::Handle;
use SWF::Element;
use SWF::Parser;
use Wiz::Noose;
use Wiz::Util::Hash qw(args2hash);
use Wiz::Util::File qw(fix_path get_absolute_path);
use Wiz::SWF::Constant qw(:tag_id :tag_value);
use Wiz::SWF::Memory;

our $SHIFT_DEPTH = Image::Magick->QuantumDepth - 8;

has imagemagick => (is => 'rw');
has swf         => (is => 'rw');
has output      => (is => 'rw');
has id_map      => (is => 'rw');

sub BUILD {
    my $self = shift;
    my $args = args2hash @_;
    $self->id_map({});
    for (qw/swf/) { $args->{$_} and $self->$_(_exists_file($args->{$_})); }
    for (qw/output/) { $args->{$_} and $self->$_(get_absolute_path($args->{$_})); }
}

sub parse {
    my $self = shift;
    my ($callback) = @_;
    my ($output, $swf_data);
    my $parser = SWF::Parser->new(
        'header-callback' => sub {
            my ($self,      $signature, $version, $length,
                $xmin,      $ymin,      $xmax,    $ymax,
                $framerate, $framecount
            ) = @_;

            $output = Wiz::SWF::Memory->new(\$swf_data, undef, Version => $version, FrameRate => $framerate, FrameSize => [$xmin, $ymin, $xmax, $ymax]);
        },
        'tag-callback' => sub {
            my ($_self, $tagno, $length, $stream) = @_;
            my $tag = SWF::Element::Tag->new( Tag => $tagno, Length => $length );
            $tag->unpack($stream);
            $tag = $callback->($self, $tag, $tagno, $length, $stream);
            $tag->pack($output);
        },
    );
    $parser->parse_file($self->swf);
    $output->save;

    if ($self->output) {
        open my $fw, '>', $self->output or die $!;
        $fw->print($swf_data);
        $fw->close;
    }
    $output;
}

sub replace_image {
    my $self = shift;
    my $cb;
    if (ref $_[0] eq 'CODE') { $cb = $_[0]; }
    else { $self->id_map(args2hash @_); }

    $cb or $cb = sub {
        my $self = shift;
        my ($tag, $tagno, $length, $stream) = @_;

        if ($tag->isa('SWF::Element::Tag::DefineBits') 
            || $tag->isa('SWF::Element::Tag::LossLessBitmap')) {
            my $cid = $tag->CharacterID;

            my $image_path = $self->id_map->{$cid} or return $tag;
            $image_path = _exists_file($image_path);
            $self->imagemagick(new Image::Magick);
            $self->imagemagick->Read($image_path);
            my $type = $self->imagemagick->Get('magick') or return $tag;
            #execute only "jpeg" and "png".
            {
                no strict 'refs';
                my $method = 'cb_replace_'. lc $type;
                return $method->($self, $tag, $tagno, $length, $stream);
            }
        }
        $self->imagemagick(undef);
        return $tag;
    };
    $self->parse($cb);
}

sub _exists_file {
    my ($file_path) = @_;
    my $file = fix_path($file_path);
    -f $file ? $file : confess "not find file : ($file)";
}

sub cb_replace_jpeg {
    my $self = shift;
    my ($tag, $tagno, $length, $stream) = @_;
    my $jpeg_data = $self->imagemagick->ImageToBlob or return $tag;
    $jpeg_data = pack("H8", JPEG2_ADDITION_SPECIFYING_DATA). $jpeg_data;

    my $character_id = $tag->CharacterID;
    my $_tag = SWF::Element::Tag->new(Tag => DEFINE_BITS_JPEG2, Length => length $jpeg_data);
    $_tag->CharacterID($character_id);
    $_tag->JPEGData(new SWF::Element::BinData->add($jpeg_data));
    $_tag;
}

sub cb_replace_png {
    my $self = shift;
    my ($tag, $tagno, $length, $stream) = @_;
    my $format = $self->imagemagick->Get('type');
    $format eq 'Pallet'
        ? $self->cb_replace_png_definebitslossless($tag, $tagno, $length, $stream)
        : $self->cb_replace_png_definebitslossless2($tag, $tagno, $length, $stream);
}

sub cb_replace_png_definebitslossless {
    my $self = shift;
    my ($tag, $tagno, $length, $stream) = @_;
    my $image = $self->imagemagick;
    my ($width, $height, $colors) = $image->Get('width', 'height', 'colors');

    my $data;
    for ( my $i = 0 ; $i < $colors ; $i++ ) {
        my ($r, $g, $b, $a) = split ",", $image->Get("colormap[$i]");
        $data .= pack "CCC", $r >> $SHIFT_DEPTH, $g >> $SHIFT_DEPTH, $b >> $SHIFT_DEPTH;
    }

    my $i = 0;
    my $padding = pack("C", 0) x (4 - $width & 3);
    for ( my $y = 0 ; $y < $height ; $y++ ) {
        for ( my $x = 0 ; $x < $width ; $x++ ) {
            my $index = $image->Get("index[$x,$y]");
            $data .= pack "C", $index;
            $i++;
        }
        while ($i++ % 4 != 0) { $data .= $padding; }
        $i = 0;
    }

    my $comp_data = compress $data;
    my $character_id = $tag->CharacterID;
    my $_tag = SWF::Element::Tag->new(Tag => DEFINE_BITS_LOSSLESS, Length => length $comp_data);
    $_tag->CharacterID($character_id);
    $_tag->BitmapWidth($width);
    $_tag->BitmapHeight($height);
    $_tag->BitmapFormat(LOSSLESS_FORMAT_8BIT);
    $_tag->ZlibBitmapData(new SWF::Element::BinData->add($comp_data));
    $_tag;
}

sub cb_replace_png_definebitslossless2 {
    my $self = shift;
    my ($tag, $tagno, $length, $stream) = @_;

    my $data;
    my $image = $self->imagemagick;
    my ($width, $height) = $image->Get('width', 'height');
    for (my $y = 0; $y < $height; $y++) {
        for (my $x = 0; $x < $width; $x++) {
            my ($r, $g, $b, $a) = split ',', $image->Get("pixel[$x,$y]");
            $data .= pack "C*", 255 - ($a >> $SHIFT_DEPTH), $r >> $SHIFT_DEPTH, $g >> $SHIFT_DEPTH, $b >> $SHIFT_DEPTH;
        }
    }
    my $comp_data = compress $data;
    my $character_id = $tag->CharacterID;
    my $_tag = SWF::Element::Tag->new(Tag => DEFINE_BITS_LOSSLESS2, Length => length $comp_data);
    $_tag->CharacterID($character_id);
    $_tag->BitmapWidth($width);
    $_tag->BitmapHeight($height);
    $_tag->BitmapFormat(LOSSLESS2_FORMAT_32BIT_ARGB);
    $_tag->ZlibBitmapData(new SWF::Element::BinData->add($comp_data));
    $_tag;
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
