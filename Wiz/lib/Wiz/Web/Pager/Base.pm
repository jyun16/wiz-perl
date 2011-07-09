package Wiz::Web::Pager::Base;

use strict;
use warnings;

no warnings 'uninitialized';

=head1 NAME

Wiz::Web::Pager::Base

=head1 VERSION

version 1.0

=cut

our $VERSION = '1.0';

=head1 SYNOPSIS

 my $pager = new Wiz::Web::Pager::Basic(
     now_page    => 1,
     total_number  => 30,
 );
 
 # 1
 # &nbsp;<a href="JavaScript:jumpPage(2);">2</a>
 # &nbsp;<a href="JavaScript:jumpPage(3);">3</a>
 # &nbsp;<a href="JavaScript:jumpPage(2);">&gt;next&nbsp;</a>
 $pager->tag;

=head2 IN TEMPLATE (ex. TT)

 <head>
 <script language="JavaScript">
     [% pager.js %]
 </script>
 </head>
 <body>
 
     [% pager.append_per_page_select_attribute(" class='box'") %]
     per_page: [% pager.per_page_select_tag %]
     page:[% pager.now_page %],
     total_page:[% pager.total_pages %]
     total:[% pager.total_number %],
     first:[% pager.first %],
     last:[% pager.last %]
     [% pager.tag %]
 
 <form>
     [% pager.hidden %]
 </form>
 </body>

=head1 DESCRIPTION

=cut

use base qw(Class::Accessor::Fast Wiz::Web::Base);

use POSIX;
use URI;
use Clone qw(clone);

use Wiz qw(get_hash_args);
use Wiz::Util::Hash qw(args2hash);

my %default = (
    dest_url                            => '',
    now_page_param_name                 => 'np',
    form_name                           => 'form',
    method                              => 'post',
    per_page                            => 10,
    per_page_picks                      => [10,20,50,100],
    per_page_param_name                 => 'pp',
    per_page_select_attribute           => '',
    per_page_select_js_function_name    => 'perPage',
    js_function_name                    => 'jumpPage',
    added_js                            => [],
    now_page                            => 1,
    param                               => {},
    total_number                        => 0,
    next_label                          => 'next',
    prev_label                          => 'prev',
    ln                                  => "\n",
);

=head1 ACCESSORS

 total_pages

=cut

__PACKAGE__->mk_accessors(keys %default, qw(total_pages param));

=head1 CONSTRUCTOR

=head2 new(\%args, %args)

=head2 ARGS

 dest_url                            => '',
 now_page_param_name                 => 'np',
 form_name                           => 'form',
 method                              => 'post',
 per_page                            => 10,
 per_page_picks                      => [10,20,50,100],
 per_page_param_name                 => 'pp',
 per_page_select_attribute           => '',
 per_page_select_js_function_name    => 'perPage',
 js_function_name                    => 'jumpPage',
 added_js                            => [],
 now_page                            => 1,
 total_number                        => 0,
 next_label                          => 'next',
 prev_label                          => 'prev',
 ln                                  => "\n",

=cut

sub new {
    my $self = shift;
    my $args = get_hash_args(@_);
    my $instance = bless((clone \%default), $self);
    for (keys %default) { defined $args->{$_} and $instance->{$_} = $args->{$_}; }
    $instance->{total_number} and $instance->calc_total_pages;
    return $instance;
}

=head1 METHODS

=head2 $per_page = per_page($per_page)

Accessor to number of list per a page.

=cut

sub per_page {
    my $self = shift;
    my ($per_page) = @_;

    if (defined $per_page and $per_page ne '') {
        $self->{per_page} = $per_page;
        $self->calc_total_pages;
    }
    return $self->{per_page};
}

=head2 $now_page = now_page($now_page)

Accessor to current page number.

=cut

sub now_page {
    my $self = shift;
    my ($now_page) = @_;

    if (defined $now_page and $now_page ne '') {
        $self->{now_page} = $now_page;
        $self->calc_total_pages;
    }
    return $self->{now_page};
}

=head2 $total_number = now_page($now_page)

Accessor to number of total data.

=cut

sub total_number {
    my $self = shift;
    my ($total_number) = @_;

    if (defined $total_number) {
        $self->{total_number} = $total_number;
        $self->calc_total_pages;
    }
    return $self->{total_number};
}

=head2 $first = first

Getter of first element number.

=cut

sub first {
    my $self = shift;
    return $self->{total_number} > 0 ? $self->offset + 1 : 0;
}

=head2 $last = last

Gets last element number.

=cut

sub last {
    my $self = shift;
    my $last = $self->offset + $self->limit;
    $last > $self->{total_number} and $last = $self->{total_number};
    return $last;
}

=head2 offset($now_page)

Gets offset at the current page in total data.

=cut

sub offset {
    my $self = shift;
    my ($offset) = @_;

    if (defined $offset and $offset ne '') {
        $self->{now_page} = int ($offset / $self->{per_page}) + 1;
    }

    return $self->{now_page} < 2 ?
        0 : ($self->{now_page} - 1) * $self->{per_page};
}

=head2 limit($limit)

Gets limit per a page.

=cut

sub limit {
    my $self = shift;
    $self->per_page(@_);
}

=head2 calc_total_pages

Calc total pages.

=cut

sub calc_total_pages {
    my $self = shift;
    $self->{total_pages} = $self->{total_number} > $self->{per_page} ?
        ceil($self->{total_number} / $self->{per_page}): 0;
}

=head2 js

Gets javascript function for operated myself.

=cut

sub js {
    my $self = shift;
    my ($args) = args2hash @_;

    my $form_name = $args->{form_name} || $self->{form_name};
    my $now_page_param_name = $args->{now_page_param_name} || $self->{now_page_param_name};
    my $per_page_select_js_function_name = $args->{per_page_select_js_function_name } ||
        $self->{per_page_select_js_function_name };

    my $func = <<EOS;
function $self->{js_function_name}(__npv) {
    document.$form_name.$now_page_param_name.value=__npv;
EOS

    $func .= $self->SUPER::js;

    $func .= <<EOS;
    document.$form_name.submit();
}

function $per_page_select_js_function_name() {
    document.$form_name.submit();
}
EOS

    return $func;
}

=head2 hidden

Gets HTML hidden tag for operated myself.

=cut

sub hidden {
    my $self = shift;
    return qq|<input type="hidden" name="$self->{now_page_param_name}">|;
}

=head2 per_page_select_tag

Gets HTML tag to change number of per page.

=cut

sub per_page_select_tag {
    my $self = shift;
    my ($selected) = @_;

    $selected ||= $self->{per_page};

    my $tag = qq|<select name="$self->{per_page_param_name}"|;
    $self->{per_page_select_attribute} and $tag .= " $self->{per_page_select_attribute}";
    $tag .= qq| onChange="$self->{per_page_select_js_function_name}()">\n|;

    for (@{$self->{per_page_picks}}) {
        $tag .= qq|\t<option value="$_"|;
        if ($selected == $_) { $tag .= ' selected'; }
        $tag .= ">$_\n";
    }

    $tag .= "</select>\n";
    return $tag;
}

=head2 append_per_page_select_attribute($attribute)

Appends to HTML tag can get by per_page_select_tag $attribute

=cut

sub append_per_page_select_attribute {
    my $self = shift;
    my ($attr) = @_;
    $self->{per_page_select_attribute} .= $attr;
    return;
}

sub query_param {
    my $self = shift;
    my $uri = new URI;
    $uri->query_form($self->{param});
    return $uri->query;
}

# ----[ private ]-----------------------------------------------------
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

