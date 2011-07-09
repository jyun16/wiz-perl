package Wiz::Util::Tree;

use strict;
use warnings;

=head1 NAME

Wiz::Util::Tree

=head1 VERSION

version 1.0

=cut

our $VERSION = '1.0';

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut

use Wiz::Constant qw(:common);

=head1 EXPORTS

 search_tree
 dependency_tree

=cut

use Wiz::ConstantExporter [qw(
    search_tree
    dependency_tree
    dependency_sequence
)];

=head1 FUNCTIONS

=cut

=head2 

=cut

sub search_tree {
    my ($tree, $target) = @_;

    if (ref $tree eq 'HASH') {
        for (keys %$tree) {
            if ($_ eq $target) {
                return $tree;
            }
            else {
                my $ret = search_tree($tree->{$_}, $target);
                defined $ret and return $ret;
            }
        }
    }
    return undef;
}

=head2 

=cut

sub dependency_tree {
    my ($data) = @_;

    my $ret = {};
    for my $child (keys %$data) {
        my $m = search_tree($ret, $child);
        my $parents = $data->{$child};
        if ($m) {
            for my $parent (@$parents) {
                $m->{$child}{$parent} = {};
            }
        }
        else {
            for my $parent (@$parents) {
                my $mv = search_tree($ret, $parent);
                if ($mv) {
                    $ret->{$child}{$parent} = $mv->{$parent};
                    delete $mv->{$parent};
                }
                else {
                    $ret->{$child}{$parent} = {};
                }
            }
        }
    }
    return $ret;
}

=head2

=cut

sub dependency_sequence {
    my ($data) = @_;

    my $tree = dependency_tree($data);
    my $ret = [];
    _dependency_sequence($ret, $tree, -1);
    return [ reverse @$ret ];
}

sub _dependency_sequence {
    my ($ret, $tree, $depth) = @_;

    $depth++;
    for (keys %$tree) {
        _dependency_sequence($ret, $tree->{$_}, $depth);
    }
    if (keys %$tree) {
        push @{$ret->[$depth]}, (keys %$tree);
    }
}

=head1 AUTHOR

Junichiro NAKAMURA, C<< <jyun16@gmail.com> >>
modified by ktat C<< <ktat@gmail.com> >>

=head1 COPYRIGHT & LICENSE

Copyright 2008,2009 The Wiz Project. All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice,
self list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright
notice, self list of conditions and the following disclaimer in the
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
We welcome anyone who cooperates with us in developing self software.

We'll invite you to self project's member.

=cut

1;

__END__
