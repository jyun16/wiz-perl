package Wiz::Web::Framework::Controller::Delete;

=head1 NAME

Wiz::Web::Framework::Controller::Delete

=head1 VERSION

version 1.0

=cut

our $VERSION = '1.0';

=head1 SYNOPSIS

=cut

use Wiz::Noose;
use Wiz::Util::String qw(camel2normal);

extends qw(Wiz::Web::Framework::Controller);

sub _index {
    my $self = shift;
    my ($c, $af, $p, $s) = @_;
    my $m = $self->_model($c, $af, $p, $s);
    my $delete_getone_method =
        $self->ourv('REMOVE_GETONE_METHOD') || $self->ourv('DELETE_GETONE_METHOD') || 'getone';
    my $pkey_val = $m->remove_key_params($p);
    my $data_name = camel2normal($self->ourv('MODEL')) . '_data';
    my $data = $c->stash->{$data_name} ? $c->stash->{$data_name} : $m->$delete_getone_method($p);
    for (keys %$pkey_val) { $s->{$_} = $pkey_val->{$_} };
    $af->params($data);
    return $data;
}

sub _execute_index {
    my $self = shift;
    my ($c, $af, $p, $s) = @_;
    $self->_execute($c, $af, $p, $s);
}

sub _execute {
    my $self = shift;
    my ($c, $af, $p, $s) = @_;
    my $m = $self->_model($c, $af, $p, $s);
    my $d;
    if ($self->ourv('NEED_DATA')) {
        $d = $m->getone($m->remove_key_params($s));
    }
    my $remove_method = $self->ourv('REMOVE_METHOD') || 'remove';
    $m->$remove_method($s);
    $self->_append_to_execute($c, $af, $p, $s, $m, $d);
    $self->_append_execute($c, $af, $p, $s, $m, $d);
    $m->commit;
}

sub _model {
    my $self = shift;
    my ($c, $af, $p, $s) = @_;
    return $c->model($self->ourv('MODEL'));
}

*_append_to_execute = '_append_execute';

sub _before_index {}
sub _after_index {}
sub _before_execute_index {}
sub _after_execute_index {}
sub _append_execute {}
sub _finish_redirect_dest {
    my $self = shift;
    my ($c, $af, $p, $s) = @_;
    $s->{finish_redirect_dest} ? $s->{finish_redirect_dest} : 'finish';
}

sub index {
    my $self = shift;
    my ($c) = @_;

    my $stash = $c->stash;
    my $template_base = $self->ourv('TEMPLATE_BASE');
    if ($template_base) {
        $template_base =~ s#^/##; $template_base =~ s#/$##;
        $stash->{template} = $self->ourv('TEMPLATE_BASE') . "/index.tt";
    }
    my $use_token = $self->use_secure_token($c);
    my $method = $c->req->method;
    if ($method eq 'GET' and $use_token) { $c->embed_token; }
    my $p = $c->req->params;
    my $s = $self->_session($c);
    my $af = $c->autoform([$self->ourv('AUTOFORM', '@')], undef, { language => $c->language });
    $af->mode('delete');
    if ($method eq 'GET') {
        $self->_before_index($c, $af, $p, $s);
        my $data = $self->_index($c, $af, $p, $s);
        $self->_after_index($c, $af, $p, $s);
        $stash->{f} = $af;
        $stash->{s} = $s;
        $stash->{data} = $data;
    }
    elsif ($method eq 'POST') {
        $self->_before_execute_index($c, $af, $p, $s);
        $self->_execute_index($c, $af, $p, $s);
        $self->_after_execute_index($c, $af, $p, $s);
        my @dest = $self->_finish_redirect_dest($c, $af, $p, $s);
        $self->_remove_session($c);
        $c->redirect(@dest);
    }
}

sub finish {
    my $self = shift;
    my ($c) = @_;
    my $stash = $c->stash;
    my $template_base = $self->ourv('TEMPLATE_BASE');
    if ($template_base) {
        $template_base =~ s#^/##; $template_base =~ s#/$##;
        $stash->{template} = $self->ourv('TEMPLATE_BASE') . "/finish.tt";
    }
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
