package Wiz::Net::OAuth::Token;

use strict;
use warnings;

no warnings 'uninitialized';

=head1 NAME

Wiz::Net::OAuth::Token

=head1 VERSION

version 1.0

=cut

our $VERSION = '1.0';

=head1 SYNOPSIS

 my $token = new Wiz::Net::OAuth::Token(
    token  => 'token',
    secret => 'secret',
 );

 or

 my $token = new Wiz::Net::OAuth::Token('token', 'secret');
 
 or

 my $token = new Wiz::Net::OAuth::Token(OAuth::Lite::Token);

 my %token_hash = $token->token_hash;
 my @token_array = $token->token_array;
 my $token_hashref = $token->token_hashref;

=head1 DESCRIPTION

=cut

use Wiz::Noose;
use Wiz::Constant qw(:common);
use Wiz::Util::Hash qw(args2hash);

has token => ( is => 'rw' );
has secret => ( is => 'rw' );

sub BUILD {
    my $self = shift;
    my $args = args2hash @_;
    if (ref $_[0] && ref $_[0] ne 'HASH' && ref $_[0] ne 'ARRAY') {
        for my $m (qw/token secret/) { 
            $_[0]->can($m) or next;
            $self->$m($_[0]->$m); 
        }
    }
    elsif (!$args->{token} && !$args->{secret}) {
        my ($token) = keys %$args;
        $self->token($token);
        $self->secret($args->{$token});
    }
    else {
        for my $m (qw/token secret/) { $self->$m($args->{$m}); }
    }
}

sub token2args {
    my $self = shift;
    my $token_data = [$self->token, $self->secret];
    wantarray ? @$token_data : $token_data;
}

sub token2hash {
    my $self = shift;
    ( token => $self->token, secret => $self->secret );
}

sub token2hashref {
    my $self = shift;
    { token => $self->token, secret => $self->secret };
}

=head1 AUTHOR

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

