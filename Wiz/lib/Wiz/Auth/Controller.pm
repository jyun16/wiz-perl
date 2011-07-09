package Wiz::Auth::Controller;

use strict;

=head1 NAME

Wiz::Auth::Controller

=head1 VERSION

version 1.0

=cut

our $VERSION = '1.0';

=head1 SYNOPSIS

 my $ac = new Wiz::Auth::Controller({
     authz   => {
         default => {
             use_delete_flag => 1,
             user_role       => 1,
             password_type   => 'sha512_base64',
             table_names    => {
                 user    => 'member',
             },
         },
         admin   => {
             user_role   => 1,
             prefix      => 'adm_',
             password_type   => 'sha512_base64',
             tables          => {
                 table_names    => {
                     user   => 'admin_member',
                     role   => 'admin_role',
                     user_authz    => 'admin_member_role',
                 },
             },
         }
     },
 });

 my $auth = $ac->auth('default');

or 

 my $auth = $ac->auth;

$auth is Wiz::Auth's instance.
The config is the following.

 use_delete_flag => 1,
 user_role       => 1,
 password_type   => 'sha512_base64',
 table_names    => {
     user    => 'member',
 },

 my $auth_admin = $ac->auth('admin');

The config is: 

 admin   => {
     user_role   => 1,
     prefix      => 'adm_',
     password_type   => 'sha512_base64',
     table_names    => {
         user   => 'admin_member',
         role   => 'admin_role',
         user_authz    => 'admin_member_role',
     },
 }

$auth_admin object is used for admin's authorization.

=cut

use Wiz qw(get_hash_args);
use Wiz::Auth;
use Wiz::Constant qw(:all);

sub new {
    my $self = shift;
    my $args = get_hash_args(@_);

    my $authz = $args->{authz};
    if (defined $authz) {
        for my $c (@Wiz::Auth::CONFS) {
            for my $l (keys %{$authz}) {
                if (defined $args->{$c}) {
                    defined $authz->{$l}{$c} or
                        $authz->{$l}{$c} = $args->{$c};
                }
            }
        }
    }
    else {
        my %args = %$args;
        $args = {};
        $args->{authz}{default} = \%args;
    }

    return bless { conf => $args, authz => {}, cluster => $args->{cluster} }, $self;
}

=head2 $conf = conf($label);

Returns config data by authz label.

=cut

sub conf {
    my $self = shift;
    my ($label)  = @_;
    $label ||= 'default';
    return $self->{conf}{authz}{$label};
};


=head2 $auth = auth($label, $db_label)

Returns Wiz::Auth object.

=cut

sub auth {
    my $self = shift;
    my ($label, $db_label) = @_;

    $label ||= 'default';
    $db_label ||= $label;

    my $conf = $self->{conf}{authz}{$label};
    defined $self->{cluster} and $conf->{db} =
        $self->{cluster}->get_slave($db_label);
    $conf->{label} ||= $label;
    return new Wiz::Auth($conf);
}

sub session_key {
    my $self = shift;
    my ($label) = @_;
    $label ||= 'default';
    my $conf = $self->{conf}{authz}{$label};
    my $key = $self->{conf}{authz}{session_key_prefix} || 'unknown';
    if ($conf->{session_key}) { $key .= '_' . $conf->{session_key}; }
    if ($conf->{session_key_prefix}) { $key .= '_' . $conf->{session_key_prefix} . '_' . $label; }
    else { "${key}_auth_session"; }
}

1;

=head1 SEE ALSO

L<Wiz::Auth>

=head1 AUTHOR

Junichiro NAKAMURA, C<< <jyun16@gmail.com> >>

=head1 COPYRIGHT & LICENSE

Copyright 2008, 2010 The Wiz Project. All rights reserved.

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
