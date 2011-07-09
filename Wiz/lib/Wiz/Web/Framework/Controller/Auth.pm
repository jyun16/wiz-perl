package Wiz::Web::Framework::Controller::Auth;

=head1 NAME

Wiz::Web::Framework::Controller::Auth

=head1 VERSION

version 1.0

=cut

our $VERSION = '1.0';

=head1 SYNOPSIS

our %AUTH_TARGET = (
    '&index'    => [
        default     => [qw(read write)],
        admin       => 1,
    ],
    secret    => [
        default => {
            read    => 1,
            write   => 1,
        },
        admin       => 1,
    ],
    special     => \&special_auth,
    any         => '*index',
);

&index: default(read or write) or admin,
secret: default(read and write) or admin,
special: \&special_auth,
any: *index,

default(read or write) or admin,
[
    default     => [qw(read write)],
    admin       => 1,
]

The keys "index", "secret", "special", "any" are dispatch point name.
The prefix &, * are YAML like anchor and alias.

See L<Wiz::Util::Hash>'s hash_anchor_alias.

The keys "default" and "admin" are Auth::Controller's label.
"read" is user role.

When dispatch point name's value is hash reference,
its page need read role and admin authority.
When it's array reference, need read role or admin authority.

The role is same rule too.

Hash reference is AND, array reference is OR.

our $AUTH_WITH_ROOT_ARGS = 1;
our $AUTH_FAIL_DEST = '/error';
our @AUTH_FAIL_ARGS = (msgid => 'not_login', history_back => 1);    

When the $AUTH_WITH_ROOT_ARGS is true, Catalyst::Plugin::DispatchType::Root's value is used.
$c->stash->{root_args} not equal $c->u->userid, then login fail.
You must include the following subroutine if you use the function.

 sub index : Root(1) {
     shift->SUPER::index(@_);
 }

%AUTH_TARGET decide the action to enable authentication.
If it is ommited, the authentication run on the all actions.

When you won't redirect,

our $AUTH_FAIL_REDIRECT = FALSE;

When you have to return status code decided yourself,

our $AUTH_FAIL_STATUS_CODE = 403;

=cut

use Wiz::Noose;
use Wiz::Constant qw(:common);
use Wiz::Util::Hash qw(hash_anchor_alias);

extends qw(Wiz::Web::Framework::Controller);

sub __begin_auth {
    my $self = shift;
    my ($c) = @_;
    $self->ourv('AUTH_TARGET', '%') or goto OK;
    my $target = hash_anchor_alias($self->ourv('AUTH_TARGET', '%'));
    my $authz_label = $self->ourv('AUTHZ_LABEL') || 'default';
    my $session_label = $self->ourv('SESSION_LABEL') || 'default';
    my $role = undef;
    if (%$target) {
        my $t = $target->{$c->req->action_method};
        $t or goto OK;
        if (ref $t eq 'CODE') {
            $t->($self, $c) or goto BANN;
            goto OK;
        }
        else {
            $c->logined($authz_label, $session_label) or goto BANN;
            my $user = $c->u($authz_label, $session_label);
            $user->label or goto BANN;
            my $check_role = $t->{$user->label};
            $check_role or goto BANN;
            my $check_role_ref = ref $check_role;
            if ($check_role_ref eq 'ARRAY') {
                $user->has_role($check_role) or goto BANN;
            }
            elsif ($check_role_ref eq 'CODE') {
                $check_role->($self, $c, $user) or goto BANN;
            }
        }
    }
    if ($self->ourv('AUTH_WITH_ROOT_ARGS')) {
        my $args = $c->stash->{root_args};
        if (not defined $args or $args->[0] ne $c->u->userid) { goto BANN; }
    }
    goto OK;
OK:
    return;
BANN:
    my $auth_fail_redirect = $self->ourv('AUTH_FAIL_REDIRECT');
    defined $auth_fail_redirect or $auth_fail_redirect = TRUE;
    if ($self->ourv('AUTH_FAIL_STATUS_CODE')) {
        $c->res->status($self->ourv('AUTH_FAIL_STATUS_CODE'));
    }
    elsif ($self->ourv('AUTH_FAIL_DEST_TO_ERROR')) {
        $c->goto_error($self->ourv('AUTH_FAIL_DEST_TO_ERROR'));
    }
    elsif ($auth_fail_redirect) {
        my $dest = $self->ourv('AUTH_FAIL_DEST');
        (not defined $dest or $dest eq '') and $dest = '/';
        $c->redirect($dest, $self->ourv('AUTH_FAIL_ARGS'));
    }
    return;
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
