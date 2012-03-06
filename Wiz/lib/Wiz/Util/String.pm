package Wiz::Util::String;

use strict;
use warnings;

no warnings 'uninitialized';

=head1 NAME

Wiz::Util::String

=head1 VERSION

version 1.0

=cut

our $VERSION = '1.0';

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 EXPORTS

 trim_sp
 trim_quote
 trim_tag_html
 trim_line_code
 stromit
 max_strlen_in_list
 get_ln
 camel2normal
 normal2camel
 pascal2normal
 normal2pascal
 string2bytes
 logical_parse
 randstr
 split_prefix
 comma_separated_numeric
 csn
 substrj
 strlenj
 stromitj
 z2h
 h2z
 empty_or_zero
 named_format
 convert
 split_csv
 regexp_meta_escape

=cut

use Encode;
use Encode::Guess;
use Unicode::Japanese qw(unijp strcut);

use Wiz::Constant qw(:common);
use Wiz::Util::Array qw(args2array);

use Wiz::ConstantExporter [qw(
    trim_sp
    trim_quote
    trim_tag_html
    trim_line_code
    strinsert
    strcount
    stromit
    max_strlen_in_list
    get_ln
    camel2normal
    normal2camel
    pascal2normal
    normal2pascal
    string2bytes
    logical_parse
    randstr
    split_prefix
    comma_separated_numeric
    csn
    substrj
    strlenj
    stromitj
    z2h
    h2z
    empty_or_zero
    named_format
    convert
    split_csv
    regexp_meta_escape
)]; 

=head1 FUNCTIONS

=cut

=head2 $str = trim_sp($str or \$str)

triming the space

=cut

sub trim_sp {
    my $str = shift;
    if (ref $str) { $$str =~ s/^\s*/$1/; $$str =~ s/\s*$/$1/; return; }
    else { $str =~ s/^\s*//; $str =~ s/\s*$//; return $str; } }

=head2 $str = trim_quote($str or \$str)

triming the quote

=cut

sub trim_quote {
    my $str = shift;

    if (ref $str) {
        $$str =~ s/^"(.*)"$/$1/;
        $$str =~ s/^'(.*)'$/$1/;
        return;
    }
    else {
        $str =~ s/^"(.*)"$/$1/;
        $str =~ s/^'(.*)'$/$1/;
        return $str;
    }
}

=head2 $str = trim_tag_html($str or \$str)

triming the tag of html

=cut

sub trim_tag_html {
    my $str = shift;

    if (ref $str) { $$str =~ s/<.*?>//g; return; }
    else { $str =~ s/<.*?>//g; return $str; }
}

=head2 $str = trim_line_code($str or \$str)

triming the line code

=cut

sub trim_line_code {
    my $str = shift;

    if (ref $str) { $$str =~ s/[\r\n]//g; return; }
    else { $str =~ s/[\r\n]//g; return $str; }
}

=head2 $str = strinsert($str, $offset, $embed)

Embeds a string to the target string at offset.
Default value of $embed is "\n"

=cut

sub strinsert {
    my ($str, $offset, $embed) = @_;

    defined $offset or $offset = 0;
    defined $embed or $embed = "\n";
    if (ref $str) {
        substr($$str, $offset, 0) = $embed;
        return;
    }
    else {
        my $ret = $str;
        substr($ret, $offset, 0) = $embed;
        return $ret;
    }
}

=head2 $count = strcount($str, $target)

Returns occurrence count $target in $str.

=cut

sub strcount {
    my ($str, $target) = @_;
    return ref $str ? (scalar (() = $$str =~ /$target/g)) : (scalar (() = $str =~ /$target/g));
}

=head2 $str = stromit($str, $len, $append)

Cuts string at $len and appends string it.

=cut

sub stromit {
    my ($str, $len, $append) = @_;

    if (ref $str) {
        my $s = substr $$str, 0, $len;
        $$str = $s . $append;
        return;
    }
    else {
        return (substr $str, 0, $len) . $append;
    }
}

=head2 $max = max_strlen_in_list(@list)

max length of the string in the list

=cut

sub max_strlen_in_list {
    my $args = args2array(@_);
    my $max = 0;

    for (@$args) { my $n = length $_; $n > $max and $max = $n; }
    return $max;
}

=head2 $ln = get_ln($ln_str)

Gets LF, CR code from character of 'n', 'rn or 'r'.

=cut

sub get_ln {
    my $ln_str = shift;

    if ($ln_str eq 'n') { return "\x0A"; }
    elsif ($ln_str eq 'rn') { return "\x0D\x0A"; }
    elsif ($ln_str eq 'r') { return "\x0D"; }
}

=head2 $str = camel2normal($str)

Change notation type Camel to joined by under line.

=cut

sub camel2normal {
    my $str = shift;
    if (ref $str) {
        $$str =~s/([a-z0-9]+)/$1_/g;
        $$str =~s/_$//;
        $$str = lc $$str;
        return;
    }
    else {
        $str =~s/([a-z0-9]+)/$1_/g;
        $str =~s/_$//;
        $str = lc $str;
        return $str;
    }
}

=head2 $str = normal2camel($str)

=cut

sub normal2camel {
    my $str = shift;
    if (ref $str) { $$str =~ s/_([a-z])/uc $1/ieg; return; }
    else { $str =~ s/_([a-z])/uc $1/ieg; return $str; }
}

=head2 $str = pascal2normal($str)

=cut

sub pascal2normal {
    my $str = shift;
    if (ref $str) {
        $$str =~s/([A-Z]+[a-z]+)/$1_/g;
        $$str =~s/_$//;
        $$str = lc $$str;
        return;
    }
    else {
        $str =~s/([A-Z]+[a-z]+)/$1_/g;
        $str =~s/_$//;
        $str = lc $str;
        return $str;
    }
}

=head2 $str = normal2pascal($str)

=cut

sub normal2pascal {
    my $str = shift;
    my $ret = ref $str ? $str : \$str;
    $$ret =~ s/^([a-z])/uc $1/eg;
    normal2camel($ret);
    return $$ret;
}

=head2 $str = string2bytes($str)

=cut

sub string2bytes {
    my $str = shift;
    my $format = shift || '%X';
    if (ref $str) { $$str =~ s/(.)/sprintf($format, ord($1))/eg; return; }
    else { $str =~ s/(.)/sprintf('%X', ord($1))/eg; return $str; }
}


=head2 $str = randstr($len)

Returns randomized string that length is $len.

=cut

sub randstr {
    my ($len, @seed) = @_;
    @seed or @seed = ('a'..'z','A'..'Z',0..9);
    my $seed_len = @seed;
    my $ret = '';
    for (1..$len) { $ret .= $seed[rand $seed_len]; }
    return $ret;
}

=head2 $list = split_prefix($str, $num)

Returns splited $str at prefix as $num.

split_prefix("abcde", 1);

returns 

[ a, bcde ]

split_prefix("abcde", 2);

returns 

[ a, b, cde ]

=cut

sub split_prefix {
    my ($str, $num) = @_;
    my @ret = ();
    $num == 0 and return [ $str ];
    length $str <= $num and $num = (length $str) - 1;
    _split_prefix($str, 0, $num, \@ret);
    push @ret, (substr $str, $num);
    return \@ret;
}

sub _split_prefix {
    my ($str, $offset, $n, $ret) = @_;
    push @$ret, (substr $str, $offset, 1);
    ++$offset; --$n;
    $n and _split_prefix($str, $offset, $n, $ret);

}

*csn = 'comma_separated_numeric';
sub comma_separated_numeric {
    my ($str) = @_;
    if (ref $str) { TRUE while $$str =~ s/([+-]?\d+)(\d\d\d)/$1,$2/; return; }
    else { TRUE while $str =~ s/([+-]?\d+)(\d\d\d)/$1,$2/; return $str; }
}

sub substrj {
    my ($str, @args) = @_;
    defined $str or return '';
    my $s = ref $str ? $str : \$str;
    $$s eq '' and return '';
    my $enc = guess_encoding($$s)->name;
    encode($enc, substr(decode($enc, $$s), $args[0], $args[1]));
}

sub strlenj {
    my ($str) = @_;
    defined $str or return 0;
    my $s = ref $str ? $str : \$str;
    $$s eq '' and return 0;
    length decode(guess_encoding($$s)->name, $$s);
}

sub stromitj {
    my ($str, $len, $append) = @_;
    defined $str or return '';
    my $s = ref $str ? $str : \$str;
    $$s eq '' and return '';
    (strlenj($str) <= $len) and $append = '';
    my $ret = (substrj $$s, 0, $len) . $append;
    $$s = $ret;
    return $ret;
}

sub z2h {
    my ($str) = @_;
    if (ref $str) { $$str = unijp($$str)->z2h->get; return; }
    else { $str = unijp($str)->z2h->get; return $str; }
}

sub h2z {
    my ($str) = @_;
    if (ref $str) { $$str = unijp($$str)->z2h->get; return; }
    else { $str = unijp($str)->h2z->get; return $str; }
}

sub empty_or_zero {
    my ($str) = @_;
    ($str eq '' or $str == 0) ? TRUE : FALSE;
}

sub named_format {
    my ($format, $data) = @_;
    $format =~ s/{([^{]*?)}/exists $data->{$1}?$data->{$1}:"{$1}"/ge;
    return $format;
}

sub convert {
    my ($data, $to, $from) = @_;
    $data or return '';
    $from ||= guess_encoding($data)->name;
    encode($to, decode($from, $data));
}

sub split_csv {
    my ($data) = @_;
    $data .= ',';
    $data =~ s/("([^"]|"")*"|[^,]*),/$1$;/g;
    $data =~ s/"([^$;]*)"$;/$1$;/g;
    $data =~ s/""/"/g;
    my @ret = split /$;/, $data;
    return wantarray ? @ret : \@ret;
}

sub regexp_meta_escape {
    my ($re) = @_;
    my $rf = 0;
    unless (ref $re) { $re = \$re; $rf = 1; }
    $$re =~ s/([\$\[\]^?+*])/\\$1/g;
    return $rf ? $$re : undef;
}

=head1 AUTHOR

Junichiro NAKAMURA, C<< <jyun16@gmail.com> >>

[Modify] 
Toshihiro MORIMOTO, C<< <dealforest.net@gmail.com> >>

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
