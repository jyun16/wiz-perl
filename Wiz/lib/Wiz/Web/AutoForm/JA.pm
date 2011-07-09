package Wiz::Web::AutoForm::JA;

use strict;
use warnings;

no warnings 'uninitialized';

=head1 NAME

Wiz::Web::AutoForm::JA

=head1 VERSION

version 1.0

=cut

our $VERSION = '1.0';

=head1 SYNOPSIS

SEE L<Wiz::Web::AutoForm::Tutorial>

=cut

use Wiz::Web::AutoForm qw(:all);

use base 'Wiz::Web::AutoForm';

our %options = (
    gender  => [
        ''  => '',
        1   => '女性',
        2   => '男性',
    ], 
    prefecture   => [
        ''  => '',
        1 => '北海道',
        2 => '青森県',
        3 => '岩手県',
        4 => '宮城県',
        5 => '秋田県',
        6 => '山形県',
        7 => '福島県',
        8 => '茨城県',
        9 => '栃木県',
        10 => '群馬県',
        11 => '埼玉県',
        12 => '千葉県',
        13 => '東京都',
        14 => '神奈川県',
        15 => '新潟県',
        16 => '富山県',
        17 => '石川県',
        18 => '福井県',
        19 => '山梨県',
        20 => '長野県',
        21 => '岐阜県',
        22 => '静岡県',
        23 => '愛知県',
        24 => '三重県',
        25 => '滋賀県',
        26 => '京都府',
        27 => '大阪府',
        28 => '兵庫県',
        29 => '奈良県',
        30 => '和歌山県',
        31 => '鳥取県',
        32 => '島根県',
        33 => '岡山県',
        34 => '広島県',
        35 => '山口県',
        36 => '徳島県',
        37 => '香川県',
        38 => '愛媛県',
        39 => '高知県',
        40 => '福岡県',
        41 => '佐賀県',
        42 => '長崎県',
        43 => '熊本県',
        44 => '大分県',
        45 => '宮崎県',
        46 => '鹿児島県',
        47 => '沖縄県',
    ],
    job  => [
        ''  => '',
        1   => '(会社員)販売・営業',
        2   => '(会社員)総務・人事',
        3   => '(会社員)経理・財務',
        4   => '(会社員)企画・マーケティング',
        5   => '(会社員)広報・宣伝',
        6   => '(会社員)研究・開発',
        7   => '(会社員)エンジニア',
        8   => '管理職',
        9   => '役員',
        10  => '会社経営',
        11  => '公務員',
        12  => '教員',
        13  => '自営業',
        14  => '農林水産',
        15  => 'アルバイト・派遣等',
        16  => '学生',
        17  => '主婦',
        18  => '専門職(医師・弁護士等)',
        19  => '無職',
        20  => 'その他',
    ],
    hobby   => [
        1   => '音楽鑑賞',
        2   => '映画鑑賞',
        3   => '楽器演奏',
        4   => '読書',
        5   => 'スポーツ・体力作り',
        6   => 'スポーツ観戦',
        7   => 'ファッション',
        8   => '美容',
        9   => 'ダイエット',
        10  => '買い物',
        11  => 'ドライブ',
        12  => '街歩き',
        13  => '旅行',
        14  => 'ペット',
        15  => '習い事',
        16  => '語学',
        17  => '漫画',
        18  => 'ゲーム',
        19  => 'テレビ',
        20  => 'インターネット',
        21  => 'アウトドア',
        22  => '写真撮影',
        23  => '舞台鑑賞',
        24  => '美術鑑賞',
        25  => '美術制作',
        26  => '手芸・工作',
        27  => '料理',
        28  => 'お菓子作り',
        29  => '園芸・ガーデニング',
        30  => '日曜大工',
        31  => 'グルメ',
        32  => 'お酒',
        33  => 'カラオケ',
        34  => 'ギャンブル',
        35  => 'その他',
    ],
);

sub _tag_gender {
    my $self = shift;
    my ($name, $value, $conf) = @_;
    return $self->_tag_select_with_options($name, $value, $conf, $options{gender});
}

sub _tag_prefecture {
    my $self = shift;
    my ($name, $value, $conf) = @_;

    $value = _tag_value($value, $conf);

    my $ret = qq|<select name="$name"|;
    $ret .= _tag_append_attribute($conf->{attribute});
    $ret .= ">\n";

    my @selected = ();
    $value and $selected[$value] = ' selected';
    if (defined $conf->{empty}) {
        if ($conf->{no_group}) {
            $ret .= qq|\t\t<option value=""$selected[0]>$conf->{empty}</option>\n|;
        }
        else {
            $ret .= qq|\t<optgroup label="">|;
            $ret .= qq|\t\t<option value=""$selected[0]>$conf->{empty}</option>\n|;
            $ret .= qq|\t</optgroup>|;
        }
    }
    $ret .= $conf->{no_group} ?
        __tag_prefecture_no_group(\@selected) : __tag_prefecture(\@selected);
    return $ret;
}

sub __tag_prefecture {
    my @selected = @{$_[0]};
    return <<EOS;
    <optgroup label="北海道">
        <option value="1"$selected[1]>北海道</option>
    </optgroup>
    <optgroup label="東北">
        <option value="2"$selected[2]>青森県</option>
        <option value="3"$selected[3]>岩手県</option>  
        <option value="4"$selected[4]>宮城県</option>
        <option value="5"$selected[5]>秋田県</option>
        <option value="6"$selected[6]>山形県</option>
        <option value="7"$selected[7]>福島県</option>
    </optgroup>
    <optgroup label="関東">
        <option value="8"$selected[8]>茨城県</option>
        <option value="9"$selected[9]>栃木県</option>
        <option value="10"$selected[10]>群馬県</option>
        <option value="11"$selected[11]>埼玉県</option>
        <option value="12"$selected[12]>千葉県</option>
        <option value="13"$selected[13]>東京都</option>
        <option value="14"$selected[14]>神奈川県</option>
    </optgroup>
    <optgroup label="甲信越">
        <option value="15"$selected[15]>新潟県</option>
        <option value="19"$selected[19]>山梨県</option>
        <option value="20"$selected[20]>長野県</option>
    </optgroup>
    <optgroup label="北陸">
        <option value="16"$selected[16]>富山県</option>
        <option value="17"$selected[17]>石川県</option>
        <option value="18"$selected[18]>福井県</option>
    </optgroup>
    <optgroup label="東海">
        <option value="21"$selected[21]>岐阜県</option>
        <option value="22"$selected[22]>静岡県</option>
        <option value="23"$selected[23]>愛知県</option>
    </optgroup>
    <optgroup label="近畿">
        <option value="24"$selected[24]>三重県</option>
        <option value="25"$selected[25]>滋賀県</option>
        <option value="26"$selected[26]>京都府</option>
        <option value="27"$selected[27]>大阪府</option>
        <option value="28"$selected[28]>兵庫県</option>
        <option value="29"$selected[29]>奈良県</option>
        <option value="30"$selected[30]>和歌山県</option>
    </optgroup>
    <optgroup label="中国">
        <option value="31"$selected[31]>鳥取県</option>
        <option value="32"$selected[32]>島根県</option>
        <option value="33"$selected[33]>岡山県</option>
        <option value="34"$selected[34]>広島県</option>
        <option value="35"$selected[35]>山口県</option>
    </optgroup>
    <optgroup label="四国">
        <option value="36"$selected[36]>徳島県</option>
        <option value="37"$selected[37]>香川県</option>
        <option value="38"$selected[38]>愛媛県</option>
        <option value="39"$selected[39]>高知県</option>
    </optgroup>
    <optgroup label="九州">
        <option value="40"$selected[40]>福岡県</option>
        <option value="41"$selected[41]>佐賀県</option>
        <option value="42"$selected[42]>長崎県</option>
        <option value="43"$selected[43]>熊本県</option>
        <option value="44"$selected[44]>大分県</option>
        <option value="45"$selected[45]>宮崎県</option>
        <option value="46"$selected[46]>鹿児島県</option>
    </optgroup>
    <optgroup label="沖縄">
        <option value="47"$selected[47]>沖縄県</option>
    </optgroup>
</select>
EOS
}

sub __tag_prefecture_no_group {
    my @selected = @{$_[0]};
    return <<EOS;
        <option value="1"$selected[1]>北海道</option>
        <option value="2"$selected[2]>青森県</option>
        <option value="3"$selected[3]>岩手県</option>  
        <option value="4"$selected[4]>宮城県</option>
        <option value="5"$selected[5]>秋田県</option>
        <option value="6"$selected[6]>山形県</option>
        <option value="7"$selected[7]>福島県</option>
        <option value="8"$selected[8]>茨城県</option>
        <option value="9"$selected[9]>栃木県</option>
        <option value="10"$selected[10]>群馬県</option>
        <option value="11"$selected[11]>埼玉県</option>
        <option value="12"$selected[12]>千葉県</option>
        <option value="13"$selected[13]>東京都</option>
        <option value="14"$selected[14]>神奈川県</option>
        <option value="15"$selected[15]>新潟県</option>
        <option value="19"$selected[19]>山梨県</option>
        <option value="20"$selected[20]>長野県</option>
        <option value="16"$selected[16]>富山県</option>
        <option value="17"$selected[17]>石川県</option>
        <option value="18"$selected[18]>福井県</option>
        <option value="21"$selected[21]>岐阜県</option>
        <option value="22"$selected[22]>静岡県</option>
        <option value="23"$selected[23]>愛知県</option>
        <option value="24"$selected[24]>三重県</option>
        <option value="25"$selected[25]>滋賀県</option>
        <option value="26"$selected[26]>京都府</option>
        <option value="27"$selected[27]>大阪府</option>
        <option value="28"$selected[28]>兵庫県</option>
        <option value="29"$selected[29]>奈良県</option>
        <option value="30"$selected[30]>和歌山県</option>
        <option value="31"$selected[31]>鳥取県</option>
        <option value="32"$selected[32]>島根県</option>
        <option value="33"$selected[33]>岡山県</option>
        <option value="34"$selected[34]>広島県</option>
        <option value="35"$selected[35]>山口県</option>
        <option value="36"$selected[36]>徳島県</option>
        <option value="37"$selected[37]>香川県</option>
        <option value="38"$selected[38]>愛媛県</option>
        <option value="39"$selected[39]>高知県</option>
        <option value="40"$selected[40]>福岡県</option>
        <option value="41"$selected[41]>佐賀県</option>
        <option value="42"$selected[42]>長崎県</option>
        <option value="43"$selected[43]>熊本県</option>
        <option value="44"$selected[44]>大分県</option>
        <option value="45"$selected[45]>宮崎県</option>
        <option value="46"$selected[46]>鹿児島県</option>
        <option value="47"$selected[47]>沖縄県</option>
</select>
EOS
}

sub prefecture_label {
    my $self = shift;
    my ($index) = @_;
    $options{prefecture}[$index * 2 + 1];
}

sub _tag_job {
    my $self = shift;
    my ($name, $value, $conf) = @_;
    return $self->_tag_select_with_options($name, $value, $conf, $options{job});
}

sub _tag_hobby {
    my $self = shift;
    my ($name, $value, $conf) = @_;
    return $self->_tag_checkbox_with_options($name, $value, $conf, $options{hobby});
}

sub _tag_zip_code {
    my $self = shift;
    my ($name, $value, $conf) = @_;
    my @value = split /-/, $value;
    $conf->{attribute}{size} = 3; $conf->{attribute}{maxlength} = 3;
    my $ret = $self->_tag_text("${name}_1", $value[0], $conf) . '-';
    $conf->{attribute}{size} = 4; $conf->{attribute}{maxlength} = 4;
    $ret .= $self->_tag_text("${name}_2", $value[1], $conf);
}

sub _tag_phone_number {
    my $self = shift;
    my ($name, $value, $conf) = @_;
    my @value = split /-/, $value;
    $conf->{attribute}{size} = 5; $conf->{attribute}{maxlength} = 5;
    my $ret = $self->_tag_text("${name}_1", $value[0], $conf) . '-';
    $ret .= $self->_tag_text("${name}_2", $value[1], $conf) . '-';
    $ret .= $self->_tag_text("${name}_3", $value[2], $conf);
}

sub _label_gender {
    my $self = shift;
    my ($name, $value, $conf) = @_;
    $self->_label_select_with_options($name, $value, $conf, $options{gender});
}

sub _label_prefecture {
    my $self = shift;
    my ($name, $value, $conf) = @_;
    $self->_label_select_with_options($name, $value, $conf, $options{prefecture});
}

sub _label_job {
    my $self = shift;
    my ($name, $value, $conf) = @_;
    $self->_label_select_with_options($name, $value, $conf, $options{job});
}

sub _label_hobby {
    my $self = shift;
    my ($name, $value, $conf) = @_;
    $self->_label_checkbox_with_options($name, $value, $conf, $options{hobby});
}

=head1 FUNCTIONS

=cut

# ----[ static ]------------------------------------------------------
# ----[ private static ]----------------------------------------------

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
