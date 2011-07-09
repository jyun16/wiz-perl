package Wiz::Util::Validation;

use strict;
use warnings;

no warnings 'uninitialized';

=head1 NAME

Wiz::Util::Validation

=head1 VERSION

version 1.0

=cut

our $VERSION = '1.0';

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 EXPORTS

 is_null
 is_empty
 is_number
 is_integer
 is_real
 is_alphabet
 is_alphabet_uc
 is_alphabet_lc
 is_alphabet_number
 is_ascii
 is_email_address
 is_url
 is_httpurl
 is_rfc822_dot_atom_text
 is_valid_local
 is_valid_domain
 is_credit_card_number
 is_name
 is_valid_date
 is_invalid_date
 not_null
 not_empty
 not_number
 not_alphabet
 not_alphabet_uc
 not_alphabet_lc
 not_alphabet_number
 not_ascii
 not_email_address
 not_url
 not_httpurl
 not_integer
 not_rfc822_dot_atom_text
 not_valid_local
 not_valid_domain
 not_credit_card_number
 not_name

=cut

use Wiz::Constant qw(:common);
use Wiz::DateTime;

=head1 FUNCTIONS

=head2 $bool = is_null($data)

Returns TRUE if $data is not defined.

=cut

sub is_null { (not defined shift) || FALSE; }

=head2 $bool = is_empty($data)

Returns TRUE if $data is empty string.

=cut

sub is_empty { shift eq '' || FALSE; }

=head2 $bool = is_zero($data)

Returns TRUE if $data is 0.

=cut

sub is_zero { shift == 0 || FALSE; }

=head2 $bool = is_number($data)

Returns TRUE if $data is number(0-9).

=cut

sub is_number { shift =~ /^[\d,]*$/ || FALSE; }

=head2 $bool = is_integer($data)

Returns TRUE if $data is integer(0, 3, -4, etc).

=cut

sub is_integer { shift =~ /^-?[\d,]*$/ || FALSE; }

=head2 $bool = is_negative_integer($data)

Returns TRUE if $data is negative integer(-1, -4, etc).

=cut

sub is_negative_integer { shift =~ /^-[\d,]*$/ || FALSE; }

=head2 $bool = is_real($data)

Returns TRUE if $data is real number(0, 0.3, -4.0, etc).

=cut

sub is_real { shift =~ /^-?[\d\.,]*$/ || FALSE; }

=head2 $bool = is_alphabet($data)

Returns TRUE if $data is alphabet(a-z and A-Z).

=cut

sub is_alphabet { shift =~ /^[a-zA-Z]*$/ || FALSE; }

=head2 $bool = is_alphabet_uc($data)

Returns TRUE if $data is alphabet with upper case(A-Z).

=cut

sub is_alphabet_uc { shift =~ /^[A-Z]*$/ || FALSE; }

=head2 $bool = is_alphabet_lc($data)

Returns TRUE if $data is alphabet with lower case(a-z).

=cut

sub is_alphabet_lc { shift =~ /^[a-z]*$/ || FALSE; }

=head2 $bool = is_alphabet_number($data)

Returns TRUE if $data is alphabet and number(a-zA-Z0-9).

=cut

sub is_alphabet_number { shift =~ /^\w*$/ || FALSE; }

=head2 $bool = is_ascii($data)

Returns TRUE if $data is printable character.

=cut

sub is_ascii { shift =~ /^[\x00-\x7E]*$/ || FALSE; }

=head2 $bool = is_email_address($data)

Returns TRUE if $data is 0.

=cut

sub is_email_address {
    shift =~ /(.*)@(.*)/;
    is_valid_local($1) or return FALSE;
    is_valid_domain($2) or return FALSE;
    return TRUE;
}

=head2 $bool = is_url($data)

Returns TRUE if $data is url.

=cut

sub is_url {
    shift =~ /^[a-z]*:\/\/[-_.!~*'()a-zA-Z0-9;\/?:\@&=+\$,%#]+$/ || FALSE;
}

=head2 $bool = is_httpurl($data)

Returns TRUE if $data is url of HTTP.

=cut

sub is_httpurl {
    shift =~ /^s?https?:\/\/[-_.!~*'()a-zA-Z0-9;\/?:\@&=+\$,%#]+$/ || FALSE;
}

=head2 $bool = is_rfc822_dot_atom_text($data)

Returns TRUE if $data is atom and dot(see the RFC 822).

=cut

sub is_rfc822_dot_atom_text {
    my $data = shift;

    my $len = length $data;
    for (my $i = 0; $i < $len; $i++) {
        my $c = substr $data, $i, 1;
        if (is_alphabet_number($c)) { next; }
        elsif ($c =~ m/[!#$%&'*+-\/=?^_`{|}~.]/) { next; }
        else { return FALSE; }
    }
    return TRUE;
}

=head2 $bool = is_valid_local($data)

Returns TRUE if $data is local-part.

=cut

sub is_valid_local {
    my $data = shift;

    $data or return FALSE;
    length $data > 64 and return FALSE;
    return is_rfc822_dot_atom_text($data);
}

=head2 $bool = is_domain($data)

Returns TRUE if $data is domain.

=cut

sub is_valid_domain {
    my $data = shift;

    $data or return FALSE;
    length $data > 255 and return FALSE;
    my $dots = 0;
    my $len = length $data;
    for (my $i = 0; $i < $len; $i++) {
        my $c = substr $data, $i, 1;
        if ($i == 0 and $c eq '.') { return FALSE; }
        elsif (is_alphabet_number($c)) { next; }
        elsif ($c eq '-' or $c eq '_') { next; }
        elsif ($c eq '.') {
            if ($i == $len - 1) { return FALSE; }
            my $nc = substr $data, ($i + 1), 1;
            if ($nc eq '.') { return FALSE; }
            $dots++;
            next;
        }
    }
    $dots < 1 and return FALSE;
    return 1;
}

sub is_credit_card_number {
    shift =~ /\d{4}-\d{4}-\d{4}-\d{4}/ || 0;
}

sub is_name {
    my ($name) = @_;
    $name =~ s/ |　//;
    is_alphabet($name);
}

sub is_valid_date {
    new Wiz::DateTime(shift) ? TRUE : FALSE;
}

sub is_invalid_date {
    new Wiz::DateTime(shift) ? FALSE : TRUE;
}

BEGIN {
    no strict 'refs';

    for my $m (keys %Wiz::Util::Validation::) {
        $m =~ /^is_(.*)/ or next;
        *{ "Wiz::Util::Validation::not_" . $1 } =
            sub { $m->(@_) ? FALSE : TRUE; }
    }
}

BEGIN {
    use Wiz::ConstantExporter [ grep { /^(is|not)_/ } keys %Wiz::Util::Validation::];
}

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
