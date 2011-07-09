package Wiz::Web::Sort;

use strict;
use warnings;

no warnings 'uninitialized';

=head1 NAME

Wiz::Web::Sort

=head1 VERSION

version 1.0

=cut

our $VERSION = '1.0';

=head1 SYNOPSIS
 
 my $sort = new Wiz::Web::Sort;
 $sort->param(
     form    => 'PARAMETER',
 );
 
 my $data = new Wiz::DB::DataIO($conn, 'FOO');
 $data->select(-order => $sort->order);

=head2 IN TEMPLATE (ex. TT)

 <head>
 <script language="JavaScript">
 [% sort.js %]
 </script>
 </head>
 
 <body>
 <form>
 [% sort.a('id', 'label') %]
 [% sort.hidden %]
 </form>
 </body>

=head1 DESCRIPTION

=cut

use base qw(Wiz::Web::Base);

use Wiz qw(get_hash_args);
use Wiz::Util::Array qw(args2array);
use Wiz::Util::Hash qw(args2hash);

=head1 ACCESSORS

 dest_url
 sort_param_name
 form_name
 method
 js_function_name
 added_js
 order

=cut

__PACKAGE__->_set_default(
    dest_url                    => '',
    sort_param_name             => 'sort',
    form_name                   => 'form',
    method                      => 'post',
    js_function_name            => 'sortField',
    added_js                    => [],
    order                       => [],
    ignore_validation           => 0,
);

=head1 CONSTRUCTOR

=head2 new(\%args or %args)

=head2 ARGS

 dest_url                    => '',
 sort_param_name             => 'sort',
 form_name                   => 'form',
 method                      => 'post',
 js_function_name            => 'sortField',
 added_js                    => [],
 order                       => [],

=cut

=head1 METHODS

=head2 a(@args or \@args or $args)

Gets HTML anchor tag for sort.

@args: ($name, $label)
$args: ($name)

$field_name: db and form field name.
$label: <a href="blah">here!</a>

=cut

sub a {
    my $self = shift;
    my ($args) = @_;

    my ($name, $label);
    if (@_ > 1) { ($name, $label) = ($_[0], $_[1]); }
    elsif (ref $_[0]) { ($name, $label) = ($_[0][0], $_[0][1]); }
    else { ($name, $label) = ($_[0], $_[0]); }
    defined $name or return '';
    defined $label or $label = $name;
    return qq|<a href="JavaScript:$self->{js_function_name}('$name')">$label</a>|;
}

sub param {
    my $self = shift;
    my ($param) = @_;

    if (defined $param) {
        my @order = ();
        for (split /,/, $param) {
            (my $o = $_) =~ s/-d$/ DESC/i;
            push @order, $o;
        }
        $self->{order} = \@order;
    }
    elsif (@{$self->{order}}) {
        my @param = ();
        for (@{$self->{order}}) {
            (my $o = $_) =~ s/ DESC$/-d/i;
            push @param, $o;
        }
        $param = join ',', @param;
    }
    defined $param or $param = '';
    return $param;
}

=head2 order

Gets order data for Wiz::DB::SQL::Where.

=cut

sub order {
    my $self = shift;
    my $order = args2array(@_);
    if (defined $order and @$order) {
        $self->{order} = $order;
    }
    return $self->{order};
}

=head2 js

Get javascript function for myself operating.

=cut

sub js {
    my $self = shift;
    my ($args) = args2hash @_;
    my $form_name = $args->{form_name} || $self->{form_name};
    my $sort_param_name = $args->{sort_param_name} || $self->{sort_param_name};
    my $ignore_validation = $args->{ignore_validation} || $self->{ignore_validation};
    my $func = <<EOS;
function $self->{js_function_name}(target) {
    var vals = document.$form_name.$sort_param_name.value.split(",");
    var nvals = new Array();
    var desc = true;
    for (i = 0; i < vals.length; i++) {
        if (vals[i] == "") { continue; }
        var sa = vals[i].split("-");
        if (target != sa[0]) {
                nvals.push(vals[i]);
        }
        else {
            if (sa[1] == "d") {
                desc = false;
            }
        }
    }
    if (desc) {
        nvals.unshift(target + "-d");
    }
    else {
        nvals.unshift(target);
    }
    document.$form_name.$sort_param_name.value = nvals.join(",");
EOS
    $func .= $self->SUPER::js;
    if ($ignore_validation) {
        $func .= "    document.$form_name.ignore_validation.value = 1;\n";
    }
    $func .= <<EOS;
    document.$form_name.submit();
}
EOS
    return $func;
}

=head2 hidden

Gets HTML tag for myself operating.

=cut

sub hidden {
    my $self = shift;
    my ($attr) = args2hash @_;
    my $a = '';
    for (keys %$attr) { $a .= qq| $_="$attr->{$_}"|; }
    return qq|<input type="hidden" name="$self->{sort_param_name}" value="| . $self->param . qq|"$a>|;
}

sub hidden_ignore_validation {
    my $self = shift;
    $self->{ignore_validation} ?
        q|<input type='hidden' name='ignore_validation' value=''>| : '';
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

