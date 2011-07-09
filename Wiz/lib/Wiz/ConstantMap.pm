package Wiz::ConstantMap;

use strict;

use Carp;

use Wiz::Util::Hash qw(hash_keys hash_swap);

=head1 NAME

Wiz::ConstantMap - Exports hash value in convenient way. 

=head1 VERSION

version 1.0

=cut

our $VERSION = '1.0';

=head1 SYNOPSIS

 package Fruit;
 use Wiz::ConstantMap {
    grape   => 'violet',
    melon   => 'green',
    banana  => 'yellow',
 }, 'fruit';

in another script...

 use Fruit qw(:fruit);
 my $grape_color = fruit_map->{'grape'};
 my $yellow_fruit = fruit_swap_key('yellow');

=head1 DESCRIPTION

Utility for preparing a constant map and using it.

It contains methods manipulating not only an original map,
but also its swapped map, that is, a map in which keys and values are all swapped.

Now we call the original map as $map, and the swapped map as $swap_map. 


=head1 EXPORTS

=cut

use base qw(Exporter);

our @EXPORT_SUB = qw();
our @EXPORT_CONST = qw();
our @EXPORT_OK = (@EXPORT_SUB, @EXPORT_CONST);

our %EXPORT_TAGS = (
    'sub'       => \@EXPORT_SUB,
    'const'     => \@EXPORT_CONST,
    'all'       => \@EXPORT_OK,
);

=head1 USE OPTION

Export hash value with specified name.

 use Wiz::ConstantMap(\%hash, $name);

=head1 FUNCTIONS

=cut

my $use_map_swap_limit = 9;

sub import {
    my $this = shift;
    my ($const, $name) = @_; 
    ref $const eq 'HASH' or confess 'const data is not hash reference.';

    no strict 'refs';

    my @caller = caller;
    my $pkg = $caller[0];

    for my $k (keys %$const) {
        *{ sprintf '%s::%s', $pkg, $k } = sub { my $val = $const->{$k}; return $val; };
    }

    *{ sprintf '%s::__%s_swap_const__', $pkg, $name } = \(hash_swap $const);

=head2 \%map cm_map()

Returns $map.

=cut

    *{ sprintf '%s::%s_map', $pkg, $name } = sub { 
        return $const; 
    };

=head2 \%map cm_swap_map()

Returns $swap_map

=cut

    if (keys %$const > $use_map_swap_limit) {
        *{ sprintf '%s::%s_swap_map', $pkg, $name } = sub {
            return eval sprintf '$%s::__%s_swap_const__', $pkg, $name;
        };
    }
    else {
        *{ sprintf '%s::%s_swap_map', $pkg, $name } = sub {
            return hash_swap $const;
        };
    }

=head2 @keys cm_keys()

Returns all keys in $map.

=cut

    *{ sprintf '%s::%s_keys', $pkg, $name } = sub {
        return wantarray ? keys %$const : [ keys %$const ];
    };

=head2 @values cm_values()

Returns all values in $map.

=cut

    *{ sprintf '%s::%s_values', $pkg, $name } = sub {
        return wantarray ? values %$const : [ values %$const ];
    };

=head2 @keys cm_swap_keys()

Returns all keys in $swap_map.

=cut

    *{ sprintf '%s::%s_swap_keys', $pkg, $name } = sub {
        my $swap_map = eval sprintf '%s::%s_swap_map', $pkg, $name;
        return wantarray ? keys %$swap_map : [ keys %$swap_map ];
    };

=head2 @values cm_swap_values()

Returns all values in $swap_map.

=cut

    *{ sprintf '%s::%s_swap_values', $pkg, $name } = sub {
        my $swap_map = eval sprintf '%s::%s_swap_map', $pkg, $name;
        return wantarray ? values %$swap_map : [ values %$swap_map ];
    };

=head2 $key cm_key($value)

Returns a key which has $value as its value in $map.

=cut

    *{ sprintf '%s::%s_key', $pkg, $name } = sub {
        my @keys = hash_keys $const, shift;
        return wantarray ? @keys : [ @keys ];
    };

=head2 $value cm_value($key)

Returns a value of the $key in $map.

=cut

    *{ sprintf '%s::%s_value', $pkg, $name } = sub {
        my $key = shift;
        return exists $const->{$key} ? $const->{$key} : undef;
    };

=head2 $key cm_swap_key($value)

Returns a key which has $value as its value in $swap_map.

=cut

    *{ sprintf '%s::%s_swap_key', $pkg, $name } = sub {
        my $value = shift;
        return exists $const->{$value} ? $const->{$value} : undef;
    };

=head2 $value cm_swap_value($key)

Returns a value of the $key in $swap_map.

=cut

    *{ sprintf '%s::%s_swap_value', $pkg, $name } = sub {
        my @keys = hash_keys $const, shift;
        return wantarray ? @keys : [ @keys ];
    };
}

=head1 AUTHOR

Egawa Takashi, C<< <egawa.takashi@adways.net> >>

[Base idea & Code ] Junichiro NAKAMURA, C<< <jyun16@gmail.com> >>

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

1; # End of Wiz::ConstantMap

__END__
