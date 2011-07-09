package Wiz::Web::Base;

use strict;
use warnings;

=head1 NAME

Wiz::Web::Base

=head1 VERSION

version 1.0

=cut

our $VERSION = '1.0';

=head1 SYNOPSIS


=head1 DESCRIPTION

This is base pckage, don't use this module.
This module should be inherited by sub class.

=cut

use base qw(Wiz::Base);

use Carp;

use Wiz qw(get_hash_args);

__PACKAGE__->_set_default(
    dest_url         => undef,
    form_name        => 'form',
    method           => 'post',
    js_function_name => 'jumpPage',
    added_js         => [],
);

=head1 ACCESSORS


=cut

=head1 CONSTRUCTOR

=head2 new(\%args, %args)

=head2 ARGS

 dest_url                            => '',
 form_name                           => 'form',
 method                              => 'post',
 js_function_name                    => 'jumpPage',
 added_js                            => [],

=cut

=head1 METHODS

=head2 add_js_function($func)

Adds javascript function.

=cut

sub add_js_function {
    my $self = shift;
    my ($func) = @_;
    push @{$self->{js_functions}}, $func;
}

=head2 js

Gets javascript function for operated myself.
The scripts which are added by add_js_function.

In subclass call this method.

 sub js {
   my $self = shift;
 
   my $func = <<EOS;
 function $self->{js_function_name}(__npv) {
    document.$self->{form_name}.$self->{now_page_param_name}.value=__npv;
 EOS
 
   $func .=  $self->SUPER::js
 }

=cut

sub js {
    my $self = shift;
    my $func;
    for (@{$self->{added_js}}) { $func .= ("\t" x 2) . "$_\n"; }
    return $func;
}

=head2 hidden

Gets HTML hidden tag for operated myself.

=cut

sub hidden {
    my $self = shift;
    Carp::croak "should be inplemented by sub class";
}

=head2 tag

Returns tag.

=cut

sub tag {
    my $self = shift;
    Carp::croak "should be inplemented by sub class";
}

=head2 style

Returns stylesheet.

=cut

sub style {
    my $self = shift;
    Carp::croak "should be inplemented by sub class";
}

# ----[ private ]-----------------------------------------------------
# ----[ static ]------------------------------------------------------
# ----[ private static ]----------------------------------------------

=head1 AUTHOR

Junichiro NAKAMURA, C<< <jyun16@gmail.com> >>
Kato Atsushi C<< <kato@adways.net> >>

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

