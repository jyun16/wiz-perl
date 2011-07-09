#!/usr/bin/perl

use strict;
use warnings;

use lib qw(../../lib);

use Wiz::Constant qw(:common);
use Wiz::Test qw(no_plan);
use Wiz::Util::Validation qw(:all);

chtestdir;

sub main{
    is is_null(undef), TRUE, "NULL(TRUE)";
    is is_null(''), FALSE, "NULL(FALSE)";
    is is_empty(''), TRUE, "EMPTY(TRUE)";
    is is_empty(undef), TRUE, "EMPTY(TRUE)";
    is is_empty('a'), FALSE, "EMPTY(FALSE)";
    is is_zero(0), TRUE, "ZERO(TRUE)";

    is is_alphabet("abcxyzABCXYZ"), TRUE, "ALPHA(TRUE)";
    is is_alphabet("abcxyz0ABCXYZ"), FALSE, "ALPHA(FALSE)";

    is is_number("1,000"), TRUE, "NUMBER(TRUE)";
    is is_number("01234z56789"), FALSE, "NUMBER(FALSE)";
    is is_integer("-1,000"), TRUE, "INTEGER(TRUE)";
    is is_integer("-1,000.0"), FALSE, "INTEGER(FALSE)";
    is is_real("-1,000.0"), TRUE, "REAL(TRUE)";

    is is_alphabet_number("abcxyzABCXYZ09"), TRUE, "ALNUM(TRUE)";
    is is_alphabet_number("abcxyz!ABCXYZ09"), FALSE, "ALNUM(FALSE)";

    is is_ascii(q|abcxyzABCXYZ!"#$%&'()|), TRUE, "ASCII(TRUE)";

    is is_email_address('jn@jn.orz'), TRUE, "MAIL ADDRESS(TRUE)";
    is is_email_address('j!/#n@jn.orz'), TRUE, "MAIL ADDRESS(TRUE)";
    is is_email_address('j\@n\@jn.orz'), FALSE, "MAIL ADDRESS(FALSE)";

    is is_integer("1234567890"), TRUE, "INTEGER(TRUE)";
    is is_integer("1.34"), FALSE, "INTEGER(FALSE)";

    is not_null(''), TRUE, "NOT_NULL(TRUE)";
    is not_null(undef), FALSE, "NOT_NULL(FALSE)";
    is not_empty('hoge'), TRUE, "NOT_EMPTY(TRUE)";
    is not_empty(''), FALSE, "NOT_EMPTY(FALSE)";

    is is_url('http://hoge:fuga@hoge.com/hogeaeafjeajkkfaj)('), TRUE, "IS_URL(TRUE)";
    is is_url('ftp://ho-ge:fuga@hoge.com/hogeaeafjeajkkfaj)('), TRUE, "IS_URL(TRUE)";
    is is_url('http://hoge:fuga@hoge.com/hogeaeafjeajkkfaj) ('), FAIL, "IS_URL(FALSE)";

    is is_httpurl('http://hoge:fuga@hoge.com/hogeaeafjeajkkfaj)('), TRUE, "IS_HTTPURL(TRUE)";
    is is_httpurl('ftp://hoge:fuga@hoge.com/hogeaeafjeajkkfaj)('), FALSE, "IS_HTTPURL(TRUE)";

    is is_credit_card_number('1111-2222-3333-4444'), TRUE, "IS_CREDIT_CARD_NUMBER(TRUE)";
    is is_credit_card_number('111-2222-3333-4444'), FALSE, "IS_CREDIT_CARD_NUMBER(FALSE)";

    is is_name('hoge fuga'), TRUE, q|IS_NAME|;

    is is_valid_date('2009-02-28'), TRUE, q|is_valid_date('2009-02-28')|;
    is is_invalid_date('2009-02-29'), TRUE, q|is_invalid_date('2009-02-29')|;

    return 0;
}

exit main;
