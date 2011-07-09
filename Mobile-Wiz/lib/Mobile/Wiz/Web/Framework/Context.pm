package Mobile::Wiz::Web::Framework::Context;

use Any::Moose;

extends qw(
    Wiz::Web::Framework::Context
);

use Encode;
use HTTP::MobileAgent;
use HTTP::MobileUserID;
use Encode::JP::Mobile ':props';
use Encode::JP::Mobile::Character;
use HTTP::MobileAgent::Plugin::Charset;

use Mobile::Wiz::Web::Util;
use Mobile::Wiz::Web::Framework::CIDR;
use Wiz::Constant qw(:common);
use  Mobile::Wiz::Web::StickyQuery::DoCoMoGUID;

# I hate DoCoMo.
sub languages {
    my @stupid = ('ja-jp', 'ja');
    return wantarray ? @stupid : \@stupid;
}

sub mobile_agent {
    my $self = shift;
    $self->req->{mobile_agent} ||= new HTTP::MobileAgent;
    return $self->req->{mobile_agent};
}

sub is_ezweb {
    shift->mobile_agent->is_ezweb;
}

sub is_docomo {
    shift->mobile_agent->is_docomo;
}

sub is_softbank {
    shift->mobile_agent->is_softbank;
}

sub is_mobile {
    shift->mobile_agent->is_non_mobile ? FALSE : TRUE;
}

sub is_non_mobile {
    shift->mobile_agent->is_non_mobile;
}

sub carrier {
    shift->mobile_agent->carrier;
}

sub carrier_longname {
    shift->mobile_agent->carrier_longname;
}

sub mobile_uid {
    new HTTP::MobileUserID(shift->mobile_agent)->id;
}

sub mobile_guid {
    my $self = shift;
    $self->req->header('x-dcmguid');
}

sub mobile_encoding {
    my $self = shift;
    if ($self->is_docomo) {
        if ($self->app_conf('mobile')->{is_mbga}) {
            return 'x-sjis-imode';
        }
        else {
            return $self->mobile_agent->encoding;
        }
    }
    elsif ($self->is_mobile) { return $self->mobile_agent->encoding; }
    else { 'UTF-8'; }
}

sub mobile_charset {
    my $self = shift;
    if ($self->is_softbank) { return 'UTF-8'; }
    elsif ($self->is_ezweb) { return 'Shift-JIS'; }
    elsif ($self->is_docomo) {
        if ($self->app_conf('mobile')->{is_mbga}) {
            return 'Shift-JIS';
        }
        else {
            return $self->mobile_encoding =~ /sjis/ ? 'Shift-JIS' : 'UTF-8';
        }
    }
    else { 'UTF-8'; }
}

sub mobile_display {
    my $self = shift;
    $self->is_non_mobile and return;
    $self->mobile_agent->display;
}

sub mobile_display_size {
    my $self = shift;
    $self->is_non_mobile and return;
    $self->mobile_display->size;
}

sub mobile_display_color {
    my $self = shift;
    $self->is_non_mobile and return;
    $self->mobile_display->color;
}

sub mobile_display_depth {
    my $self = shift;
    $self->is_non_mobile and return;
    $self->mobile_display->depth;
}

sub convert_emoji {
    my $self = shift;
    Mobile::Wiz::Web::Util::convert_emoji($self->is_non_mobile, $self->mobile_encoding, @_);
}

sub init_cidr {
    my $self = shift;
    $self->{cidr} and return;
    my $conf = $self->app_conf('cidr');
    $self->{cidr} = new Mobile::Wiz::Web::Framework::CIDR(%$conf);
}

sub carrier_with_cidr {
    my $self = shift;
    $self->init_cidr;
    $self->{cidr}->carrier(@_);
}

sub carrier_longname_with_cidr {
    my $self = shift;
    $self->init_cidr;
    $self->{cidr}->carrier_longname(@_);
}

sub is_mobile_with_cidr {
    my $self = shift;
    $self->init_cidr;
    $self->{cidr}->is_mobile(@_);
}

sub is_non_mobile_with_cidr {
    my $self = shift;
    $self->init_cidr;
    $self->{cidr}->is_non_mobile(@_);
}

sub append_guid_on {
    my $self = shift;
    my ($arg) = @_;
    my $output = ref $arg ? $arg : \$arg;
    my $guid =  Mobile::Wiz::Web::StickyQuery::DoCoMoGUID->new(base => $self->req->base);
    $$output = $guid->sticky(%{$self->_create_param4guid_on($output)});
}

sub _create_param4guid_on {
    my $self = shift;
    my ($output) = @_;
    { scalarref => $output };
}

sub redirect {
    my $self = shift;
    my ($uri, $param) = @_;
    my $conf = $self->app_conf('mobile');
    if ($conf->{auto_append_guid_on} and $self->is_docomo) { 
        $param->{__guid_off} or $param->{guid} = 'ON';
    }
    ref $param eq 'HASH' and delete $param->{__guid_off};
    $self->SUPER::redirect($uri, $param);
}

=head1 AUTHOR

Junichiro NAKAMURA, C<< <jyun16@gmail.com> >>

[Modify] Toshihiro MORIMOTO C<< dealforest.net@gmail.com >>

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


