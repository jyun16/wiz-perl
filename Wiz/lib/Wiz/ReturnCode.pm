package Wiz::ReturnCode;

use strict;
use warnings;
use base qw/Exporter/;
use Carp ();

our @EXPORT_OK = qw/return_code return_code_is/;
our %EXPORT_TAGS = (
                   all => \@EXPORT_OK,
                  );
use overload
    '""' => \&_rcode,
    'eq' => \&_rcode,
    '==' => \&_rcode;

=head1 NAME

Wiz::ReturnCode - return code with message

=head1 VERSION

version 1.0

=cut

our $VERSION = '1.0';

=head1 SYNOPSIS

 use Wiz::ReturnCode qw/:all/;
 
 sub check {
     # .....
 
     return $test ? $test : return_code undef, "cannot connect database";
 }
 
 sub check2 {
     # .....
 
     return $test ? $test : return_code 200, "cannot connect database";
 }
 
 if (not my $f = check()) {
     die $f->message;
 }
 
 if (return_code_is $f = check2(), 200) {
     die $f->message;
 }

=head1 DESCRIPTION

This module can return code with message.

=head1 CONSTRUCTOR

=head2 $object = new($return_code, $message)

Normaly, no need to use this.
Just use C<return_code> instead.

=cut

sub new {
    my $class = shift;
    my($return_code, $message) = @_;
    return bless {
           return_code => $return_code,
           message     => $message,
          }, $class;
}

=head1 EXPORTED FUNCTIONS

=head2 $object = return_code($return_code, $message)

It create Wiz::ReturnCode object.

=cut

sub return_code {
    __PACKAGE__->new(@_);
}

sub message {
    my $self = shift;
    return $self->{message};
}

=head2 $bool = return_code_is($object, $code)

If given $object is Wiz::ReturnCode object and its code is as same as $code,
returns 1.

=cut

sub return_code_is {
    my ($obj, $code) = @_;

    my $class = ref $obj or return;
    $class eq __PACKAGE__ or return;
    my $rcode = $obj->_rcode;

    return 1 if not defined $obj->_rcode and not defined $code;
    return $obj->_rcode eq $code;
}

sub _rcode {
    my $self = shift;
    $self->{return_code};
}

=head1 TODO

=head1 SEE ALSO

=head1 AUTHOR

Kato Atsushi, C<< <kato@adways.net> >>

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
