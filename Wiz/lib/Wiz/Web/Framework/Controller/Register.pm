package Wiz::Web::Framework::Controller::Register;

=head1 NAME

Wiz::Web::Framework::Controller::Register

=head1 VERSION

version 1.0

=cut

our $VERSION = '1.0';

=head1 SYNOPSIS

=cut

use Wiz::Noose;
use Wiz::Constant qw(:common);

extends qw(Wiz::Web::Framework::Controller);

sub _index {
    my $self = shift;
    my ($c, $af) = @_;
}

sub _execute_index {
    my $self = shift;
    my ($c, $af, $p, $s) = @_;
    my $params = $af->complement_params($p);
    $af->params($params);
    $af->continue_check_params;
    $self->_session($c, $af->params);
}

sub _confirm {
    my $self = shift;
    my ($c, $af, $p, $s) = @_;
    $af->params($s);
}

sub _execute_confirm {
    my $self = shift;
    my ($c, $af, $p, $s) = @_;
    return $self->_execute($c, $af, $p, $s);
}

sub _execute {
    my $self = shift;
    my ($c, $af, $p, $s) = @_;
    my $m = $self->_model($c, $af, $p, $s);
    my $create_method = $self->ourv('CREATE_METHOD') || 'create';
    $self->_append_to_execute($c, $af, $p, $s, $m, $m->$create_method($s));
    $m->commit;
    return SUCCESS;
}

sub _model {
    my $self = shift;
    my ($c, $af, $p, $s) = @_;
    return $c->model($self->ourv('MODEL'));
}

sub __before_index {}
sub _before_index {}
sub __after_index {}
sub _after_index {}
sub _before_execute_index {}
sub _after_execute_index {}
sub __before_confirm {}
sub _before_confirm {}
sub __after_confirm {}
sub _after_confirm {}
sub _append_to_execute {}
sub _before_execute_confirm {}
sub _after_execute_confirm {}
sub _finish_redirect_dest {
    my $self = shift;
    my ($c, $af, $p, $s) = @_;
    my $dest = $s->{finish_redirect_dest} || 'finish';
    ref $dest eq 'ARRAY' ? @$dest : $dest;
}
sub _finish { }

sub index {
    my $self = shift;
    my ($c) = @_;
    my $stash = $c->stash;
    my $template_base = $self->ourv('TEMPLATE_BASE');
    if ($template_base) {
        $template_base =~ s#^/##; $template_base =~ s#/$##;
        $stash->{template} = $self->ourv('TEMPLATE_BASE') . "/index.tt";
    }
    my $method = $c->req->method;
    if ($method eq 'GET' and $self->ourv('USE_TOKEN')) { $c->embed_token; }
    my $p = $c->req->params;
    my $s = $self->_session($c);
    my $af = $c->autoform([$self->ourv('AUTOFORM', '@')], $s, { language => $c->language });
    $af->mode('register');
    if ($method eq 'GET') {
        $self->__before_index($c, $af, $p, $s);
        $self->_before_index($c, $af, $p, $s);
        $self->_index($c, $af, $p, $s);
        $self->_after_index($c, $af, $p, $s);
        $self->__after_index($c, $af, $p, $s);
    }
    elsif ($method eq 'POST') {
        $af->params($p);
        $self->__before_index($c, $af, $p, $s);
        $self->_before_execute_index($c, $af, $p, $s);
        $self->_execute_index($c, $af, $p, $s);
        $self->_after_execute_index($c, $af, $p, $s);
        $self->__after_index($c, $af, $p, $s);
        my $errors = $af->{validator}{errors};
        my %forms = map { $_ => 1 } @{$af->input_forms};
        for (keys %$errors) { $forms{$_} or delete $errors->{$_}; }
        if ($af->has_error) {
            $af->clear_password_value;
            my $dest = $self->ourv('VALIDATION_FAIL_DEST') || $s->{validation_fail_dest};
            $dest and $c->redirect($dest);
        }
        else { $c->redirect('confirm'); }
    }
    $stash->{f} = $af;
    $stash->{s} = $s;
}

sub _set_template_base {
    my $self = shift;
    my ($c) = @_;
    my $stash = $c->stash;
    my $template_base = $self->ourv('TEMPLATE_BASE');
    if ($template_base) {
        $template_base =~ s#^/##; $template_base =~ s#/$##;
        $stash->{template} = $self->ourv('TEMPLATE_BASE') . "/confirm.tt";
    }
}

sub confirm {
    my $self = shift;
    my ($c) = @_;
    my $stash = $c->stash;
    my $p = $c->req->params;
    my $s = $self->_session($c);
    my $af = $c->autoform([$self->ourv('AUTOFORM', '@')], $s, { language => $c->language });
    $af->mode('register');
    if ($c->req->method eq 'GET') {
        $self->_set_template_base($c);
        $self->__before_confirm($c, $af, $p, $s);
        $self->_before_confirm($c, $af, $p, $s);
        $self->_confirm($c, $af, $p, $s);
        if ($self->ourv('SKIP_CONFIRM')) {
            $c->forward('execute_confirm', [ $af, $p, $s ]);
        }
        $self->_after_confirm($c, $af, $p, $s);
        $self->__after_confirm($c, $af, $p, $s);
    }
    elsif ($c->req->method eq 'POST') {
        $c->forward('execute_confirm', [ $af, $p, $s ]);
    }
    $stash->{f} = $af;
    $stash->{s} = $s;
}

sub execute_confirm {
    my $self = shift;
    my ($c, $af, $p, $s) = @_;
    $self->_set_template_base($c);
    unless ($af) {
        $af = $c->autoform([$self->ourv('AUTOFORM', '@')], $s, { language => $c->language });
    }
    unless ($p) { $p = $c->req->params; }
    unless ($s) { $s = $self->_session($c); }
    $self->__before_confirm($c, $af, $p, $s);
    $self->_before_execute_confirm($c, $af, $p, $s);
    my $success = $self->_execute_confirm($c, $af, $p, $s);
    $self->_after_execute_confirm($c, $af, $p, $s);
    $self->__after_confirm($c, $af, $p, $s);
    my @dest = $self->_finish_redirect_dest($c, $af, $p, $s);
    $success and $self->_remove_session($c);
    $c->redirect(@dest);
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
    $self->_finish($c);
}

=head1 AUTHOR

Junichiro NAKAMURA, C<< <jyun16@gmail.com> >>

[Modify] Toshihiro MORIMOTO C<< dealforest.net@gmail.com >>

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
