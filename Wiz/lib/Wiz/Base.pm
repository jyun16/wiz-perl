package Wiz::Base;

use Wiz qw/get_hash_args/;
use base qw(Class::Accessor::Fast);
use Clone qw(clone);

=head1 NAME

Wiz::Base

=head1 VERSION

version 1.0

=cut

our $VERSION = '1.0';

=head1 SYNOPSIS

 package YourClass;
 
 use base qw/Wiz::Base/;
 
 # YOU MUST CALL _set_default METHOD!!!
 __PACKAGE__->_set_default(
    dest_url         => undef,
    form_name        => 'form',
    method           => 'post',
    js_function_name => 'jumpPage',
    added_js         => [],
 );

 package YourClass::Extended;
 
 use base qw/YourClass/;
 
 # This module default value is as same as YourClass
 # except "dest_url".
 # "dest_url" is overrided by the following.
 __PACKAGE__->_set_default(
    dest_url => 'http://example.com/',
 );

 package YourClass::Extended2;
 
 use base qw/YourClass::Extended/;
 
 # This module defualt value is as same as YourClass::Extended

=head1 DESCRIPTION

This module provides C<new> and C<_set_default>.
General constructor and default implementation.

This class is only for being inherited.

=cut

=head2 new(%option)

=cut

sub new {
    my $self = shift;
    my $args = get_hash_args(@_);

    my $default = $self->_default;
    my $instance = bless {}, $self;
    for (keys %$default) {
        if (exists $args->{$_}) {
            $instance->{$_} = $args->{$_};
        } else {
            $instance->{$_} = $default->{$_};
        }
    }

    return $instance;
}


=head2 _set_default(%default)

It sets default values and set its keys as accessor.
Wiz::Web::Base's default is used as default value.
%default has same key, it is used as default value.
And C<_default> method is automatically defined in same time,
which can get default hash ref.

For example:

If you use _set_default as the follwoig.

 __PACKAGE__->_set_default(
     dest_url         => undef,
     form_name        => 'form',
     method           => 'post',
     js_function_name => 'jumpPage',
     added_js         => [],
 );

In same time, _default method is automatically defined.

 __PACKAGE__->_default;

 {
     dest_url         => undef,
     form_name        => 'form',
     method           => 'post',
     js_function_name => 'jumpPage',
     added_js         => [],
 }

The following is actual example;

C<<Wiz::Web::Base->_default>>;

 {
     dest_url         => '',
     form_name        => 'form',
     method           => 'post',
     js_function_name => 'jumpPage',
     added_js         => [],
 };

In another class;

 use base qw/Wiz::Web::Base/;
 
 __PACKAGE__->_set_default({form_name => 'hoge', method => 'GET'});

The default value of the class is like this:

 {
     dest_url         => '',
     form_name        => 'hoge',
     method           => 'GET',
     js_function_name => 'jumpPage',
     added_js         => [],
 }

=cut

sub _set_default {
    my $class = shift;
    if (my $default = get_hash_args(@_)) {
        my %default = $class->can('_default') ? %{$class->_default} : ();
        foreach my $key (keys %default) {
            $default->{$key} = $default{$key}
                if not defined $default->{$key};
        }
        no strict 'refs';
        *{$class . '::_default'} = sub { clone $default };
        __PACKAGE__->mk_accessors(keys %$default);
    }
}

=head1 AUTHOR

Kato Atsushi C<< <KTAT@cpan.org> >>

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

