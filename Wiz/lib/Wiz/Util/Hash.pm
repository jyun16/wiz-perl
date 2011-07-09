package Wiz::Util::Hash;

use strict;
use warnings;

no warnings 'uninitialized';

=head1 NAME

Wiz::Util::Hash

=head1 VERSION

version 1.0

=cut

our $VERSION = '1.0';

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut

use Clone qw(clone);
use Tie::Hash::Indexed;

use Wiz::Constant qw(:common);
use Wiz::Util::Array qw(array_equals args2array);

=head1 EXPORTS

 hash_equals
 hash_keys
 hash_keys_format
 hash_swap
 hash_contains_value
 hash_access_by_list
 args2hash
 create_ordered_hash
 array2ordered_hash
 override_hash
 hash_anchor_alias
 convert_interactive_hash
 hash_relatively_access
 cleanup_interactive_hash

=cut

use Wiz::ConstantExporter [qw(
    hash_equals
    hash_keys
    hash_keys_format
    hash_swap
    hash_contains_value
    hash_access_by_list
    args2hash
    create_ordered_hash
    array2ordered_hash
    override_hash
    hash_anchor_alias
    convert_interactive_hash
    hash_relatively_access
    cleanup_interactive_hash
)]; 

=head1 FUNCTIONS

=head2 $bool = hash_equals($hash1, $hash2)

Returns TRUE when $hash1 equals $hash2.

=cut

sub hash_equals {
    my ($hash1, $hash2) = @_;

    my @key1 = sort keys %$hash1;
    my @key2 = sort keys %$hash2;

    array_equals(\@key1, \@key2) or return FALSE;

    for (@key1) { $hash1->{$_} ne $hash2->{$_} and return FALSE; }
    return TRUE;
}

=head2 @keys or \@keys = hash_keys($hash, $value)

Returns an array that contains values matched the $value in the $hash.

=cut

sub hash_keys {
    my ($hash, $value) = @_;

    my @keys = ();
    for (keys %$hash) { $hash->{$_} eq $value and push @keys, $_; }
    return wantarray ? @keys : \@keys;
}

=head2 $hash = hash_keys_format($method, $hash)

Returns hash formated key at $method.
$method is Wiz::Util::String's format method.
camel2normal normal2camel pascal2normal normal2pascal...
or define method yourself.

=cut

sub hash_keys_format {
    my $format_method = shift;
    my $hash = args2hash(@_);
    return { map { $format_method->($_), $hash->{$_ }} keys %$hash };
}

=head2 $hash = hash_swap($hash)

Returns hash reversed key and value.
When $hash has same values, the value is overwrited.

=cut

sub hash_swap {
    my $hash = args2hash(@_);
    return { map { $hash->{$_}, $_ } keys %$hash };
}

=head2 $bool = hash_contains_value($hash, $value)

Returns TRUE when the $hash has the $value as value.

=cut

sub hash_contains_value {
    my ($hash, $value) = @_;
    for (values %$hash) { $_ eq $value and return TRUE; }
    return FALSE;
}

=head2 $hash = hash_access_by_list($hash, $list, $value, $push_mode)

Accesses for a hash value by a list.

 my $hash = {
     foo    => {
         bar    => 'blah',
     },
 }

In the case,

 hash_access_by_list($hash, [qw(foo bar)]);

Execute the above code, then it returns 'blah'.

If $push_mode is TRUE:

 my $hash = {
     foo    => {
         bar    => 'blah',
     },
 }
 hash_access_by_list($hash, [qw(foo bar)], 'FOO');
 hash_access_by_list($hash, [qw(foo bar)], 'BAR');

then

 {
     foo    => {
         bar    => ['FOO', 'BAR']
     },
 }

=cut

sub hash_access_by_list {
    my ($hash, $list, $value, $push_mode) = @_;
    my $d = shift @$list;
    if (defined $d) {
        if (defined $value and @$list < 1) {
            if ($push_mode) {
                if (defined $hash and defined $hash->{$d} and ref $hash->{$d} ne 'ARRAY') {
                    $hash->{$d} = [ $hash->{$d} ];
                }
                push @{$hash->{$d}}, $value;
            }
            else {
                $hash->{$d} = $value;
            }
            return $value;
        }
        else {
            return hash_access_by_list($hash->{$d}, $list, $value, $push_mode);
        }
    }
    else {
        return $hash;
    }
}

=head2 $args = args2hash(@args)

An array reference, a hash reference or a hash are converted into a hash reference.

=cut

sub args2hash {
    my $ref = ref $_[0];
    if ($ref eq 'ARRAY') { return { @{$_[0]} }; }
    elsif ($ref eq 'HASH') { return $_[0]; }
    else { return @_ > 1 ? { @_ } : $_[0]; }
}

=head2 $ordered_hash = create_ordered_hash()

=cut

sub create_ordered_hash {
    tie my %hash, 'Tie::Hash::Indexed';
    return \%hash;
}

=head2 $ordered_hash = array2ordered_hash($array);

=cut

sub array2ordered_hash {
    my $args = args2array(@_);

    my $hash = create_ordered_hash;
    my $n = @$args;
    for (my $i = 0; $i < $n; $i += 2) {
        $hash->{$args->[$i]} = $args->[$i+1];
    }

    return $hash;
}


=head2 $original_hash = override_hash($original_hash, $override_hash)

Merges two hashes up to deep level.
If two hashes have the same key, the value of $original_hash is overridden
with the one of $override_hash.

CAUTION: The content of $original_hash is changed.

=cut

sub override_hash {
    my ($original, $override) = @_;

    if (ref $original eq 'HASH') { 
        for (keys %{$override}) {
            if (ref $override->{$_} eq 'HASH') {
                defined $original->{$_} or $original->{$_} = {};
                %{$override->{$_}} or $original->{$_} = {};
                override_hash($original->{$_}, $override->{$_});
            }
            else { $original->{$_} = $override->{$_}; }
        }
    }
    return $original;   
}

=head2 $hash = hash_anchor_alias(%hash or \%hash)

Activate anchor and alias mechanism like the YAML.

 {
     &user1   => {
         name    => 'USER-1',
     },
     &user2   => {
         name    => 'USER-2',
     },
     users   => [ *user1, *user2 ],
     '&sub'  => sub {
         return 'hoge';
     },
     'sub2' => '*sub',
 }

The above value is changed as the following by this method.

 {
     user1   => {
         name    => 'USER-1',
     },
     user2   => {
         name    => 'USER-2',
     },
     users   => [
         user1   => {
             name    => 'USER-1',
         },
         user2   => {
             name    => 'USER-2',
         },
     ],
     'sub'  => sub {
         return 'hoge';
     },
     'sub2' => sub {
         return 'hoge';
     }
 }

When this method recieve a hash reference, itself is changed.

If you want to override hash, write the following.

 {
     '&parent'           => {
         name    => 'NAME',
         options => [qw(opt1 opt2)],
     },
     '*child:parent'    => {
         name    => 'OVERRIDDEN',
     },
 }

then it changed to

 {
     'parent'    => {
         name    => 'NAME',
         options => [qw(opt1 opt2)],
     },
     'child'     => {
         name    => 'OVERRIDDEN',
         options => [qw(opt1 opt2)],
     },
 }

=cut

sub hash_anchor_alias {
    my $hash = args2hash(@_);

    my %anchors = ();
    _create_anchors($hash, \%anchors);
    _apply_alias($hash, \%anchors);
    _apply_inheritance($hash, \%anchors);
    return $hash;
}

sub _create_anchors {
    my ($hash, $anchors) = @_;

    for (keys %$hash) {
        my $r = ref $hash->{$_};
        if ($r) {
            $r eq 'HASH' and _create_anchors($hash->{$_}, $anchors);
        }
        if (/^&(.*)/) {
            $hash->{$1} = $hash->{$_};
            $anchors->{$1} = $hash->{$_};
            delete $hash->{$_};
        }
    }
}

sub _apply_alias {
    my ($hash, $anchors) = @_;

    for (keys %$hash) {
        my $r = ref $hash->{$_};
        if ($r eq 'HASH') {
            _apply_alias($hash->{$_}, $anchors);
        }
        elsif ($r eq 'ARRAY') {
            for (@{$hash->{$_}}) {
                /^\*(.*)/ or next;
                exists $anchors->{$1} or next;
                $_ = $anchors->{$1};
            }
        }
        else {
            if ($hash->{$_} =~ /^\*(.*)/) {
                if (exists $anchors->{$1}) {
                    $hash->{$_} = $anchors->{$1};
                }
            }
        }
    }
}

sub _apply_inheritance {
    my ($hash, $anchors) = @_;

    for my $key (keys %$hash) {
        if (ref $hash->{$key} eq 'HASH') {
            _apply_inheritance($hash->{$key}, $anchors);
        }
        if ($key =~ /^\*(.*?:.*)/) {
            my @keys = reverse split /:/, $1;
            my $ret = {};
            $hash->{pop @keys} = $ret;
            for (@keys) {
                defined $anchors->{$_} or last;
                defined $ret or $ret = clone $anchors->{$_};
                $ret = override_hash($ret, $anchors->{$_});
            }
            $ret = override_hash($ret, $hash->{$key});
            delete $hash->{$key};
        }
    }
    return $hash;
}

sub convert_interactive_hash {
    my ($hash) = args2hash(@_);
    for (keys %$hash) {
        _convert_interactive_hash($hash, $hash->{$_});
    }
}

sub _convert_interactive_hash {
    my ($parent, $hash) = @_;
    if (ref $hash eq 'HASH') {
        for (keys %$hash) {
            _convert_interactive_hash($hash, $hash->{$_});
        }
        $hash->{__parent_hash__} = $parent;
    }
}

sub cleanup_interactive_hash {
    my ($hash) = args2hash(@_);
    delete $hash->{__parent_hash__};
    for (keys %$hash) {
        if (ref $hash->{$_} eq 'HASH') {
            cleanup_interactive_hash($hash->{$_});
        }
    }
}

sub hash_relatively_access {
    my ($hash, $path) = @_;

    my @path = split /\//, $path;
    my $ret = $hash;
    while (my $p = shift @path) {
        if ($p eq '..') { $ret = $ret->{__parent_hash__}; }
        elsif ($p ne '.') { $ret = $ret->{$p}; }
    }
    return $ret;
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
