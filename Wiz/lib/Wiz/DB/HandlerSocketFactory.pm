package Wiz::DB::HandlerSocketFactory;

use Wiz::Noose;

=head1 NAME

Wiz::DB::HandlerSocketFactory - 

=head1 VERSION

version 1.0

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut

our $VERSION = '1.0';

=head1 METHODS

=cut

use Wiz::DB::HandlerSocket;

has 'host' => (is => 'rw', default => 'localhost');
has 'port' => (is => 'rw', default => 9998);
has 'db' => (is => 'rw', required => 1);
has 'hs' => (is => 'rw');
has 'seq' => (is => 'rw', default => 1);

our $USED_MYSELF;

sub BUILD {
    my $self = shift;
    my ($args) = @_;
    unless ($USED_MYSELF) { eval 'use Net::HandlerSocket'; $USED_MYSELF = 1; }
    $self->{hs} = new Net::HandlerSocket({
        host    => $args->{host},
        port    => $args->{port},
    });
}

sub open {
    my $self = shift;
    my ($table, $index, $fields) = @_;
    $self->{error} = undef;
    my $fields_array;
    if (ref $fields eq 'ARRAY') {
        $fields_array = $fields;
        $fields = join ',', @$fields;
    }
    else { $fields_array = [ split /,/, $fields ]; }
    my $seq = $self->{seq}++;
    my $hs = $self->{hs};
    $hs->open_index($seq, $self->{db}, $table, $index, $fields) and do {
        $self->{error} = $hs->get_error;
        return undef;    
    };
    return new Wiz::DB::HandlerSocket(hs => $hs, seq => $seq, fields => $fields_array);
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

