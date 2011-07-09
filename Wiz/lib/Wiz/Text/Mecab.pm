package Wiz::Text::Mecab;

=head1 NAME

Wiz::Test::Mecab

=head1 VERSION

version 1.0

=cut

our $VERSION = '1.0';

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut

=head1 EXPORTS

=cut

use MeCab;

use Wiz::Noose;

use Wiz::ConstantExporter {
    WORD_CLASS_NOUN             => 1,   # 名詞
    WORD_CLASS_VERB             => 2,   # 動詞
    WORD_CLASS_AUXILIARY_VERB   => 4,   # 助動詞
    WORD_CLASS_ADJECTIVE        => 8,   # 形容詞
    WORD_CLASS_ADVERB           => 16,  # 副詞
    WORD_CLASS_PARTICLES        => 32,  # 助詞
    WORD_CLASS_CODE             => 64,  # 記号
    WORD_CLASS_IGNORE           => 128, # 無視
}, 'word_class';

use Wiz::ConstantExporter [qw(
    mecab_parse
    mecab_parse_with_filter
    mecab_parse_with_output_filter
    mecab_parse_with_word_class
    wakachi
    filterd_wakachi
)];

use Wiz::ConstantExporter {
    MECAB_WORD                 => 0,    # 表層系
    MECAB_CLASS                => 1,    # 品詞
    MECAB_CLASS1               => 2,    # 品詞細分類1
    MECAB_CLASS2               => 3,    # 品詞細分類2
    MECAB_CLASS3               => 4,    # 品詞細分類3
    MECAB_CONJUGATED_FORM      => 5,    # 活用形
    MECAB_CONJUGATED_TYPE      => 6,    # 活用型
    MECAB_BASIC_PATTERN        => 7,    # 原型
    MECAB_READING              => 8,    # 読み
    MECAB_PRONUNCIATION        => 9,    # 発音
} , 'mecab';

sub mecab_parse {
    my ($str, $output, $word_class) = @_;
    if (defined $output and defined $word_class) { mecab_parse_with_filter(@_); }
    elsif (defined $output) { return mecab_parse_with_output_filter($str, $output); }
    elsif (defined $word_class) { return mecab_parse_with_word_class($str, $word_class); }
    else {
        my $mecab = new MeCab::Tagger;
        my @ret;
        my $node = $mecab->parseToNode($str);
        while ($node = $node->{next}) {
            $node->{surface} eq '' and next;
            push @ret, [ $node->{surface}, split /,/, $node->{feature} ]; 
        }
        return wantarray ? @ret : \@ret;
    }
}

sub mecab_parse_with_output_filter {
    my ($str, $output) = @_;
    my $mecab = new MeCab::Tagger;
    my @ret;
    my $node = $mecab->parseToNode($str);
    while ($node = $node->{next}) {
        $node->{surface} eq '' and next;
        my @n = ($node->{surface}, split /,/, $node->{feature});
        push @ret, [ map { $n[$_] } @$output ];
    }
    return wantarray ? @ret : \@ret;
}

sub mecab_parse_with_word_class {
    my ($str, $word_class) = @_;
    my $word_class_map = create_word_class_map($word_class);
    my $mecab = new MeCab::Tagger;
    my @ret;
    my $node = $mecab->parseToNode($str);
    while ($node = $node->{next}) {
        $node->{surface} eq '' and next;
        my @n = ($node->{surface}, split /,/, $node->{feature});
        $word_class_map->{$n[MECAB_CLASS]} or next;
        push @ret, \@n;
    }
    return wantarray ? @ret : \@ret;
}

sub mecab_parse_with_filter {
    my ($str, $output, $word_class) = @_;
    my $word_class_map = create_word_class_map($word_class);
    my $mecab = new MeCab::Tagger;
    my @ret;
    my $node = $mecab->parseToNode($str);
    while ($node = $node->{next}) {
        $node->{surface} eq '' and next;
        my @n = ($node->{surface}, split /,/, $node->{feature});
        $word_class_map->{$n[MECAB_CLASS]} or next;
        push @ret, [ map { $n[$_] } @$output ];
    }
    return wantarray ? @ret : \@ret;
}

sub wakachi {
    my ($str, $word_class) = @_;
    if (defined $word_class) { filterd_wakachi(@_); }
    else {
        my $mecab = new MeCab::Tagger;
        my @ret;
        my $node = $mecab->parseToNode($str);
        while ($node = $node->{next}) {
            $node->{surface} eq '' and next;
            push @ret, $node->{surface};
        }
        return wantarray ? @ret : \@ret;
    }
}

sub filterd_wakachi {
    my ($str, $word_class) = @_;
    my $word_class_map = create_word_class_map($word_class);
    my $mecab = new MeCab::Tagger;
    my @ret;
    my $node = $mecab->parseToNode($str);
    while ($node = $node->{next}) {
        $node->{surface} eq '' and next;
        my @n = ($node->{surface}, split /,/, $node->{feature});
        $word_class_map->{$n[MECAB_CLASS]} or next;
        push @ret, $n[MECAB_WORD];
    }
    return wantarray ? @ret : \@ret;
}

sub create_word_class_map {
    my ($word_class) = @_;
    my %ret = ();
    $word_class & WORD_CLASS_NOUN and $ret{'名詞'} = 1;
    $word_class & WORD_CLASS_VERB and $ret{'動詞'} = 1;
    $word_class & WORD_CLASS_AUXILIARY_VERB and $ret{'助動詞'} = 1;
    $word_class & WORD_CLASS_ADJECTIVE and $ret{'形容詞'} = 1;
    $word_class & WORD_CLASS_ADVERB and $ret{'副詞'} = 1;
    $word_class & WORD_CLASS_PARTICLES and $ret{'助詞'} = 1;
    $word_class & WORD_CLASS_CODE and $ret{'記号'} = 1;
    $word_class & WORD_CLASS_IGNORE and $ret{'無視'} = 1;
    return \%ret;
}

=head1 AUTHOR

Junichiro NAKAMURA, C<< <jyun16@gmail.com> >>

=head1 COPYRIGHT & LICENSE

Copyright 2010 The Wiz Project. All rights reserved.

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
