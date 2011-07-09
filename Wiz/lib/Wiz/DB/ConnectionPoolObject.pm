package Wiz::DB::ConnectionPoolObject;

use strict;
use warnings;

=head1 NAME

Wiz::DB::ConnectionPoolObject -

=head1 VERSION

version 1.0

=cut

our $VERSION = '1.0';

=head1 SYNOPSIS

This object will be passed by ConnectionPool. It doesn't intend to be used directly.

=cut

use strict;

use base qw(Wiz::DB::Connection);

use Wiz::ReturnCode qw(:all);

=head1 CONSTRUCTOR

=head2 new(%conf) or new(\%conf)

Intend to be called only from ConnectionPool.

=cut

sub new {
    my $self = shift;
    my ($conf, $pool) = @_;

    my $instance = $self->SUPER::new(%$conf);
    return_code_is($instance, undef) and return $instance;

    $instance->{pool} = $pool;
    $instance->{create_date} = time;
    $instance->{last_update} = time;
    $instance->{used_count} = 0;
    #  TRUE will be set in case of slave. Data manipulation will be restricted to select.
    $instance->{is_slave} = undef;

    return $instance;
}

=head1 METHODS

=head2 date_refresh

Resets 'last_update' with the time being called self method.

=cut

sub date_refresh {
    my $self = shift;
    $self->{last_update} = time;
}

=head2 increment_used_count

Increments the count of used of self connection.

=cut

sub increment_used_count {
    my $self = shift;
    ++($self->{used_count});
}

=head2 $used_count = used_count

Getrer

=cut

sub used_count {
    my $self = shift;
    return $self->{used_count};
}

=head2 $create_date = create_date

$create_date: Wiz::Date

=cut

sub create_date {
    my $self = shift;
    return new Wiz::Date($self->{create_date});
}

=head2 $last_update = last_update

Getter

=cut

sub last_update {
    my $self = shift;
    return $self->{last_update}
}

=head2 close

close virtual connection.
self method is used by client.

Pooled as an idle connection if possible. Otherwise, simply closed.
Its implementation is delegated to ConnectionPool.

=cut

sub close {
    my $self = shift;

    $self->close_statement_handle();
    $self->{pool} and $self->{pool}->release($self);
}

=head2 force_close

Enforce closing connection.

=cut

sub force_close {
    my $self = shift;
    $self->close_statement_handle();
    $self->_close();
}

=head2 status_dump

For debug

=cut

sub status_dump {
    my $self = shift;

    print <<EOS;
===== [ CONNECTION POOL STATUS DUMP ]==================================
CREATE DATE: $self->{create_date}
LAST UPDATE: $self->{last_update}
USED CNT: $self->{used_count}
=======================================================================
EOS
}

sub DESTROY {
    my $self = shift;
    $self->force_close;
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
