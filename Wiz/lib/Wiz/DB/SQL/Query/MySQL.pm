package Wiz::DB::SQL::Query::MySQL;

use strict;

=head1 NAME

Wiz::DB::SQL::Query::MySQL -

=head1 VERSION

version 1.0

=cut

our $VERSION = '1.0';

=head1 SYNOPSIS

=head1 DESCRIPTION

=head2 CONSTRUCTOR

=head2 METHOD

=cut

use base 'Wiz::DB::SQL::Query';

use Wiz::DB::Constant qw(:common);
use Wiz::ConstantExporter [qw(kwic)];

sub new {
    my $self = shift;
    my $instance = $self->SUPER::new(@_);
    $instance->type(DB_TYPE_MYSQL);
    return $instance;
}

=head3 $str = kwic(($field, $maxlen, $maxnum, $html_encoding, $start_str, $end_str, $word1, $pre_word1, $suf_word1, $word2, ...)

Returns string q|kwic($field,$maxlen,$maxnum,$html_encoding,"$start_str","$end_str","$word1","$pre_word1","$suf_word1")|

=cut

sub kwic {
    my ($field, $maxlen, $maxnum, $html_encoding, $start_str, $end_str, @words) = @_;
    my $ret = qq|kwic($field,$maxlen,$maxnum,$html_encoding,"$start_str","$end_str"|;
    my $n = scalar @words;
    for (my $i = 0; $i < $n; $i+=3) { $ret .= qq|,"$words[$i]","${words[$i+1]}","${words[$i+2]}"|; }
    $ret .= ')';
    return $ret;
}

sub table_status {
    my $self = shift;
    return "SHOW TABLE STATUS LIKE '$self->{table}'";
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
