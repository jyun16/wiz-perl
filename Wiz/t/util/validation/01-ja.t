#!/usr/bin/perl

use strict;
use warnings;

use lib qw(../../../lib);

use Wiz::Constant qw(:common);
use Wiz::Test qw(no_plan);
use Wiz::Util::Validation::JA qw(:all);

chtestdir;

sub main {
    is is_phone_number("03-3333-4444"), TRUE, "PHONE NUMBER(TRUE)";
    is is_phone_number("03333333-3333-4444"), FALSE, "PHONE NUMBER(FALSE)";
    is is_zip_code("111-4444"), TRUE, "ZIPCODE(TRUE)";
    is is_zip_code("1111-4444"), TRUE, "ZIPCODE(FALSE)";
    is is_katakana("アイウエオワヲンｱｵｳｴｵﾜｦﾝ"), TRUE, q|is_katakana("アイウエオワヲンｱｵｳｴｵﾜｦﾝ")|;
    is is_katakana("あアイウエオワヲンｱｵｳｴｵﾜｦﾝ"), FALSE, q|is_katakana("あアイウエオワヲンｱｵｳｴｵﾜｦﾝ")|;
    is is_hiragana("あいうえおわをん"), TRUE, q|is_hiragana("あいうえおわをん")|;
    is is_hiragana("あいうえおわをんカフェド鬼"), FALSE, q|is_hiragana("あいうえおわをんカフェド鬼")|;
    is is_furigana("アイウエオワヲン ｱｵｳｴｵﾜｦﾝ"), TRUE, q|is_furigana("アイウエオワヲン ｱｵｳｴｵﾜｦﾝ")|;
    is is_kanji("無双"), TRUE, q|is_hiragana("無双")|;
    is is_kanji("ムソウ"), FALSE, q|is_hiragana("ムソウ")|;

    return 0;
}

exit main;
