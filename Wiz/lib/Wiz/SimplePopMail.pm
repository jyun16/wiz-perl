package Wiz::SimplePopMail;

use strict;
use warnings;

no warnings 'uninitialized';

=head1 NAME

Wiz::SimplePopMail

=head1 VERSION

version 1.0

=cut

our $VERSION = '1.0';

use Clone qw(clone);
use Carp;
use Email::MIME;
use Mail::POP3Client;

use Wiz qw(get_hash_args);

=head1 SYNOPSIS

    my $pop = Wiz::SimplePopMail(
        pop         => '',
        user        => '',
        password    => '',
    );

    my $messages = $pop->pop;
    for (@$messages) {
        print "$_->{header}{Subject}\n";
        print "$_->{body}\n";
    }

=head1 DESCRIPTION

    my $pop = Wiz::SimplePopMail(
        pop             => '',
        user            => '',
        password        => '',
        port            => 110,
        debug           => 0,
        auth_mode       => 'BEST',
        timeout         => 60,
        use_ssl         => 0,
        delete_message  => 0,
    );

    auth_mode: BEST, PASS, APOP, CRAM-MD5
    delete_message: delete all messages after pop message.

=cut

sub new {
    my $self = shift;
    my $args = clone get_hash_args(@_);
    $args->{host} = $args->{pop}; delete $args->{pop};
    $args->{usessl} = $args->{use_ssl}; delete $args->{use_ssl};
    my $delete_message = $args->{delete_message} || 0;
    for (keys %$args) {
        $args->{uc $_} = $args->{$_};
        delete $args->{$_};
    }
    my $pop = new Mail::POP3Client(%$args);
    my $instance = bless {
        pop             => $pop,
        delete_message  => $delete_message,
    }, $self;
    return $instance;
}

sub pop {
    my $self = shift;
    my @ret = ();
    my $pop = $self->{pop};
    for my $n (1..$pop->Count) {
        my %r = ();
        my $parsed = new Email::MIME(scalar $pop->Retrieve($n));
        $r{number} = $n;
        $r{header} = { $parsed->header_pairs };
        $r{body} = $parsed->body;
        push @ret, \%r;
        $self->{delete_message} and $pop->Delete($n);
    }
    return \@ret;
}

sub delete {
    my $self = shift;
    $self->{pop}->Delete(@_);
}

sub DESTROY {
    my $self = shift;
    $self->{pop}->Close;
}

=head1 AUTHOR

Junichiro NAKAMURA, C<< <jyun16@gmail.com> >>

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
