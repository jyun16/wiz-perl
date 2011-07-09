package Wiz::Web::Pager::Google;

use strict;
use warnings;

no warnings 'uninitialized';

=head1 NAME

Wiz::Web::Pager::Google

=head1 VERSION

version 1.0

=cut

our $VERSION = '1.0';

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut

use base qw(Wiz::Web::Pager::Base);

=head1 CONSTRUCTOR

=cut

sub tag {
    my $self = shift;

    my ($now_page, $total_number, $add_param) =
        ($self->{now_page}, $self->{total_number}, $self->query_param);
    $add_param and $add_param = '&' . $add_param;

    my ($first_page, $last_page) = $self->_calc_page($now_page, $total_number);
    my $next_label = $self->{next_label};
    my $prev_label = $self->{prev_label};
    my $ln = $self->{ln};
    my $tag = '';
    if ($now_page > 1) {
        my $prev_page = $now_page - 1;
        if ($self->{method} eq 'post') {
            $tag .= qq|<a href="JavaScript:$self->{js_function_name}($prev_page);">|;
            $tag .= qq|$prev_label&nbsp;&lt;</a>$ln|;
        }
        else {
            $tag .= qq|<a href="$self->{dest_url}?$self->{now_page_param_name}=$prev_page$add_param">|;
            $tag .= qq|$prev_label&nbsp;&lt;</a>$ln|;
        }
    }
    for my $i ($first_page..$last_page) {
        if (($now_page == 0 && $i == 1) || $now_page == $i) { $tag .= "$i$ln"; }
        else {
            if ($self->{method} eq 'post') {
                $tag .= qq|<a href="JavaScript:$self->{js_function_name}($i);">$i</a>$ln|;
            }
            else {
                $tag .= qq|<a href="$self->{dest_url}?$self->{now_page_param_name}=$i$add_param">$i</a>$ln|;
            }
        }
        $i < 10 and $tag .= "&nbsp;";
    }
    if ($now_page < $self->{total_pages}) {
        my $next_page = $now_page == 0 ? 2 : $now_page + 1;
        if ($self->{method} eq 'post') {
            $tag .= qq|<a href="JavaScript:$self->{js_function_name}($next_page);">&gt;$next_label&nbsp;</a>$ln|;
        }
        else {
            $tag .= qq|<a href="$self->{dest_url}?$self->{now_page_param_name}=$next_page$add_param">|;
            $tag .= qq|&gt;&nbsp;$next_label</a>$ln|;
        }
    }
    return $tag;
}

# ----[ private ]-----------------------------------------------------
sub _calc_page {
    my $self = shift;
    my ($now_page, $total_number) = @_;

    my ($first_page, $last_page) = (0, 0);
    if ($self->{total_pages} < 21) {
        $first_page = 1;
        $last_page = $self->{total_pages};
    }
    else {
        $first_page = $now_page < 11 ? 1 : $now_page - 10;
        $last_page = $now_page < 21 ? $now_page + 9 : $first_page + 20;
        $last_page > $self->{total_pages} and $last_page = $self->{total_pages};
    }

    return ($first_page, $last_page);
}

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

__END__

