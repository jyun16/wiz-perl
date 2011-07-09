package Wiz::Util::String::UTF8;

use strict;

=head1 NAME

Wiz::Util::String::UTF8

=head1 VERSION

version 1.0

=cut

our $VERSION = '1.0';

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 EXPORTS

=cut

use Encode;
use Encode::Guess;
use Data::Dumper ();
use Wiz::ConstantExporter [qw(
    utf8_off
    utf8_off_recursive
    utf8_on
    utf8_on_recursive
    hate_utf8_dumper
    Dumper
    dumper
)]; 

sub utf8_off {
    my ($s, $enc) = @_;
    my $h = ref $s ? $s : \$s;
    utf8::is_utf8 $$h or return $$h;
    if ($enc) {
        $$h = Encode::encode($enc, $$h);
    }
    else {
        defined $$h or return;
        $$h eq '' and return '';
        my $g = Encode::Guess::guess_encoding($$h);
        $$h = $g->encode($$h);
    }
}

sub utf8_off_recursive {
    my ($d, $enc) = @_;
    return _utf8_off_recursive($d, $enc);
}

sub _utf8_off_recursive {
    my ($d, $enc) = @_;
    my $r = ref $d;
    if ($r eq 'ARRAY') {
        my @ret = ();
        for (@$d) { push @ret, _utf8_off_recursive($_, $enc); }
        return \@ret;
    }
    elsif ($r eq 'HASH') {
        my %ret = ();
        for (keys %$d) { $ret{_utf8_off_recursive($_, $enc)} = _utf8_off_recursive($d->{$_}, $enc); }
        return \%ret;
    }
    elsif ($r) {
        return $d;
    }
    else { return utf8_off($d, $enc) }
}

sub utf8_on {
    my ($s, $enc) = @_;
    my $h = ref $s ? $s : \$s;
    utf8::is_utf8 $$h and return $$h;
    if ($enc) {
        $$h = Encode::decode($enc, $$h);
    }
    else {
        defined $$h or return;
        $$h eq '' and return '';
        my $g = Encode::Guess::guess_encoding($$h);
        $$h = $g->decode($$h);
    }
}

sub utf8_on_recursive {
    my ($d, $enc) = @_;
    return _utf8_on_recursive($d, $enc);
}

sub _utf8_on_recursive {
    my ($d, $enc) = @_;
    my $r = ref $d;
    if ($r eq 'ARRAY') {
        my @ret = ();
        for (@$d) { push @ret, _utf8_on_recursive($_, $enc); }
        return \@ret;
    }
    elsif ($r eq 'HASH') {
        my %ret = ();
        for (keys %$d) { $ret{_utf8_on_recursive($_, $enc)} = _utf8_on_recursive($d->{$_}, $enc); }
        return \%ret;
    }
    elsif ($r) {
        return $d;
    }
    else { return utf8_on($d, $enc) }
}

sub hate_utf8_dumper {
    local $Data::Dumper::Sortkeys = 1;
    local $Data::Dumper::Terse = 1;
    local $Data::Dumper::Indent = 1;
    if (@_ > 1) {
        Data::Dumper::Dumper utf8_off_recursive(\@_);
    }
    else {
        Data::Dumper::Dumper utf8_off_recursive(shift);
    }
}

*Dumper = 'hate_utf8_dumper';
*dumper = 'hate_utf8_dumper';

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
