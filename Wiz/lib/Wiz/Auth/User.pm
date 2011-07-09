package Wiz::Auth::User;

use strict;
use warnings;

no warnings 'uninitialized';

=head1 NAME

Wiz::Auth::User

=head1 VERSION

version 1.0

=cut

our $VERSION = '1.0';

=head1 SYNOPSIS

 #  create an instance for the user.
 my $user = Wiz::Auth::User->new( userid => $userid );
 
 #  check if the user has a role 'role1'
 if ($user->has_role('role1')) {
    #  work for role1   
 }
 
 #  get all roles of the user.
 my @roles = $user->get_roles();
 
 #  check status of the user stored on database.
 if ($user->check_status(2)) { ... }
 
 #  get a part of user information stored on database.
 #  for example, if user table has a field 'email_address',
 #  it can be retrieved by the following way.
 my $email_address = $user->get('email_address');


=head1 DESCRIPTION

Represents information of one user.

=cut

use base qw(Class::Accessor::Fast);

use Carp;

use Wiz qw(get_hash_args);
use Wiz::Constant qw(:all);

=head2 $user = new($tables, $user)

Constuctor.

$tables - a name of table which contains user login and additional information.
$user - hashref of user information retrieved from DB.

=cut

sub new {
    my $class = shift;
    my ($user, $roles) = @_;
    delete $user->{password};
    bless {
        user    => $user, 
        roles   => $roles,
    }, $class;
}

=head2 @roles = get_roles()

Returns value of the specified field from the user information.
$field must be exist as a field of user information table.

=cut

sub get_roles {
    my $self = shift;
    my @roles = grep { $self->{roles}{$_} } keys %{ $self->{roles} }; 
    return wantarray ? @roles : \@roles;
}

=head2 $result = has_role($role_name)

Check if the user has a role.

=head2 $result = has_role(-and => [ @role_names ])

Check if the user has all roles.

=head2 $result = has_role({ $role_name1 => 1, $role_name2 => 1, ... })

Check if the user has all roles.

=head2 $result = has_role(-or => [ @role_names ])

Check if the user has at least one role or more.

=head2 $result = has_role([ @role_names ])

Check if the user has at least one role or more.

=cut

sub has_role {
    my $self = shift;
    my @args = @_;

    defined $self->{roles} or return FALSE;

    my $r = ref $args[0];
    if ($r eq 'HASH') {
        $self->_has_role_and([keys %{$args[0]}]);
    }
    elsif ($r eq 'ARRAY') {
        $self->_has_role_or($args[0]);
    }
    else {
        if ($args[0] eq '-and') {
            $self->_has_role_and($args[1]);
        }
        elsif ($args[0] eq '-or') {
            $self->_has_role_or($args[1]);
        }
        else {
            $self->_has_role_and(\@args);
        }
    }
}

=head2 $bool = check_status($status)

When the status has been user is $status, returns TRUE.

=cut

sub check_status {
    my $self = shift;
    my ($status) = @_;
    return $self->{user}{status} == $status || FALSE;
}

=head2 $value = get($field)

Accessor of the value of user table.
$field is user table's field name.

=cut

sub get {
    my $self = shift;
    my ($field) = @_;
    return $self->{user}{$field};
}

=head2 $id = id()

Getter for id field.

=cut

sub id {
    shift->{user}{id};
}

=head2 $id = user_id()

Getter for id field.
This is the same function with id().

=cut

sub user_id {
    shift->{user}{id};
}

=head2 $userid = userid()

Getter for userid field.

=cut

sub userid {
    shift->{user}{userid};
}

=head2 $label = label()

Getter for auth controller's label

=cut

sub label {
    shift->{user}{label};
}

=head2 $status = status()

Getter for status field.

=cut

sub status {
    shift->{user}{status};
}

sub info {
    my $self = shift;
    my ($key) = @_;
    defined $key ? $self->{user}{$key} : $self->{user};
}

sub set_label {
    my $self = shift;
    $self->{user}{label} = shift;
}

sub label_is {
    my $self = shift;
    $self->{user}{label} eq shift;
}

sub _has_role_and {
    my $self = shift;
    my ($args) = @_;

    my $r = $self->{roles};
    for (@$args) {
        $r->{$_} or return FALSE;
    }

    return TRUE;
}

sub _has_role_or {
    my $self = shift;
    my ($args) = @_;

    my $r = $self->{roles};
    for (@$args) {
        $r->{$_} and return TRUE;
    }

    return FALSE;
}

sub login_mode {
    my $self = shift;
    my ($mode) = @_;
    defined $mode and $self->{login_mode} = $mode;
    return $self->{login_mode};
}

sub login_mode_is {
    my $self = shift;
    my ($mode) = @_;
    return $self->{login_mode} eq $mode ? TRUE : FALSE;
}

1;

=head1 SEE ALSO

Wiz::Auth

=head1 AUTHOR

Egawa Takashi, C<< <egawa.takashi@adways.net> >>
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
