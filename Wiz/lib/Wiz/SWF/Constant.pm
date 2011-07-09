package Wiz::SWF::Constant;

use Wiz::ConstantExporter {
    HEX_ACTION_ADD              => "\x0A",
    HEX_ACTION_SUBTRACT         => "\x0B",
    HEX_ACTION_MULTIPLY         => "\x0C",
    HEX_ACTION_DIVIDE           => "\x0D",
    HEX_ACTION_EQUALS           => "\x0E",
    HEX_ACTION_LESS             => "\x0F",
    HEX_ACTION_AND              => "\x10",
    HEX_ACTION_OR               => "\x11",
    HEX_ACTION_NOT              => "\x12",
    HEX_ACTION_STRING_ADD       => "\x21",
    HEX_ACTION_STRING_EXTRACT   => "\x15",
    HEX_ACTION_STRING_LESS      => "\x29",
    HEX_ACTION_MBSTRING_LENGTH  => "\x31",
    HEX_ACTION_MBSTRING_EXTRACT => "\x35",
    HEX_ACTION_ASCII_TO_CHAR    => "\x33",
    HEX_ACTION_CHAR_TO_ASCII    => "\x32",
    HEX_ACTION_TO_INTEGER       => "\x18",
    HEX_ACTION_MBASCII_TO_CHAR  => "\x37",
    HEX_ACTION_MBCHAR_TO_ASCII  => "\x36",
    HEX_ACTION_PUSH             => "\x96",
    HEX_ACTION_POP              => "\x17",
    HEX_ACTION_CALL             => "\x9E",
    HEX_ACTION_IF               => "\x9D",
    HEX_ACTION_JUMP             => "\x99",
    HEX_ACTION_GET_VARIABLE     => "\x1C",
    HEX_ACTION_SET_VARIABLE     => "\x1D",
    HEX_ACTION_GET_PROPERTY     => "\x22",
    HEX_ACTION_SET_PROPERTY     => "\x23",
    HEX_ACTION_CLONE_SPRITE     => "\x24",
    HEX_ACTION_REMOVE_SPRITE    => "\x25",
    HEX_ACTION_GETURL2          => "\x9A",
    HEX_ACTION_GO_TO_FRAME2     => "\x9F",
    HEX_ACTION_SET_TARGET2      => "\x20",
    HEX_ACTION_START_DRAG       => "\x27",
    HEX_ACTION_END_DRAG         => "\x28",
    HEX_ACTION_WAIT_FOR_FRAME2  => "\x8D",
    HEX_ACTION_GET_TIME         => "\x34",
    HEX_ACTION_RANDOM_NUMBER    => "\x30",
    HEX_ACTION_TRACE            => "\x26",
    HEX_ACTION_END              => "\x00",
}, 'hex_action_tag';

use Wiz::ConstantExporter {
    DEFAULT_FRAME_RATE       => 10,
    DEFAULT_FRAME_SIZE_X     => 12_800,
    DEFAULT_FRAME_SIZE_Y     => 9_600,
}, 'default_swf_header';

use Wiz::ConstantExporter {
	DEFINE_BITS_LOSSLESS  => 20,
	DEFINE_BITS_JPEG2     => 21,
	DEFINE_BITS_LOSSLESS2 => 36,
}, 'tag_id';

use Wiz::ConstantExporter {
	LOSSLESS_FORMAT_8BIT           => 3,
	LOSSLESS_FORMAT_15BIT_RGB      => 4,
	LOSSLESS_FORMAT_24BIT_RGB      => 5,
	LOSSLESS2_FORMAT_8BIT          => 3,
	LOSSLESS2_FORMAT_32BIT_ARGB    => 5,
	JPEG2_ADDITION_SPECIFYING_DATA => "FFD8FFD9",
}, 'tag_value';

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
