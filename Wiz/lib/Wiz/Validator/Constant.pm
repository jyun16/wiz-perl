package Wiz::Validator::Constant;

use strict;
use warnings;

=head1 NAME

Wiz::Validator::Constant

=head1 VERSION

version 1.0

=cut

our $VERSION = '1.0';

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 EXPORTS

=cut

use Wiz::ConstantExporter {
    NO_ERROR                    => 0,
    IS_NULL                     => 1,
    IS_EMPTY                    => 2,
    IS_ZERO                     => 3,
    IS_NUMBER                   => 4,
    IS_INTEGER                  => 5,
    IS_NEGATIVE_INTEGER         => 6,
    IS_REAL                     => 7,
    IS_ALPHABET                 => 20,
    IS_ALPHABET_UC              => 21,
    IS_ALPHABET_LC              => 22,
    IS_ALPHABET_NUMBER          => 23,
    IS_ASCII                    => 24,
    IS_EQUALS                   => 40,
    IS_BIGGER                   => 41,
    IS_SMALLER                  => 42,
    IS_EMAIL_ADDRESS            => 30,
    IS_URL                      => 61,
    IS_HTTPURL                  => 62,
    IS_RFC822_DOT_ATOM_TEXT     => 70,
    IS_VALID_LOCAL              => 71,
    IS_VALID_DOMAIN             => 72,
    IS_PHONE_NUMBER             => 73,
    IS_ZIP_CODE                 => 74,
    IS_CREDIT_CARD_NUMBER       => 75,
    IS_NAME                     => 76,
    IS_VALID_DATE               => 77,
    IS_INVALID_DATE             => 78,
    IS_HIRAGANA                 => 101,
    IS_KATAKANA                 => 102,
    IS_KANJI                    => 103,
    IS_FURIGANA                 => 104,

    NOT_NULL                    => 201,
    NOT_EMPTY                   => 202,
    NOT_ZERO                    => 203,
    NOT_NUMBER                  => 204,
    NOT_INTEGER                 => 205,
    NOT_NEGATIVE_INTEGER        => 206,
    NOT_REAL                    => 207,
    NOT_ALPHABET                => 220,
    NOT_ALPHABET_UC             => 221,
    NOT_ALPHABET_LC             => 222,
    NOT_ALPHABET_NUMBER         => 223,
    NOT_ASCII                   => 224,
    NOT_EQUALS                  => 240,
    NOT_BIGGER                  => 241,
    NOT_SMALLER                 => 242,
    NOT_EMAIL_ADDRESS           => 230,
    NOT_URL                     => 261,
    NOT_HTTPURL                 => 262,
    NOT_RFC822_DOT_ATOM_TEXT    => 270,
    NOT_VALID_LOCAL             => 271,
    NOT_VALID_DOMAIN            => 272,
    NOT_PHONE_NUMBER            => 273,
    NOT_ZIP_CODE                => 274,
    NOT_CREDIT_CARD_NUMBER      => 275,
    NOT_NAME                    => 276,
    NOT_VALID_DATE              => 277,
    NOT_INVALID_DATE            => 278,

    NOT_HIRAGANA                => 301,
    NOT_KATAKANA                => 302,
    NOT_KANJI                   => 303,
    NOT_FURIGANA                => 304,

    OVER_MAX_SELECT             => 400,
    SHORT_MIN_SELECT            => 401,
    OVER_MAX_LENGTH             => 402,
    SHORT_MIN_LENGTH            => 403,
}, 'error'; 

use Wiz::ConstantExporter common => [qw(error)];

=head1 FUNCTIONS

=cut

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
