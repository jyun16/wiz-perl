package Wiz::Web::Framework::Model::Message;

=head1 NAME

Wiz::Web::Framework::Model::Message

=head1 VERSION

version 1.0

=cut

our $VERSION = '1.0';

=head1 SYNOPSIS

use Wiz::Constant qw(:common);

our @CREATE = qw(
member_id_from
member_id_to
type
message
data
read_flag
created_time
);
our @MODIFY = @CREATE;
our @SEARCH = ('id', @CREATE);
our $PRIMARY_KEY = 'id';
our $MODIFY_KEY = [qw(id)];

=cut

=head1 SQL

=head2 MySQL

 CREATE TABLE message (
     id                  INTEGER UNSIGNED    AUTO_INCREMENT  PRIMARY KEY,
     member_id_from      INTEGER UNSIGNED,
     member_id_to        INTEGER UNSIGNED,
     type                SMALLINT UNSIGNED,
     message             TEXT,
     data                TEXT,
     read_flag           BOOL                DEFAULT 0,
     delete_flag         BOOL                DEFAULT 0,
     created_time        DATETIME            NOT NULL,
     last_modified       TIMESTAMP,
     KEY(member_id_to, read_flag)
 ) ENGINE=innodb DEFAULT CHARACTER SET utf8 COLLATE utf8_bin;

=cut

use Storable qw(thaw nfreeze);

use Wiz::Noose;
use Wiz::Constant qw(:common);

extends qw(Wiz::Web::Framework::Model);

sub send {
    my $self = shift;
    my ($from, $to, $type, $message, $data) = @_;
    $data ||= {};
    $self->clear;
    $self->set(
        member_id_from  => $from,
        member_id_to    => $to,
        type            => $type,
        message         => $message,
        data            => nfreeze $data,
    );
    $self->create;
}

sub receive {
    my $self = shift;
    my ($to) = @_;
    my $ret = $self->search(
        member_id_to    => $to,
        read_flag       => FALSE,
    );
    for (@$ret) {
        $_->{data} = thaw $_->{data};
    }
    return $ret;
}

sub read {
    my $self = shift;
    my ($id, $member_id) = @_;
    $self->clear;
    $self->set(
        read_flag   => TRUE,
    );
    $self->modify(
        id              => $id,
        member_id_to    => $member_id,
    );
}

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
