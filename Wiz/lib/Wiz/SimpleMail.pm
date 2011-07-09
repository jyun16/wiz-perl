package Wiz::SimpleMail;

use strict;
use warnings;

no warnings 'uninitialized';

=head1 NAME

Wiz::SimpleMail

=head1 VERSION

version 1.0

=cut

our $VERSION = '1.0';

use Carp;
use Net::SMTP;
use Clone qw(clone);
use Encode qw(decode from_to);
use Encode::Guess;

use Wiz qw(get_hash_args);
use Wiz::Util::Hash qw(args2hash);

=head1 SYNOPSIS

Very simple send mail module.

 my $m = new Wiz::SimpleMail(
     smtp        => '7pp.jp',
     port        => 587,
     user        => 'hoge',
     password    => 'hogehoge',
 );
 
 $m->send(
     from        => 'jn@7pp.jp',
     to          => 'jn@7pp.jp',
     subject     => 'TEST',
     data        => 'Hoge',
 );

=head1 DESCRIPTION

=cut

sub new {
    my $self = shift;
    my $args = get_hash_args(@_);

    $args->{smtp} or do { confess "not defined smtp"; return; };

    my @param = ($args->{smtp});
    for (qw(port user password debug timeout)) {
        defined $args->{$_} and push @param, (ucfirst $_ => $args->{$_}); 
    }
    my $smtp = $args->{user} ?  _create_net_smtp_tls(\@param) : _create_net_smtp(\@param);
    my $instance = bless {
        smtp    => $smtp,
    }, $self;

    return $instance;
}

sub _create_net_smtp_tls {
    my ($param) = @_;
    my $ret = eval <<'EOS';
        use Net::SMTP::TLS;
        new Net::SMTP::TLS(@$param);
EOS
    $@ and die $@;
    return $ret;
}

sub _create_net_smtp {
    my ($param) = @_;
    new Net::SMTP(@$param);
}

sub send {
    my $self = shift;
    my $args = clone args2hash(@_);

    if ($args->{to} eq '' or $args->{from} eq '') { return; }
    my $header = $args->{header};
    for (qw(subject to from)) { 
        $args->{$_} ne '' and $header->{ucfirst $_} = 
            ref $args->{$_} eq 'ARRAY' ? join ',',  @{$args->{$_}} : $args->{$_};
    }
    my $smtp = $self->{smtp};
    $smtp->mail($args->{from});
    ref $args->{to} eq 'ARRAY' ? $smtp->to(@{$args->{to}}) : $smtp->to($args->{to});
    defined $header->{Cc} and $smtp->cc(split ',', $header->{Cc});
    defined $header->{Bcc} and $smtp->bcc(split ',', $header->{Bcc}); 
    $smtp->data;
    my $header_flag = 1;
    my ($header_part, $body);
   
    if ($args->{data} !~ /\n\n/) {
        $body = $args->{data};
    }
    else {
        ($header_part, $body) = split /\n\n/, $args->{data}, 2;
    }
    for (split /\n/, $header_part) {
        $_ =~ /(.*):\s*(.*)/;
        $header->{$1} = $2;
    }
    my ($in_enc, $out_enc) = ('', 'jis');
    $in_enc = guess_encoding($body)->name;
    from_to($body, $in_enc, $out_enc);
    from_to($header->{Subject}, $in_enc, 'MIME-Header-ISO_2022_JP');
    $header->{'Content-Type'} = 'text/plain; charset=ISO-2022-JP';
    $header->{'Content-Transfer-Encoding'} = '7bit';
    for (keys %$header) {
        $smtp->datasend("$_: $header->{$_}\n");
    }
    $smtp->datasend("\n");
    $smtp->datasend($body);
    $smtp->dataend;
}

sub reset {
    shift->{smtp}->reset;
}

sub quit {
    shift->{smtp}->quit;
}

sub DESTROY {
    my $self = shift;
    $self->{smtp}->quit;
}

=head1 AUTHOR

Junichiro NAKAMURA, C<< <jyun16@gmail.com> >>
[Modify] Toshihiro MORIMOTO C<< dealforest.net@gmail.com >>

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
