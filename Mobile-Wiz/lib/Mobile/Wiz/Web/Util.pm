package Mobile::Wiz::Web::Util;

use strict;

use Encode;
use Encode::JP::Mobile ':props';
use Encode::JP::Mobile::Character;
use HTTP::MobileAgent::Plugin::Charset;

use Wiz::ConstantExporter [qw(
    convert_emoji
)];

our %EMOJI_MAP;
{
    use utf8;
    %EMOJI_MAP = (
        '晴れ'                      => "\x{E63E}",
        '曇り'                      => "\x{E63F}",
        '雨'                        => "\x{E640}",
        '雪'                        => "\x{E641}",
        '雷'                        => "\x{E642}",
        '台風'                      => "\x{E643}",
        '霧'                        => "\x{E644}",
        '小雨'                      => "\x{E645}",
        '牡羊座'                    => "\x{E646}",
        '牡牛座'                    => "\x{E647}",
        '双子座'                    => "\x{E648}",
        '蟹座'                      => "\x{E649}",
        '獅子座'                    => "\x{E64A}",
        '乙女座'                    => "\x{E64B}",
        '天秤座'                    => "\x{E64C}",
        '蠍座'                      => "\x{E64D}",
        '射手座'                    => "\x{E64E}",
        '山羊座'                    => "\x{E64F}",
        '水瓶座'                    => "\x{E650}",
        '魚座'                      => "\x{E651}",
        'スポーツ'                  => "\x{E652}",
        '野球'                      => "\x{E653}",
        'ゴルフ'                    => "\x{E654}",
        'テニス'                    => "\x{E655}",
        'サッカー'                  => "\x{E656}",
        'スキー'                    => "\x{E657}",
        'バスケットボール'          => "\x{E658}",
        'モータースポーツ'          => "\x{E659}",
        'ポケットベル'              => "\x{E65A}",
        '電車'                      => "\x{E65B}",
        '地下鉄'                    => "\x{E65C}",
        '新幹線'                    => "\x{E65D}",
        'セダン'                    => "\x{E65E}",
        'ＲＶ'                      => "\x{E65F}",
        'バス'                      => "\x{E660}",
        '船'                        => "\x{E661}",
        '飛行機'                    => "\x{E662}",
        '家'                        => "\x{E663}",
        'ビル'                      => "\x{E664}",
        '郵便局'                    => "\x{E665}",
        '病院'                      => "\x{E666}",
        '銀行'                      => "\x{E667}",
        'ＡＴＭ'                    => "\x{E668}",
        'ホテル'                    => "\x{E669}",
        'コンビニ'                  => "\x{E66A}",
        'ガソリンスタンド'          => "\x{E66B}",
        '駐車場'                    => "\x{E66C}",
        '信号'                      => "\x{E66D}",
        'トイレ'                    => "\x{E66E}",
        'レストラン'                => "\x{E66F}",
        '喫茶店'                    => "\x{E670}",
        'バー'                      => "\x{E671}",
        'ビール'                    => "\x{E672}",
        'ファーストフード'          => "\x{E673}",
        'ブティック'                => "\x{E674}",
        '美容院'                    => "\x{E675}",
        'カラオケ'                  => "\x{E676}",
        '映画'                      => "\x{E677}",
        '右斜め上'                  => "\x{E678}",
        '遊園地'                    => "\x{E679}",
        '音楽'                      => "\x{E67A}",
        'アート'                    => "\x{E67B}",
        '演劇'                      => "\x{E67C}",
        'イベント'                  => "\x{E67D}",
        'チケット'                  => "\x{E67E}",
        '喫煙'                      => "\x{E67F}",
        '禁煙'                      => "\x{E680}",
        'カメラ'                    => "\x{E681}",
        'カバン'                    => "\x{E682}",
        '本'                        => "\x{E683}",
        'リボン'                    => "\x{E684}",
        'プレゼント'                => "\x{E685}",
        'バースデー'                => "\x{E686}",
        '電話'                      => "\x{E687}",
        '携帯電話'                  => "\x{E688}",
        'メモ'                      => "\x{E689}",
        'ＴＶ'                      => "\x{E68A}",
        'ゲーム'                    => "\x{E68B}",
        'ＣＤ'                      => "\x{E68C}",
        'ハート'                    => "\x{E68D}",
        'スペード'                  => "\x{E68E}",
        'ダイヤ'                    => "\x{E68F}",
        'クラブ'                    => "\x{E690}",
        '目'                        => "\x{E691}",
        '耳'                        => "\x{E692}",
        'グー'                      => "\x{E693}",
        'チョキ'                    => "\x{E694}",
        'パー'                      => "\x{E695}",
        '右斜め下'                  => "\x{E696}",
        '左斜め上'                  => "\x{E697}",
        '足'                        => "\x{E698}",
        'くつ'                      => "\x{E699}",
        '眼鏡'                      => "\x{E69A}",
        '車椅子'                    => "\x{E69B}",
        '新月'                      => "\x{E69C}",
        'やや欠け月'                => "\x{E69D}",
        '半月'                      => "\x{E69E}",
        '三日月'                    => "\x{E69F}",
        '満月'                      => "\x{E6A0}",
        '犬'                        => "\x{E6A1}",
        '猫'                        => "\x{E6A2}",
        'リゾート'                  => "\x{E6A3}",
        'クリスマス'                => "\x{E6A4}",
        '左斜め下'                  => "\x{E6A5}",
        'phone to'                  => "\x{E6CE}",
        'mail to'                   => "\x{E6CF}",
        'fax to'                    => "\x{E6D0}",
        'iモード'                   => "\x{E6D1}",
        'iモード（枠付き）'         => "\x{E6D2}",
        'メール'                    => "\x{E6D3}",
        'ドコモ提供'                => "\x{E6D4}",
        'ドコモポイント'            => "\x{E6D5}",
        '有料'                      => "\x{E6D6}",
        '無料'                      => "\x{E6D7}",
        'ID'                        => "\x{E6D8}",
        'パスワード'                => "\x{E6D9}",
        '次項有'                    => "\x{E6DA}",
        'クリア'                    => "\x{E6DB}",
        '調べる'                    => "\x{E6DC}",
        'ＮＥＷ'                    => "\x{E6DD}",
        '位置情報'                  => "\x{E6DE}",
        'フリーダイヤル'            => "\x{E6DF}",
        'シャープダイヤル'          => "\x{E6E0}",
        'モバＱ'                    => "\x{E6E1}",
        '1'                         => "\x{E6E2}",
        '2'                         => "\x{E6E3}",
        '3'                         => "\x{E6E4}",
        '4'                         => "\x{E6E5}",
        '5'                         => "\x{E6E6}",
        '6'                         => "\x{E6E7}",
        '7'                         => "\x{E6E8}",
        '8'                         => "\x{E6E9}",
        '9'                         => "\x{E6EA}",
        '0'                         => "\x{E6EB}",
        '決定'                      => "\x{E70B}",
        '黒ハート'                  => "\x{E6EC}",
        '揺れるハート'              => "\x{E6ED}",
        '失恋'                      => "\x{E6EE}",
        '複数ハート'                => "\x{E6EF}",
        '嬉しい顔'                  => "\x{E6F0}",
        '怒った顔'                  => "\x{E6F1}",
        '落胆した顔'                => "\x{E6F2}",
        '悲しい顔'                  => "\x{E6F3}",
        'ふらふら'                  => "\x{E6F4}",
        '上向き矢印'                => "\x{E6F5}",
        'るんるん'                  => "\x{E6F6}",
        '温泉'                      => "\x{E6F7}",
        'かわいい'                  => "\x{E6F8}",
        'キスマーク'                => "\x{E6F9}",
        '新しい'                    => "\x{E6FA}",
        'ひらめき'                  => "\x{E6FB}",
        '怒り'                      => "\x{E6FC}",
        'パンチ'                    => "\x{E6FD}",
        '爆弾'                      => "\x{E6FE}",
        'ムード'                    => "\x{E6FF}",
        '下向き矢印'                => "\x{E700}",
        '眠い(睡眠)'                => "\x{E701}",
        'exclamation'               => "\x{E702}",
        'exclamation&question'      => "\x{E703}",
        'exclamation×2'             => "\x{E704}",
        '衝撃'                      => "\x{E705}",
        '飛び散る汗'                => "\x{E706}",
        '汗'                        => "\x{E707}",
        '走り出すさま'              => "\x{E708}",
        '長音記号１'                => "\x{E709}",
        '長音記号２'                => "\x{E70A}",
        'カチンコ'                  => "\x{E6AC}",
        'ふくろ'                    => "\x{E6AD}",
        'ペン'                      => "\x{E6AE}",
        '人影'                      => "\x{E6B1}",
        'いす'                      => "\x{E6B2}",
        '夜'                        => "\x{E6B3}",
        'soon'                      => "\x{E6B7}",
        'on'                        => "\x{E6B8}",
        'end'                       => "\x{E6B9}",
        '時計'                      => "\x{E6BA}",
    );
}

sub convert_emoji {
    my ($is_non_mobile, $output_encoding, $arg) = @_;
    my $content = ref $arg ? $arg : \$arg;
    unless (utf8::is_utf8($$content)) {
        $$content = Encode::decode('utf-8', $$content);
    }
    $$content =~ s/{emoji:(.*?)}/$1 ? ($EMOJI_MAP{$1} || chr(hex("0x$1"))) : ''/ge;
    if ($is_non_mobile) {
        $$content =~ s{(\p{InMobileJPPictograms})}{
            my $char = Encode::JP::Mobile::Character->from_unicode(ord $1);
            sprintf '[%s]', $char->name;
        }ge;
        $$content = encode($output_encoding, $$content, Encode::JP::Mobile::FB_CHARACTER);
    }
    else {
        $$content = encode($output_encoding, $$content);
    }
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


