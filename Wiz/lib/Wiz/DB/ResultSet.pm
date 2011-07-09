package Wiz::DB::ResultSet;

use strict;
use warnings;

=head1 NAME

Wiz::DB::ResultSet - Statement handle wrapper class

=head1 VERSION

version 1.0

=cut

our $VERSION = '1.0';

=head1 SYNOPSIS

=head1 DESCRIPTION

This package use fetchrow_hashref at internal it, 
because it improve generality(and to be comparable java.sql.ResultSet).
As a result, it is slower than to use fetchrow_array.
If it is problem, I suggest to use the prepare method ofWiz::DB::Connection.

=cut

use Wiz::Constant qw(:common);

=head1 CONSTRUCTOR

=head2 new($sth, $dbc)

$sth: statement handle(is already executed)
$dbc: database handle

The reason why give the connection to it is to delete itself from the ResultSet management table when self is closed.

=cut

sub new {
    my $self = shift;
    my ($dbc, $sth) = @_;

    my $status = bless {
        dbc         => $dbc,
        sth         => $sth,
        data        => {},
    }, $self;
    return $status;
}

=head1 METHODS

=head2 next

Moves the cursor down one row from its current position.
When it has no next reacords or error happens, it returns "0".

=cut

sub next {
    my $self = shift;

    my $data = $self->{sth}->fetchrow_hashref();
    my $err = $self->{sth}->errstr;
    if ($err) {
        $self->{dbc}->write_error($err, [ caller ]);
        return FALSE;
    }
    $self->{dbc}->clear_error;

    if (defined $data) {
        $self->{data} = $data;
        return TRUE;
    }
    else { return FALSE; }
}

=head2 $value = get($key)

Returns the value of the designated column in the current row of self ResultSet object.

=cut

sub get {
    my $self = shift;
    my $key = shift;

    defined $self->{data} or return undef;
    return $self->{data}{$key};
}

=head2 $data = data

Returns the hash reference data of result.

=cut

sub data {
    my $self = shift;

    return $self->{data};
}

=head2 $column_names = keys

Returns the list of column names on the table.

=cut

sub keys {
    my $self = shift;
    return $self->{sth}{NAME};
}

=head2 $column_names = columns

Returns the list of column names on the table.

=cut

sub columns {
    my $self = shift;
    return $self->{sth}{NAME};
}

=head2 $field_number = fields_num

Returns the number of the fileds on the table.

=cut

sub field_num {
    my $self = shift;
    return $self->{sth}{NUM_OF_FIELDS};
}

=head2 $field_names = field_names

Returns the list of the name of the fields on the table.

=cut

sub field_names {
    my $self = shift;
    return $self->{sth}{NAME};
}

=head2 close

Releases self object is holding values.

=cut

sub close {
    my $self = shift;

    if (defined $self->{sth}) {
        local $@;
        eval { $self->{sth}->finish(); };
        if ($@ ne '') {
            my @ca = caller;
            $@ and $self->write_error($@, [ caller ]);
            $@ = ''; return FALSE;
        }
        $self->{sth} = undef;
    }

    $self->{data} = undef;
    return TRUE;
}

sub DESTROY {
    my $self = shift;
    $self->close();
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
