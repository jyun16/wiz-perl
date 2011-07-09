package Wiz::DB::ConnectionFactory;

use strict;
use warnings;

=head1 NAME

Wiz::DB::ConnectionFactory -

=head1 VERSION

version 1.0

=cut

our $VERSION = '1.0';

=head1 SYNOPSIS

This factory class make a object which is Connection or ConnectionPoolingObject.

 use Wiz::DB::Constant qw(:all);
 use Wiz::DB::Connection;
 use Wiz::DB::ConnectionPool;
 use Wiz::DB::ConnectionFactory;
 use Wiz::DB::ResultSet;
 
 my %conf = (
     type        => DB_TYPE_MYSQL,
     host        => 'localhost',
     db          => 'test',
     user        => 'test',
     passwd      => 'test',
     auto_commit => TRUE,
     log     => {
         path    => 'logs/db/error.log',
         stderr  => TRUE,
     },
     min_idle    => 2,
     max_idle    => 4,
     pooling     => 1,
 );
 
 my $cf = new Wiz::DB::ConnectionFactory(%conf);
 my $dbc = $cf->create;
 
 my $rs = $dbc->execute("SELECT * FROM test");
 while ($rs->next) {
     warn $rs->get('id');
 }
 
 $rs->close;
 $dbc->close;

=cut

use base qw(Wiz::DB::Base);

use Wiz qw(get_hash_args);
use Wiz::Constant qw(:common);
use Wiz::DB::Connection;
use Wiz::DB::ConnectionPool;

my %default = (
    pooling => FALSE,
    pool    => undef,
);

=head2 ACCESSOR

 pooling

=cut

our @CONFS = qw(pooling);

__PACKAGE__->mk_accessors(@CONFS);

=head1 CONSTRUCTOR

=head2 new(%conf) or new(\%conf)

The arguments are same constructor of the Connection or the ConnectionPool.
But it is appended a parameter that name is "pooling".
The "pooling" is boolian value.
When the "pooling" is TRUE, this class make the ConnectionPoolObject.

=cut

sub new {
    my $self = shift;

    my $conf = get_hash_args(@_);

    my $instance = bless {
        map { $_ => $conf->{$_} ? $conf->{$_} : $default{$_} } keys %default
    }, $self;
    $instance->{conf} = $conf;

    if (defined $conf->{pooling} and $conf->{pooling}) {
        $instance->{pool} = new Wiz::DB::ConnectionPool($conf);
    }

    return $instance;
}

=head1 METHODS

=head2 $dbc = create

Returns a instance of the Connection or the ConnectionPoolObject.

=cut

sub create {
    my $self = shift;
    return $self->{pooling} ? 
        $self->create_connection_from_pool : $self->create_connection;
}

=head2 $dbc = create_connection

Returns a instance of the Connection.

=cut

sub create_connection {
    my $self = shift;
    return new Wiz::DB::Connection($self->{conf});
}

=head2 $dbc = create_connection_from_pool

Returns a instance of the ConnectionPoolObject.

=cut

sub create_connection_from_pool {
    my $self = shift;
    return $self->{pool}->get_connection;
}

=head2 status_dump

For debug

=cut

sub status_dump {
    my $self = shift;
    $self->{pooling} == FALSE and return; 
    $self->{pool}->status_dump; 
}

sub force_close {
    my $self = shift;
    $self->{pooling} and defined $self->{pool} and $self->{pool}->close;
}

=head1 SEE ALSO

L<Wiz::DB::Connection>, L<Wiz::DB::ConnectionPool>

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
