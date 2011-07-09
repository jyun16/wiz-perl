#!/usr/bin/perl

use strict;
use warnings;

use lib qw(../../lib);

use Wiz::Test qw(no_plan);
use Wiz::Util::String qw(:all);

chtestdir;

sub main {
    trim_sp_test();
    trim_quote_test();
    trim_tag_html_test();
    trim_line_code_test();
    string2bytes_test();
    strinsert_test();
    stromit_test();
    max_strlen_in_list_test();
    get_ln_test();
    camel2normal_test();
    split_prefix_test();
    j_test();
    named_format_test();
    return 0;
}

sub trim_sp_test {
    my $data = "\t \t \thoge \t fuga\t  \t  \t";
    is(trim_sp($data), "hoge \t fuga", 'trim_sp($data)');
    trim_sp(\$data);
    is($data, "hoge \t fuga", 'trim_sp(\$data)');
}

sub trim_quote_test {
    my $hoge = q|'ho'--'ge'|;
    my $fuga = q|"fu"--"ga"|;
    my $foo = q|"fo'--"o'|;

    is(trim_quote($hoge), q|ho'--'ge|, q|trim_quote('ho'--'ge')|);
    is(trim_quote($fuga), q|fu"--"ga|, q|trim_quote("fu"--"ga")|);
    is(trim_quote($foo), $foo, q|trim_quote("fo'--"o')|);
    trim_quote(\$hoge);
    is($hoge, q|ho'--'ge|, q|trim_quote(\'ho'--'ge')|);
    trim_quote(\$fuga);
    is($fuga, q|fu"--"ga|, q|trim_quote(\"fu"--"ga")|);
    trim_quote(\$foo);
    is($foo, q|"fo'--"o'|, q|trim_quote(\"fo'--"o')|);
}

sub trim_tag_html_test {
    my $hoge = "<p>hoge</p>";
    my $fuga = "<div> <p>fuga</p> </div>";

    is(trim_tag_html($hoge), 'hoge', q|<p>hoge</p>|);
    is(trim_tag_html($fuga), ' fuga ', q|<div> <p>fuga</p> </div>|);
    trim_tag_html(\$hoge);
    is($hoge, 'hoge', q|<p>hoge</p>|);
    trim_tag_html(\$fuga);
    is($fuga, ' fuga ', q|<div> <p>fuga</p> </div>|);
}

sub trim_line_code_test {
    my $hoge  = "hoge\r\nhoge";

    is(trim_line_code($hoge), 'hogehoge', q|trim_line_code('hoge\nhoge)|);
    trim_line_code(\$hoge);
    is($hoge, 'hogehoge', q|trim_line_code('hoge\nhoge)|);
}

sub string2bytes_test {
    my $hoge  = "hogehoge";

    is(string2bytes($hoge), '686F6765686F6765', q|string2bytes('hogehoge')|);
    string2bytes(\$hoge);
    is($hoge, '686F6765686F6765', q|string2bytes(\'hogehoge')|);
}

sub strinsert_test {
    my $hoge = 'hoge';

    is(strinsert($hoge, 2, '---'), 'ho---ge', q|strinsert($hoge, 2, '---')|);
    strinsert(\$hoge, 2, '---');
    is($hoge, 'ho---ge', q|strinsert(\$hoge, 2, '---')|);
}

sub stromit_test {
    my $hoge = 'hoge';
    is(stromit($hoge, 2, '...'), 'ho...', q|stromit($hoge, 2, '...')|);
    stromit(\$hoge, 2, '...');
    is($hoge, 'ho...', q|stromit(\$hoge, 2, '---')|);

}

sub max_strlen_in_list_test {
    my @list = qw(hoge fuga foo bar 0123456789);
    is(max_strlen_in_list(@list), 10, q|max_strlen_in_list(@list)|);
}

sub get_ln_test {
    is(get_ln('n'), "\n", q|get_ln('n')|);
    is(get_ln('rn'), "\r\n", q|get_ln('rn')|);
    is(get_ln('r'), "\r", q|get_ln('r')|);
}

sub camel2normal_test {
    is(camel2normal('Hoge'), 'hoge', q|camel2normal('Hoge')|);
    is(camel2normal('HogeFuga'), 'hoge_fuga', q|camel2normal('HogeFuga')|);
    is(camel2normal('HogeFugaFoo'), 'hoge_fuga_foo', q|camel2normal('HogeFugaFoo')|);
    my $str = 'FooBar';
    camel2normal(\$str);
    is($str, 'foo_bar', q|camel2normal(\$str)|);
}

sub split_prefix_test {
    is_deeply split_prefix('abcde', 0), [ 'abcde' ], q|split_prefix('abcde', 0)|;
    is_deeply split_prefix('abcde', 1), [ 'a', 'bcde' ], q|split_prefix('abcde', 1)|;
    is_deeply split_prefix('abcde', 2), [ 'a', 'b', 'cde' ], q|split_prefix('abcde', 2)|;
    is_deeply split_prefix('abcde', 4), [ 'a', 'b', 'c', 'd', 'e' ], q|split_prefix('abcde', 4)|;
    is_deeply split_prefix('abcde', 5), [ 'a', 'b', 'c', 'd', 'e' ], q|split_prefix('abcde', 5)|;
    is_deeply split_prefix('abcde', 6), [ 'a', 'b', 'c', 'd', 'e' ], q|split_prefix('abcde', 6)|;
}

sub j_test {
    my $str = 'ほげほげふがふが';
    is strlenj(undef), 0;
    is strlenj(''), 0;
    is strlenj($str), 8;
    is strlenj(\$str), 8;
    is stromitj(undef, 4, '...'), '';
    is stromitj($str, 4, '...'), 'ほげほげ...';
    is stromitj('ほげ', 4, '...'), 'ほげ';
    is stromitj('ほげほげ', 4, '...'), 'ほげほげ'; 
    is substrj($str, 0, 4), 'ほげほげ';
}

sub named_format_test {
    is named_format('hoge: {hoge}, fuga: {{fuga}}, {foo}', { hoge => 'HOGE', fuga => 'FUGA' }), 
        q|hoge: HOGE, fuga: {FUGA}, {foo}|,
        q|named_format('hoge: {hoge}, fuga: {{fuga}}, {foo}', { hoge => 'HOGE', fuga => 'FUGA' })|;
}

exit main;
