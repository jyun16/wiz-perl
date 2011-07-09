package Wiz::Net::OpenSocial::API::Mbga;

use Wiz::Noose;

=head1 NAME

Wiz::Net::OpenSocial::API::Mbga

=head1 VERSION

version 1.0

=cut

our $VERSION = '1.0';

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut

use JSON::Syck;
use Wiz::Constant qw(:common);

with qw(Wiz::Net::OpenSocial::API);

has 'api_base_domain' => (is => 'rw', default => 'app.mbga.jp');
has 'sandbox' => (is => 'rw', default => FALSE);
has 'api_version' => (is => 'rw', default => 'v1');

my $API_BASE;

sub api_base {
    my $self = shift; 
    $API_BASE and return $API_BASE;
    my $domain = $self->api_base_domain;
    if ($self->sandbox) { $domain = "sb.$domain"; }
    $API_BASE = sprintf 'http://%s/api/restful/%s', $domain, $self->api_version;
}

=head

    $param

    size

        large   画像大
        medium  画像中(default)
        small   画像小

    view

        entire  全体(default)
        upper   上半身

    emotion

        defined ユーザーが現在設定している物(default)
        normal  表情 - 通常 
        smile   表情 - 笑う
        cry     表情 - 泣く
        angry   表情 - 怒る
        shy     表情 - 照れ

    dimension
    
        defined ユーザーが現在設定している物(default)
        2d      2Dアバター
        3d      3Dアバター

    transparent

        true    透過 ON
        false   透過 OFF(default)

    type

        image   画像形式で取得(default)
        flash   Flashで取得

    extension
    
        gif(default)
        png
        swf

    motion

        swf時に指定したモーションを適用

    scene

        swf時に指定したシーン設定で swf を生成

    appId

        swf時に現在のappId値または@appを指定(必須)

=cut

sub avatar {
    my $self = shift;
    my ($guid, $param) = @_;
    $self->request('GET',
        sprintf('%s/avatar/%s/@self%s', $self->api_base, $guid, parameter_sequence($param)),
    );
}

sub payment {
    my $self = shift;
    my ($guid, $app_id, $param) = @_;
    $self->request('POST',
        sprintf('%s/payment/%s/@self/%s', $self->api_base, $guid, $app_id, $param),
        $param,
        {
            headers => [ 'Content-Type' => 'application/json; charset=utf8' ],
            content => JSON::Syck::Dump($param),
        },
    );
}

sub get_payment {
    my $self = shift;
    my ($guid, $app_id, $payment_id) = @_;
    $self->request('GET',
        sprintf('%s/payment/%s/@self/%s/%s', $self->api_base, $guid, $app_id, $payment_id),
    );
}

sub clear_api_base {
    $API_BASE = undef;
}

sub parameter_sequence {
    my ($param) = @_;
    my @ret = map { "$_=$param->{$_}" } keys %$param;
    return '/' . join ';', @ret;
}

sub _return_result {
    my $self = shift;
    my ($content) = @_;
    my $data = JSON::Syck::Load $content;
    for (qw(person avatar payment)) {
        if ($data->{$_}) {
            my $entry = delete $data->{$_};
            return wantarray ? ($entry, $data) : $entry;
        }
    }
    my $entry = delete $data->{entry};
    $entry = ref $entry eq 'ARRAY' ? $entry : [ $entry ];
    return wantarray ? ($entry, $data) : $entry;
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
