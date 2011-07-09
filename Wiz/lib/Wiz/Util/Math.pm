package Wiz::Util::Math;

use strict;
use warnings;

=head1 NAME

Wiz::Util::Math

=head1 VERSION

version 1.0

=cut

our $VERSION = '1.0';

=head1 SYNOPSIS

=head1 DESCRIPTION

Each functions name's format is "src2dest".

The src and dest types are the following.

 bin: binary
 dec: decimal
 hex: hex
 str: string

=cut

use Config;
use Digest;
use Digest::MD5;
use Math::Random::MT::Auto;

=head1 EXPORTS

 hex2dec
 hex2bin
 hex2str
 dec2hex
 dec2bin
 dec2str
 bin2hex
 bin2dec
 bin2str
 str2hex
 str2dec
 str2decs
 str2bin
 create_token
 create_secure_token

=cut

use Wiz::ConstantExporter [qw(
    hex2dec
    hex2bin
    hex2str
    dec2hex
    dec2bin
    dec2str
    bin2hex
    bin2dec
    bin2str
    str2hex
    str2dec
    str2decs
    str2bin
    create_token
    create_secure_token
)];

=head1 FUNCTIONS

=head2 $hex = hex2dec($hex or \$hex)

=cut

sub hex2dec {
    my $data = shift;

    if (ref $data) { $$data = hex($$data); }
    else { return hex($data); }
}

=head2 $bin = hex2bin($hex or \$hex)

=cut

sub hex2bin {
    my $data = shift;

    if (ref $data) { $$data =~ s/(..)/unpack("B8", pack("H2", $1))/ge; }
    else { $data =~ s/(..)/unpack("B8", pack("H2", $1))/ge; return $data; }
}

=head2 $str = hex2str($hex or \$hex)

=cut

sub hex2str {
    my $data = shift;

    if (ref $data) { $$data =~ s/(..)/pack("H2", $1)/ge; }
    else { $data =~ s/(..)/pack("H2", $1)/ge; return $data; }
}

=head2 $hex = dec2hex($dec or \$dec)

=cut

sub dec2hex {
    my $data = shift;
    
    if (ref $data) { $$data = sprintf("%x", $$data); }
    else { return sprintf("%x", $data); }
}

=head2 $bin = dec2bin($dec or \$dec)

=cut

sub dec2bin {
    my $data = shift;

    if (ref $data) { $$data = unpack("B8", pack("C", $$data)); }
    else { return unpack("B8", pack("C", $data)); }
}

=head2 $str = dec2str($dec or \$dec or \@dec)

$dec is array reference that a element is decimal string.

=cut

sub dec2str {
    my $data = shift;

    my $r = ref $data;
    if ($r eq "ARRAY") { return pack("C*", @$data); }
    elsif ($r) { $$data = chr($$data); }
    else { return chr($data); }
}

=head2 $hex = bin2hex($bin or \$bin)

Returns array reference that a element is decimal string.

=cut

sub bin2hex {
    my $data = shift;

    if (ref $data) { $$data =~ s/(.{8})/unpack("H2", pack("B8", $1))/ge; }
    else { $data =~ s/(.{8})/unpack("H2", pack("B8", $1))/ge; return $data; }
}

=head2 $dec = bin2dec($bin or \$bin)

=cut

sub bin2dec {
    my $data = shift;

    if (ref $data) { $$data =~ s/(.{8})/unpack("C", pack("B8", $1))/ge; }
    else { $data =~ s/(.{8})/unpack("C", pack("B8", $1))/ge; return $data; }
}

=head2 $str = bin2str($bin or \$bin)

=cut

sub bin2str {
    my $data = shift;

    if (ref $data) { $$data =~ s/(.{8})/pack("B8", $1)/ge; }
    else { $data =~ s/(.{8})/pack("B8", $1)/ge; return $data; }
}

=head2 $hex = str2hex($str or \$str)

=cut

sub str2hex {
    my $data = shift;

    if (ref $data) { $$data =~ s/(.)/unpack("H2", $1)/ge; }
    else { $data =~ s/(.)/unpack("H2", $1)/ge; return $data; }
}

=head2 $dec = str2dec($str or \$str)

=cut

sub str2dec {
    my $data = shift;

    if (ref $data) { $$data = unpack("C*", $$data); }
    else { return unpack("C*", $data); }
}

=head2 $dec = str2decs($str)

=cut

sub str2decs {
    my $data = shift;

    my @data = unpack("C*", $data);
    return \@data;
}

=head2 $bin = str2bin($str)

=cut

sub str2bin {
    my $data = shift;

    if (ref $data) { $$data =~ s/(.)/unpack("B8", $1)/ge; }
    else { $data =~ s/(.)/unpack("B8", $1)/ge; return $data; }
}

sub create_token {
    return Digest::MD5::md5_hex(rand);
}

=head2 create_secure_token

Very slow because it is using SHA-256 and The Mersenne Twister.

=cut

sub create_secure_token {
    my $sha = new Digest("SHA-256");
    $sha->add(Math::Random::MT::Auto::rand);
    return $sha->b64digest;
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

