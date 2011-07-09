package Wiz::DB::PreparedStatement;

use strict;
use warnings;

=head1 NAME

Wiz::DB::PreparedStatement - For prepared statement

=head1 VERSION

version 1.0

=cut

our $VERSION = '1.0';

use Wiz::Constant qw(:common);
use Wiz::DB::ResultSet;

=head1 CONSTRUCTOR

=head2 new($dbc, $query)

=cut

sub new {
    my $self = shift;
    my ($dbc, $query) = @_;

    my $sth = $dbc->prepare($query, [ caller ]);
    defined $sth or return undef;

    my $instance = bless {
        dbc         => $dbc,
        sth         => $sth,
        query       => $query,
    }, $self;
    
    return $instance;
}

=head1 METHODS

=head2 execute(@data or \@data)

Executes the query that set to itself and it returns the ResultSet object.
@data is value to bind.

=cut

sub execute {
    my $self = shift;
    my @data = @_;

    ref $data[0] eq 'ARRAY' and @data = @{$data[0]};

    my $ret = $self->{sth}->execute(@data);;
    my $err = $self->{sth}->errstr;
    if ($err) {
        $self->{dbc}->write_error($err, [ caller ]);
        return $ret;
    }
    $self->{dbc}->clear_error;
    $ret eq '0E0' and return 0;
    return new Wiz::DB::ResultSet($self->{dbc}, $self->{sth});
}

=head2 execute_only(@data or \@data)

Executes the query that set to itself and it returns null.

=cut

sub execute_only {
    my $self = shift;
    my @data = @_;

    ref $data[0] eq 'ARRAY' and @data = @{$data[0]};

    my $ret = $self->{sth}->execute(@data);
    my $err = $self->{sth}->errstr;
    if ($err) {
        $self->{dbc}->write_error($err, [ caller ]);
        return $ret;
    }
    $self->{dbc}->clear_error;
    $ret eq '0E0' and return 0;
    return $ret;
}

=head2 dump(@data or \@data)

Returns the query that the values already are binded(for debugging).

=cut

sub dump {
    my $self = shift;
    return $self->{query};
}

=head2 close

Releases self object is holding values.

=cut

sub close {
    my $self = shift;

    defined $self->{sth} or return;

    $self->{sth}->finish;
    my $err = $self->{sth}->errstr;
    if ($err) {
        $self->{dbc}->write_error($err, [ caller ]);
        return FALSE;
    }
    $self->{dbc}->clear_error;
    $self->{sth} = undef;

    return TRUE;
}

sub DESTROY {
    my $self = shift;
    $self->close;
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

