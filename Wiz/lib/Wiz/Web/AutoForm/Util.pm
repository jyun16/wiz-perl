package Wiz::Web::AutoForm::Util;

use strict;
use warnings;

no warnings 'uninitialized';

=head1 NAME

Wiz::Web::AutoForm::Util

=head1 VERSION

version 1.0

=cut

our $VERSION = '1.0';

=head1 SYNOPSIS

=cut

=head1 EXPORTS

=cut

use Wiz::ConstantExporter [qw(
    create_select_tag
    create_select_tag_sort
    create_select_tag_reverse_sort 
)];

=head1 FUNCTIONS

=cut

sub _create_select_tag {
    my ($for_sub, $name, $options, $attribute) = @_;
    return sub {
        my ($selected) = @_;
        my $ret = qq|<select name='$name'|;
        if (defined $attribute) {
            for (sort keys %$attribute) {
                $ret .= qq| $_='$attribute->{$_}'|;
            }
        }
        $ret .= ">\n";
        $ret = $for_sub->($ret, $selected, $options, $attribute);
        $ret .= '</select>';
        return $ret;
    }
}

sub create_select_tag {
    my ($name, $options, $attribute) = @_;
    return _create_select_tag(sub {
            my ($ret, $selected, $options, $attribute) = @_;
            for (keys %$options) {
                $ret .= qq|\t<option value='$_'|;
                $_ eq $selected and $ret .= ' selected';
                $ret .= qq|>$options->{$_}\n|;
            }
            return $ret;
        }, $name, $options, $attribute);
}

sub create_select_tag_sort {
    my ($name, $options, $attribute) = @_;
    return _create_select_tag(sub {
            my ($ret, $selected, $options, $attribute) = @_;
            for (sort keys %$options) {
                $ret .= qq|\t<option value='$_'|;
                $_ eq $selected and $ret .= ' selected';
                $ret .= qq|>$options->{$_}\n|;
            }
            return $ret;
        }, $name, $options, $attribute);
}

sub create_select_tag_reverse_sort {
    my ($name, $options, $attribute) = @_;
    return _create_select_tag(sub {
            my ($ret, $selected, $options, $attribute) = @_;
            for (reverse sort keys %$options) {
                $ret .= qq|\t<option value='$_'|;
                $_ eq $selected and $ret .= ' selected';
                $ret .= qq|>$options->{$_}\n|;
            }
            return $ret;
        }, $name, $options, $attribute);
}

=head1 AUTHOR

Junichiro NAKAMURA, C<< <jyun16@gmail.com> >>

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

