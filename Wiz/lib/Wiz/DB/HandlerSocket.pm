package Wiz::DB::HandlerSocket;

use Wiz::Noose;

=head1 NAME

Wiz::DB::HandlerSocket - 

=head1 VERSION

version 1.0

=head1 SYNOPSIS

    my $hsf = new Wiz::DB::HandlerSocketFactory({
        host => $conf->{host}, port => $conf->{handler_socket}{port}, db => $conf->{db}
    });
    my $hs = $hsf->open('test', 'PRIMARY', [qw(id text)]) or die $hsf->error;
    my @data = $hs->select('>=', 1, 0, 100);
    $hs->insert(qw(1 HOGE));
    $hs->update('=', 1, [qw(1 XXXXXXXXX)]);
    $hs->delete('=', 1);

=head1 DESCRIPTION

=cut

our $VERSION = '1.0';

=head1 METHODS

=cut

use Wiz::Constant qw(:common);
use Wiz::Util::Array qw(args2array);

has 'hs' => (is => 'rw');
has 'seq' => (is => 'rw');
has 'fields' => (is => 'rw');

sub select {
    my $self = shift;
    my ($operator, $value, $offset, $limit) = @_;
    $offset ||= 0;
    $limit ||= 1;
    ref $value or $value = [ $value ];
    my $res = $self->{hs}->execute_single($self->{seq}, $operator, $value, $limit, $offset);
    $res->[0] and return undef;
    shift @$res;
    @$res or return undef;
    my @ret;
    my @fields = @{$self->{fields}};
    my $fcnt = @fields;
    my $cnt = @$res;
    for (my $i = 0; $i < $cnt; $i += $fcnt) {
        my %r = ();
        for (my $j = 0; $j < $fcnt; $j++) {
            $r{$fields[$j]} = $res->[$i+$j];
        }
        push @ret, \%r;
    }
    return wantarray ? @ret : \@ret;
}

sub retrieve {
    my $self = shift;
    my ($value) = @_;
    ref $value or $value = [ $value ];
    my $res = $self->{hs}->execute_single($self->{seq}, '=', $value, 1, 0);
    $res->[0] and return undef;
    shift @$res;
    @$res or return undef;
    my @fields = @{$self->{fields}};
    my %ret = ();
    my $i = 0;
    for (@fields) {
        $ret{$fields[$i]} = $res->[$i];
        $i++;
    }
    return \%ret;
}

sub insert {
    my $self = shift;
    my ($value) = args2array @_;
    my $res = $self->{hs}->execute_single($self->{seq}, '+', $value, 1, 0);
    $res->[0] and return FALSE;
    return TRUE;
}

sub update {
    my $self = shift;
    my ($operator, $value, $new_value) = @_;
    ref $value or $value = [ $value ];
    ref $new_value or $new_value = [ $new_value ];
    my $res = $self->{hs}->execute_single($self->{seq}, $operator, $value, 1, 0, 'U', $new_value);
    $res->[0] and return FALSE;
    return $res->[1];
}

sub delete {
    my $self = shift;
    my ($operator, $value) = @_;
    ref $value or $value = [ $value ];
    my $res = $self->{hs}->execute_single($self->{seq}, $operator, $value, 1, 0, 'D');
    $res->[0] and return FALSE;
    return $res->[1];
}

sub error {
    shift->{hs}->get_error;
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

