package Wiz::Web::Framework::Controller::Captcha;

=head1 NAME

Wiz::Web::Framework::Controller::Captcha

=head1 VERSION

version 1.0

=cut

our $VERSION = '1.0';

=head1 SYNOPSIS

Create captcha image.

If you want to provite page to create captcha image at http://domain/captcha_image, do the following.

* Write controller

 package MondMember::Controller::Root;
 
 use strict;
 use warnings;
 
 use base qw(
     Catalyst::Controller::Wiz::Root
     Catalyst::Controller::Wiz::Captcha
 );
 
 our $USE_TOKEN = 1;
 our $SESSION_NAME = __PACKAGE__;

 # session key captcha random string to store in session
 our $CAPTCHA_SESSION_KEY = 'captcha_rnd_str';
 
 sub index {
     my $self = shift;
     my ($c) = @_;
 }

Create conf/test/captcha.pdat

See L<GD::SecurityImage>.

 {
     font            => [qw(
         /home/work/perl/catalyst/wizapp/MondMember/font/Altea.ttf
         /home/work/perl/catalyst/wizapp/MondMember/font/tiza.ttf
         /home/work/perl/catalyst/wizapp/MondMember/font/BabelfishContour.ttf
     )],
     fonttype        => 'ttf',
     bgcolor         => '#FFFFFF',
     font_color      => ['#2e8b57', '#5f9ea0', '#3cb371'],
     line_color      => ['#FF0000', '#00FF00', '#0000FF'],
 }

* Call captcha_image in a html.

Use jQuery L<<http://jquery.com/>>.

in the head

 <script type="text/javascript" src="/js/jquery.js"></script>
 <script type="text/javascript">
 
 function get_captcha_image() {
     $.get("/captcha_image", function(data) {
         $("#captcha_image").attr("src", data);
     });
 }
 
 $(function() {
     get_captcha_image();
     $("#get_captcha_image").click(function() {
         get_captcha_image();
     });
 });
 
 </script>

in the body

 <img src="" id="captcha_image"/>
 <input type="button" id="get_captcha_image" value="更新" class="button"/><br/>

* Check captcha key in a controller.

 use base 'Catalyst::Controller::Wiz::Regist';

 use Catalyst::Controller::Wiz::Captcha;

 our @AUTOFORM = qw(member invite);

 sub _before_execute_index {
     my $self = shift;
     my ($c, $af) = @_;
 
     my $session_captcha_key = $c->app_conf('captcha')->{session_captcha_key};
     $session_captcha_key ||= ${Catalyst::Controller::Wiz::Captcha::default}{session_captcha_key};
     if ($af->value('captcha') ne $c->session->{$session_captcha_key}) {                                                     $af->outer_error(captcha => $c->validation_message('invalid_captcha_key'));
     }
 }
 
 sub _after_execute_index {
     my $self = shift;
     my ($c, $af) = @_;
     $af->has_error and $af->param(captcha => '');
 }

* The sample of autoform config

 captcha           => {
     type        => 'text',
     validation    => {
         not_empty =>1,
     },
 },

=cut

use File::Temp;
use GD::SecurityImage;

use Wiz::Noose;
use Wiz::Util::File qw(cleanup filename);
use Wiz::Util::Array qw(array_random);

extends qw(Wiz::Web::Framework::Controller);

our %default = (
    width               => 360,
    height              => 60,
    lines               => 5,
    scramble            => 1,
    angle               => 10,
    ptsize              => 20,
    ptrange             => 0,
    thickness           => 1,
    rndmax              => 6,
    rnd_data            => [ 0..9, 'A' .. 'Z' ],
    bgcolor             => '#FFFFFF',
    gd                  => 1,
    fonttype            => 'normal',
    style               => 'ec',
    font_color          => '#2E8B57',
    line_color          => '#2E8B57',
    create              => [ 'ttf', 'ec', '#2E8B57', '#2E8B57' ],
    particle            => [ 100, 10 ],
    out                 => { force => 'jpeg' },
    tmpdir              => 'root/tmp/captcha',
    suffix              => '.jpg',
    tmpdir_cleanup      => 10,
    session_captcha_key => 'captcha_rnd_str',
);

sub captcha_image {
    my $self = shift;
    my ($c) = @_;

    my $conf = _init_captcha_image_conf($c->app_conf('captcha'));
    my $gd = GD::SecurityImage->new(%{$conf->{new}});
    $gd->random;
    $gd->create(@{$conf->{create}});
    $gd->particle(@{$conf->{particle}});

    my ($data, $mime, $rnd_str) = $gd->out(%{$conf->{out}});
    my $f = new File::Temp(
        DIR     => $c->path_to($conf->{tmpdir}),
        SUFFIX  => $conf->{suffix},
        TMPDIR  => 1,
    );
    print $f $data;
    $f->unlink_on_destroy(0);
    cleanup($c->path_to($conf->{tmpdir}), $conf->{tmpdir_cleanup});

    my $session_label = $self->ourv('SESSION_LABEL') || 'default';
    my $session_captcha_key = $conf->{session_captcha_key} || $default{session_captcha_key};
    $c->session($session_label)->{$session_captcha_key} = $rnd_str;

    (my $tmpdir = $default{tmpdir}) =~ s/^(?:root)\/(.*)/$1/;
    $tmpdir =~ s/\/$//;
    $c->res->body($c->uri_for("$tmpdir/" . filename $f->filename));
    $self->end;
}

sub _init_captcha_image_conf {
    my ($base_conf) = @_;

    my %conf = ();
    for (qw(width height lines scramble angle ptsize ptrange thickness rndmax rnd_data bgcolor gd font)) {
        if (defined $base_conf->{$_}) {
            if (($_ eq 'bgcolor' or $_ eq 'font') and ref $base_conf->{$_} eq 'ARRAY') {
                $conf{new}{$_} = array_random($base_conf->{$_});
            }
            else { $conf{new}{$_} = $base_conf->{$_}; }
        }
        else { $conf{new}{$_} = $default{$_}; }
    }

    my @create = ();
    for (qw(fonttype style)) {
        push @create, (defined $base_conf->{$_} ? $base_conf->{$_} : $default{$_});
    }

    for (qw(font_color line_color)) {
        if (defined $base_conf->{$_}) {
            push @create, (ref $base_conf->{$_} eq 'ARRAY' ? array_random($base_conf->{$_}) : $base_conf->{$_});
        }
        else { push @create, $default{$_}; }
    }

    $conf{create} = \@create;
    for (qw(particle out tmpdir suffix tmpdir_cleanup)) {
        $conf{$_} = defined $base_conf->{$_} ? $base_conf->{$_} : $default{$_};
    }

    return \%conf;
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
