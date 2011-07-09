package Wiz::Web::Framework::Session::Controller;

=head1 NAME

Wiz::Web::Framework::Session::Controller

=head1 VERSION

version 1.0

=cut

our $VERSION = '1.0';

use Wiz::Noose;
use Wiz::Web::Framework::Session;
use Wiz::Web::Framework::Session::DB;
use Wiz::Web::Framework::Session::DB::HandlerSocket;
use Wiz::Web::Framework::Session::Memcached;

has 'conf' => (is => 'rw');

sub init {
    my $self = shift;
    for (keys %{$self->{sessions}}) {
        $self->{sessions}{$_}->init;
    }
}

sub session {
    my $self = shift;
    my ($c, $label) = @_;
    my $session_obj = $self->_get_session_obj($c, $label);
    return $session_obj->session;
}

sub change_session_id {
    my $self = shift;
    my ($c, $label) = @_;
    my $session_obj = $self->_get_session_obj($c, $label);
    $session_obj->change_session_id;
}

sub clear_session {
    my $self = shift;
    my ($c, $label) = @_;
    my $session_obj = $self->_get_session_obj($c, $label);
    $session_obj->clear_session;
}

sub data2server {
    my $self = shift;
    for (keys %{$self->{sessions}}) {
        $self->{sessions}{$_}->data2server;
        delete $self->{sessions}{$_};
    }
}

sub _get_session_obj {
    my $self = shift;
    my ($c, $label) = @_;
    $label ||= 'default';
    unless ($self->{sessions}{$label}) {
        my $conf = $self->conf->{cluster} ?
            $self->conf->{cluster}{$label} :
            $self->conf;
        my $session_class = 'Wiz::Web::Framework::Session::';
        if ($conf->{use_handler_socket}) {
            $session_class .= 'DB::HandlerSocket';
        }
        elsif ($conf->{db}) {
            $session_class .= 'DB';
        }
        else {
            $session_class .= 'Memcached';
        }
        $self->{sessions}{$label} =
            new $session_class(c => $c, conf => $conf, label => $label);
        if ($conf->{sid_from_param}) {
            $self->{sessions}{$label}{sid_from_param} = $conf->{sid_from_param};
        }
    }
    return $self->{sessions}{$label};
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


