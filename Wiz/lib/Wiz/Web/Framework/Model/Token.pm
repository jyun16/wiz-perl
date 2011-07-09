package Wiz::Web::Framework::Model::Token;

=head1 NAME

Wiz::Web::Framework::Model::Token

=head1 VERSION

version 1.0

=cut

our $VERSION = '1.0';

=head1 SQL

=head2 MySQL

 CREATE TABLE token (
     id              INTEGER         AUTO_INCREMENT  PRIMARY KEY,
     token           VARCHAR(32)     UNIQUE,
     type            TINYINT,
     data            TEXT,
     created_time    DATETIME,
     last_modified   TIMESTAMP,
     KEY(token),
     KEY(token, type)
 ) ENGINE=innodb DEFAULT CHARACTER SET utf8 COLLATE utf8_bin;

=cut

use Clone qw(clone);
use Data::Dumper;

use Wiz::Noose;
use Wiz::Constant qw(:common);
use Wiz::DateTime;
use Wiz::Util::Math;
use Wiz::Util::Hash qw(args2hash);

extends qw(Wiz::Web::Framework::Model);

use Wiz::ConstantExporter {
    TOKEN_TYPE_REGIST => 1,
}, 'type';

our %TOKEN_EXPIRE = (
    TOKEN_TYPE_REGIST()  => 86400,
);

sub create_token {
    my $self = shift;
    my ($param) = args2hash @_;

    my $token_str = Wiz::Util::Math::create_token;
    $self->set(token => $token_str);

    my $now = Wiz::DateTime->new;
    $self->set(created_time => $now->to_string);

    if ($param->{data}) {
        $param = clone $param;
        local $Data::Dumper::Terse = 1;
        local $Data::Dumper::Indent = 0;
        $param->{data} = Dumper $param->{data};
    }
    return $self->create($param);
}

sub get_token {
    my $self = shift;
    my ($token, $type) = @_;

    my $param = { token => $token };
    defined $type and $param->{type} = $type;
    my $token_data = $self->getone($param);
    if ($token_data) { $token_data->{data} and $token_data->{data} = eval $token_data->{data}; }
    return $token_data;
}

sub remove_token {
    my $self = shift;
    my ($token, $type) = @_;
    $self->delete({
        token   => $token
    });
}

sub token_expire {
    my $self = shift;
    return $TOKEN_EXPIRE{+shift};
}

sub set_token_expire {
    my $self = shift;
    my ($expires) = args2hash @_;
    for (%$expires) { $TOKEN_EXPIRE{$_} = $expires->{$_}; }
}

=head1 SEE ALSO

L<Catalyst::Model::Wiz/DEFAULT FILTER>.

=head1 AUTHOR

Junichiro NAKAMURA, C<< <jyun16@gmail.com> >>

=head1 COPYRIGHT & LICENSE

Copyright 2010 The Wiz Project. All rights reserved.

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
