package Wiz::Noose;

use strict;

=head1 NAME

Wiz::Noose 
=head1 VERSION

version 1.0

=cut

our $VERSION = '1.0';

use Carp qw(confess);
use Data::Util qw(subroutine_modifier modify_subroutine);

use Wiz::Dumper;
use Wiz::Util::String::UTF8 qw(hate_utf8_dumper);

=head1 SYNOPSIS

Very simple and cheap Moose.

=cut

no strict 'refs';

sub import {
    my $i_pkg = shift;
    my ($i_tpkg) = caller;
    'strict'->import;
    unshift @{"${i_tpkg}::ISA"}, 'Wiz::Noose::Constructor';
    *{"${i_tpkg}::requires"} = sub { my ($method) = @_; push @{"${i_tpkg}::__NOOSE_REQUIRES_"}, $method; };
    _create_extends($i_tpkg);
    _create_with($i_tpkg);
    _create_has($i_tpkg);
    _create_hook($i_tpkg);
    _create_warn_dumper($i_tpkg);
}

sub _create_accessor {
    my ($i_tpkg, $member) = @_;
    my $attr = ${"${i_tpkg}::__NOOSE_ACCESSOR_"}{$member};
    my $ro = $attr->{is} eq 'ro';
    *{"${i_tpkg}::$member"} = sub {
        my $self = shift;
        if (defined $_[0]) {
            if ($ro) {
                confess "$i_tpkg->$member is read only value";
            }
            else {
                $self->{$member} = $attr->{setter} ?
                    $attr->{setter}->($self, $_[0]) : $_[0];
            }
        }
        return $attr->{getter} ? $attr->{getter}->($self, $self->{$member}) : $self->{$member};
    };
}

sub _create_has {
    my ($i_tpkg) = @_;
    *{"${i_tpkg}::has"} = sub {
        my ($member, %attr) = @_;
        my $ro = $attr{is} eq 'ro';
        ${"${i_tpkg}::__NOOSE_ACCESSOR_"}{$member} = \%attr;
        $attr{required} and push @{"${i_tpkg}::__NOOSE_REQUIRED_"}, $member;
        exists $attr{default} and ${"${i_tpkg}::__NOOSE_DEFAULT_"}{$member} = $attr{default};
        _create_accessor($i_tpkg, $member);
    };
}

sub _create_with {
    my ($i_tpkg) = @_;
    *{"${i_tpkg}::with"} = sub {
        my (@pkg) = @_;
        for my $pkg (@pkg) {
            eval "require $pkg";
            $@ and die $@;
            unshift @{"${i_tpkg}::ISA"}, $pkg;
            for (@{"${pkg}::__NOOSE_REQUIRES_"}) {
                $i_tpkg->can($_) or confess qq|'$pkg' requires the method '$_' to be implemented by '$i_tpkg'|;
            }
        }
    };
}

sub _create_extends {
    my ($i_tpkg) = @_;
    *{"${i_tpkg}::extends"} = sub {
        my (@pkg) = @_;
        for my $pkg (@pkg) {
            eval "require $pkg";
            $@ and die $@;
            unshift @{"${i_tpkg}::ISA"}, $pkg;
        }
    };
}

sub _create_warn_dumper {
    my ($i_tpkg) = @_;
    *{"${i_tpkg}::wd"} = \&wd;
}

sub _create_hook {
    my ($i_tpkg) = @_;
    for my $hook (qw(before after around)) {
        my $uc_hook = uc $hook;
        *{"${i_tpkg}::$hook"} = sub {
            my ($target, $sub) = @_;
            if (${"${i_tpkg}::__${uc_hook}_"}{$target}) {
                subroutine_modifier(\&{"${i_tpkg}::$target"}, $hook => ($sub));
            }
            else {
                *{"${i_tpkg}::$target"} =
                    modify_subroutine(\&{"${i_tpkg}::$target"}, $hook => [ $sub ]);
                ${"${i_tpkg}::__${uc_hook}_"}{$target} = 1;
            }
        };
    }
}

sub BUILD {
    return @_;
}

sub BUILDARGS {
}

package Wiz::Noose::Constructor;

use Carp;
use Wiz::Dumper;
use Wiz::Util::Hash qw(args2hash);

sub _noose_init_args {
    my $pkg = shift;
    my ($args) = @_;
    for (@{"${pkg}::__NOOSE_REQUIRED_"}) {
        exists $args->{$_} or confess "$pkg->$_ is required value";
    }
    for (keys %{"${pkg}::__NOOSE_DEFAULT_"}) {
        exists $args->{$_} or $args->{$_} = ${"${pkg}::__NOOSE_DEFAULT_"}{$_};
    }
    $args;
}

sub _noose_get_isa {
    my $pkg = shift;
    my @isa = ();
    __noose_get_isa($pkg, \@isa);
    return \@isa;
}

sub __noose_get_isa {
    my $pkg = shift;
    my ($isa) = @_;
    for my $p (@{"${pkg}::ISA"}) {
        __noose_get_isa($p, $isa);
        unless (grep /$p/, @$isa) {
            unshift @$isa, $p;
        }
    }
}

sub _init_meta {
    my $pkg = shift;
    my %required = ();
    my %default = ();
    for my $p (reverse @{_noose_get_isa($pkg)}, $pkg) {
        my $def = \%{"${p}::__NOOSE_DEFAULT_"};
        my $req = \@{"${p}::__NOOSE_REQUIRED_"};
        for (keys %$def) { $default{$_} = $def->{$_}; }
        for (@$req) { $required{$_} = 1; }
    }
    %{"${pkg}::__NOOSE_DEFAULT_"} = %default;
    @{"${pkg}::__NOOSE_REQUIRED_"} = keys %required;
    ${"${pkg}::__NOOSE_FIXED_"} = 1;
}

sub new {
    my $pkg = shift;
    my $args = args2hash @_;
    unless (${"${pkg}::__NOOSE_FIXED_"}) {
        $pkg->_init_meta;
    }
    $args = $pkg->_noose_init_args($args);
    $args = $pkg->BUILDARGS(%$args) if $pkg->can('BUILDARGS');
    my $instance = bless {}, $pkg;
    for my $m (keys %$args) {
        $instance->$m($args->{$m}) if $pkg->can($m);
    }
    $instance->BUILD($args) if $pkg->can('BUILD');
    return $instance;
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
