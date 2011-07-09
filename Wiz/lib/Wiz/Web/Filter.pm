package Wiz::Web::Filter;

use strict;
use warnings;

no warnings 'uninitialized';

use Encode;
use Unicode::Japanese qw(unijp);
use HTML::Scrubber;

use Wiz::Util::String;
use Wiz::Web::Util::AutoLink;

=head1 NAME

Wiz::Web::Filter

=head1 VERSION

version 1.0

=cut

our $VERSION = '1.0';

=head1 SYNOPSIS

=cut

=head1 EXPORTS

    line_break
    mask_password
    z2h
    h2z
    csn
    comma_separated_numeric
    auto_link
    datetime
    pw
    stromit
    stromitj
    substrj
    trim_tag_html
    scrub
    scrub_contents 

=cut

use Wiz::DateTime;

use Wiz::ConstantExporter [qw(
    line_break
    mask_password
    z2h
    h2z
    csn
    comma_separated_numeric
    auto_link
    datetime
    pw
    stromit
    stromitj
    substrj
    trim_tag_html
    scrub
    scrub_contents 
)];

sub line_break {
    my ($target) = @_;
    my $ret = ref $target ? $target : \$target;
    $$ret =~ s#\r?\n#<br \/>#g;
    return $$ret;
}

sub mask_password {
    my ($target, $mask) = @_;
    my $ret = ref $target ? $target : \$target;
    $$ret = $mask x length $$target;
    return $$ret;
}

*z2h = 'Wiz::Util::String::z2h';
*h2z = 'Wiz::Util::String::h2z';
*csn = 'Wiz::Util::String::comma_separated_numeric';
*comma_separated_numeric = 'Wiz::Util::String::comma_separated_numeric';
*stromit = 'Wiz::Util::String::stromit';
*stromitj = 'Wiz::Util::String::stromitj';
*substrj = 'Wiz::Util::String::substrj';
*trim_tag_html = 'Wiz::Util::String::trim_tag_html';

sub auto_link {
    my ($target, $opts) = @_;
    my $ret = ref $target ? $target : \$target;
    $$ret = Wiz::Web::Util::AutoLink::auto_link($$ret, $opts);
    return $$ret;
}

sub datetime {
    my ($target, $opts) = @_;
    my $ret = ref $target ? $target : \$target;
    if ($$ret ne '') {
        my $date = new Wiz::DateTime($$ret);
        if ($opts) {
            if ($opts->{format}) {
                $date->set_format($opts->{format});
            }
        }
        $$ret = $date->to_string;
    }
    return $$ret;
}

sub pw {
    my ($target, $opts) = @_;
    my $ret = ref $target ? $target : \$target;
    my $str = (ref $opts and defined $opts->{str}) ? $opts->{str} : '*';
    $$ret = $str x (length $$ret);
    return $$ret;
}

sub scrub {
    my ($target, $rule, $default) = @_;
    my $scrub = new HTML::Scrubber;
    $rule->{allow} and $scrub->allow(@{$rule->{allow}});
    $scrub->allow(keys %$rule);
    $rule and $scrub->rules(%$rule);
    $default and $scrub->default(@$default);
    $scrub->scrub($target);
}

sub scrub_contents {
    return scrub(shift, {
        allow   => [qw(
            h1
            h2
            h3
            h4
            h5
            h6
            b
            i
            u
            pre
            hr
            br
            strong
            sup
            sub
            ul
            li
            ol
            address
            width
            height
            tbody
            tr
            td
        )],
        a       => {
            href    => qr{^(?!(?:java)?script)}i,
            target  => 1,
        },
        p       => {
            style   => 1,
        },
        span    => {
            style   => 1,
        },
        img     => {
            title   => 1,
            src     => 1,
            border  => 1,
        },
        table   => {
            border  => 1,
            cellspacing => 1,
            cellpadding => 1,
        },
        object  => {
            width   => 1,
            height  => 1,
        },
        param   => {
            name    => 1,
            value   => 1,
        },
        embed   => {
            src                 => 1,
            type                => 1,
            width               => 1,
            height              => 1,
            allowscriptaccess   => 1,
            allowfullscreen     => 1,
        },
    },
    [
        0   => {
            '*'           => 1,
            'href'        => qr{^(?!(?:java)?script)}i,
            'src'         => qr{^(?!(?:java)?script)}i,
            'cite'        => '(?i-xsm:^(?!(?:java)?script))',
            'language'    => 0,
            'name'        => 1,
            'onblur'      => 0,
            'onchange'    => 0,
            'onclick'     => 0,
            'ondblclick'  => 0,
            'onerror'     => 0,
            'onfocus'     => 0,
            'onkeydown'   => 0,
            'onkeypress'  => 0,
            'onkeyup'     => 0,
            'onload'      => 0,
            'onmousedown' => 0,
            'onmousemove' => 0,
            'onmouseout'  => 0,
            'onmouseover' => 0,
            'onmouseup'   => 0,
            'onreset'     => 0,
            'onselect'    => 0,
            'onsubmit'    => 0,
            'onunload'    => 0,
            'src'         => 0,
            'type'        => 0,
        },
    ]);
}

=head1 FUNCTIONS

=cut

=head1 AUTHOR

Junichiro NAKAMURA, C<< <jyun16@gmail.com> >>

[Modify]
Toshihiro MORIMOTO C<< dealforest.net@gmail.com >>

=head1 COPYRIGHT & LICENSE

Copyright 2008,2009 The Wiz Project. All rights reserved.

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

