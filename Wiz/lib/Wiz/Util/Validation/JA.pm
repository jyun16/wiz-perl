package Wiz::Util::Validation::JA;

use strict;
use warnings;

=head1 NAME

Wiz::Util::Validation::JA

=head1 VERSION

version 1.0

=cut

our $VERSION = '1.0';

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 EXPORTS

    is_phone_number
    is_zip_code
    is_hiragana
    is_katakana
    is_kanji
    is_furigana

=cut

use Encode;
use Encode::Guess;

use Wiz::Constant qw(:common);
use Wiz::ConstantExporter [qw(
    is_phone_number
    is_zip_code
    is_hiragana
    is_katakana
    is_kanji
    is_furigana
)]; 

=head1 FUNCTIONS

=head2 $bool = is_phone_number($str)

Returns TRUE if $str is phone number.

=cut

sub is_phone_number {
    my ($str) = @_;
    $str eq '' and return TRUE;
    my ($n1, $n2, $n3) = ($str =~ /(\d*)-(\d*)-(\d*)/) or return FALSE;
    $n1 !~ /^0/ and return FALSE;
    (length $n1 > 5 or length $n2 > 4) and return FALSE;
    my $len3 = length $n3;
    ($len3 < 4 and 5 < $len3) and return FALSE;
    return TRUE;
}

=head2 $bool = is_zip_code($str)

Returns TRUE if $str is zip code.

=cut

sub is_zip_code {
    my ($str) = @_;
    $str eq '' and return TRUE;
    return $str =~ /\d{3}-\d{4}/ || FALSE;
}

sub is_hiragana {
    my ($str) = @_;
    ref $str and $str = $$str;
    $str eq '' and return TRUE;
    $str = decode(guess_encoding($str), $str);
    return $str =~ /^\p{Hiragana}*$/ || FALSE;
}

sub is_katakana {
    my ($str) = @_;
    ref $str and $str = $$str;
    $str eq '' and return TRUE;
    $str = decode(guess_encoding($str), $str);
    $str =~ s/[\x{2015}\x{2500}\x{2501}\x{30FC}\x{02D7}\x{2010}\x{2012}\x{FE63}\x{FF0D}]/-/g;
    return $str =~ /^(?:\p{Katakana}|\p{Hyphen})*$/ || FALSE;
}

sub is_kanji {
    my ($str) = @_;
    ref $str and $str = $$str;
    $str eq '' and return TRUE;
    $str = decode(guess_encoding($str), $str);
    return $str =~ /^\p{Han}*$/ || FALSE;
}

sub is_furigana {
    my ($str) = @_;
    ref $str and $str = $$str;
    $str eq '' and return TRUE;
    $str = decode(guess_encoding($str), $str);
    return $str =~ /^(?:\p{Katakana}|\s)*$/ || FALSE;
}

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
