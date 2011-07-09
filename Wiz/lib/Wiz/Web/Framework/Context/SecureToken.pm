package Wiz::Web::Framework::Context::SecureToken;

=head1 NAME

Wiz::Web::Framework::Context::SecureToken - embedding & checking one time token

=head1 VERSION

version 1.0

=cut

our $VERSION = '1.0';

=head1 SYNOPSIS

Exapmle 1:

 sub input {
   # ...
   $c->embed_token;
 }
 
 sub confirm {
     # ...
     if (my $session = $c->token_session) {
         # success
     } else {
         # error
     }
  }
 
 sub regist {
     # ...
     if (my $session = $c->token_session) {
         # success
         # ...
         $c->remove_token_session;
     } else {
         # error
     }
  }

Exapmle 2:

 sub input {
   # ...
   $c->embed_token_single($session_name);
 }
 
 sub confirm {
     # ...
     if (my $session = $c->token_session_single($session_name)) {
         # success
     } else {
         # error
     }
  }
 
 sub regist {
     # ...
     if (my $session = $c->token_session($session_name)) {
         # success
         delete $c->session->{$session_name};
     } else {
         # error
     }
 }

=head1 DESCRIPTION

This provides one time token against CSRF etc.
Basic strategy is the following;

 [  input page  ] <-- embed token to hidden and session
        |
 [ confirm page ] <-- check tokens & embed token to hidden
        |
 [  regist page ] <-- check tokens & remove session

This has 2 kind of tokens.

=head2 multiple one time tokens for multiple process

You can allow users to open multiple windows.

 [  input page  ] <-- $c->embed_token;
        |             <input type="hidden" name="secure_token" value="SeCuReToKeN">
        |             $c->session->{__secure_token_session__}->{"SeCuReToKeN"} = ...
        |             the above session is in $c->{stash}->{secure_token_session}
        |
 [ confirm page ] <-- $c->token_session;
        |             It returns $c->session->{__secure_token_session__}->{"SeCuReToKeN"}
        |             If 0 is returned, invalid access.
        |
 [  regist page ] <-- same as the above
                      $c->remove_token_session
=head2 one time token for one process

If users use multiple window and your application can ignore all other page
except the most latest window(for example wiki), you can use this type token.

 [  input page  ] <-- $c->embed_token($session_name);
        |             <input type="hidden" name="secure_token" value="SeCuReToKeN">
        |             $c->session->{$session_name}->{secure_token} = "SeCuReToKeN"
        |
 [ confirm page ] <-- $c->token_session($session_name);
        |             check whether $c->req->param('secure_token') is equal to
        |             $c->session->{$session_name}->param('secure_token')
        |
 [  regist page ] <-- same as the above

C<secure_token> is default name. You can change it by configuration.

=head2 In Template

C<secure_token>, C<secure_token_tag> and C<token_session> can be used.
If you want to change these names, you can change them by configuration.

If you use secure_token, use as the following;

 <input type="hidden" name="secure_token" value="[% secure_token %]">

If you use secure_token_tag, use as the following;

 [% secure_token_tag %]

This outputs hidden tag as the above.

You can also use token session in template.

 [% token_session.key %]

=head1 METHODS

The following methods take $session_names.

If you pass ['admin', 'bbs'], it means:

 $c->session->{admin}->{bbs}

If you pass 'admin', it means:

 $c->session->{admin}

=head2 embed_token

It embeds one time token for multi window process.

You can pass $session_names as optional.
If you want controll sessions for specified process,
you should set $session_names.

 $c->embed_token($session_names);

=head2 set_token_expire($expire)

You can set token session's expire(default expire time is 86400).
If you use $session_names when embedding session, you must pass $session_names.

 $c->set_token_expire($session_names, $expire);

=head2 token_session

If ok, it returns session for this process. If NG, it returns 0.
If you use $session_names when embedding session, you must pass $session_names.

 $c->token_session($session_names);

=head2 remove_token_session

It remove token session.
You have to call it when the process is finished.

If you use $session_names when embedding session, you must pass $session_names.

 $c->remove_token_session($session_names);

=head2 embed_token_single($session_names)

It embeds one time token for single window process.

=head2 $session = token_session_single($session_names)

If ok, it returns session for this process.
If ng, it returns 0.

=head1 Automaticaly set token into stash

If reqest parameter has token and stash doesn't have token,
this module automaticaly set the token into stash in finalize.

=head1 Configuration

In conf/secure_token.yml;

 token_name: token
 token_session_name: t_session
 token_expire: 3600

default value is;

 token_name: secure_token
 token_session_name: secure_token_session
 token_expire: 86400

=head1 AUTHOR

=cut

use Digest::MD5;
use Class::Inspector;

use constant DEFAULT_EXPIRE_TIME => 86400;
use constant SECURE_TOKEN_SESSION_NAME => '__secure_token_session__';

my $USE_ADWAYS_SESSION;

our @PUBLIC_FUNCTIONS = qw(
    token_session_single
    embed_token
    embed_token_single
    token_session
    remove_token_session
    secure_token_name
);

sub init_conf {
    my ($conf) = @_;
    $conf->{token_name}         ||= 'secure_token';
    $conf->{token_expire}       ||= DEFAULT_EXPIRE_TIME;
    $conf->{token_session_name} ||= 'secure_token_session';
    $USE_ADWAYS_SESSION = Class::Inspector->loaded('Catalyst::Plugin::Wiz::Session') || 0;
}

sub token_session_single {
    my ($c, $session_names) = @_;
    my $session = _secure_token_get_session($c, $session_names);
    my $token_name   = secure_token_name($c);
    my $secure_token = $c->req->param($token_name);
    _secure_token_to_stash($c, $secure_token);
    return (not $secure_token or $session->{$token_name} ne $secure_token) ? 0 : $session
}

sub embed_token {
    my ($c, $session_names) = @_;
    my $session = _secure_token_get_session($c, $session_names);
    my $token = _secure_token_create();
    $c->stash->{_secure_token_session_name($c)} = $session->{SECURE_TOKEN_SESSION_NAME()}->{$token} = {};
    _secure_token_to_stash($c, $token);
    return $token;
}

sub embed_token_single {
    my ($c, $session_names) = @_;
    my $session = _secure_token_get_session($c, $session_names);
    my $token_name = secure_token_name($c);
    _secure_token_to_stash($c, $session->{$token_name} = _secure_token_create());
}

sub token_session {
    my ($c, $session_names) = @_;
    my $session = _secure_token_get_session($c, $session_names);
    my $token_name = secure_token_name($c);
    my $secure_token = $c->req->param($token_name);
    my $token_session;
    my $token_session_name = _secure_token_session_name($c);
    if ($c->stash->{secure_token_name($c)}) {
        return $session->{SECURE_TOKEN_SESSION_NAME()}->{$c->stash->{secure_token_name($c)}};
    }
    elsif (defined $secure_token and
        defined $session->{SECURE_TOKEN_SESSION_NAME()}->{$secure_token}
       ) {
        $token_session = $session->{SECURE_TOKEN_SESSION_NAME()}->{$secure_token};
        $c->stash->{$token_session_name} = $token_session;
        _secure_token_to_stash($c, $secure_token);
        return $token_session;
    }
    elsif ($c->app_conf('secure_token')->{force_token_session}) {
        $token_session = $c->stash->{secure_token_session_name($c)};
        return defined $token_session ? $token_session : 0;
    }
}

sub remove_token_session {
    my ($c, $session_names) = @_;
    my $session = _secure_token_get_session($c, $session_names);
    my $token_name = secure_token_name($c);
    my $token = $c->req->param($token_name);
    return delete $session->{SECURE_TOKEN_SESSION_NAME()}->{$token};
}

sub secure_token_name {
    my $c = shift;
    return $c->app_conf('secure_token')->{token_name};
}

sub _secure_token_to_stash {
    my ($c, $token) = @_;
    my $token_name = secure_token_name($c);
    $c->stash->{$token_name} = $token;
    $c->stash->{$token_name . '_tag'} = sprintf '<input type="hidden" name="%s" value="%s">', $token_name, $token;
}

sub set_token_expire {
    my $c = shift;
    my ($session_names, $expire) = @_ > 1 ? @_ : (undef, $_[0]);
    my $token_name    = secure_token_name($c);
    my $secure_token  = $c->req->param($token_name) || $c->stash->{$token_name};
    return 0 if not defined $secure_token or not $secure_token;
    return _secure_token_set_token_expire($c, $session_names, $secure_token, $expire);
}

sub _secure_token_set_token_expire {
    my ($c, $session_names, $secure_token, $expire) = @_;
    my @session_names = (SECURE_TOKEN_SESSION_NAME, $secure_token);
    if (ref $session_names) {
        unshift @session_names, @$session_names;
    } elsif (defined $session_names and $session_names) {
        unshift @session_names, $session_names;
    }
    if ($USE_ADWAYS_SESSION) {
        my $expire_setting = {};
        my $copy = $expire_setting;
        my $parent;
        foreach (@session_names) {
            $parent = $copy;
            $copy = $copy->{$_} = {}
        }
        $parent->{$session_names[$#session_names]}
            = ($expire || $c->app_conf('secure_token')->{expire_time} || DEFAULT_EXPIRE_TIME);
        $c->session_expire_key($expire_setting);
    } elsif (my $first_session_name = shift @session_names) {
        $c->session_expire_key($first_session_name => $expire || DEFAULT_EXPIRE_TIME);
    }
    return 1;
}

sub _secure_token_create {
    shift;
    return Digest::MD5::md5_hex(Digest::MD5::md5_hex(time() . (join "", {} x 10) . rand()));
}

sub _secure_token_session_name {
    my $c = shift;
    return $c->app_conf('secure_token')->{token_session_name};
}

sub _secure_token_get_session {
    my $c = shift;
    my $s = $c->session;
    my $session_names = shift;
    if (defined $session_names and $session_names) {
        foreach my $name (ref $session_names ? @$session_names : $session_names) {
            $s = $s->{$name} ||= {};
        }
    }
    return $s;
}

sub finalize {
    my $c = shift;
    my $token_name = secure_token_name($c);
    if (
        not defined $c->stash->{$token_name} and
        my $token = $c->req->param($token_name)
       ) {
        _secure_token_to_stash($c, $token)
    }
}

=head1 AUTHOR

Junichiro NAKAMURA, C<< <jyun16@gmail.com> >>
[base]Kato Atsushi, C<< <kato@adways.net> >>

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


