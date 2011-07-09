package Wiz::Web::Ext;

use strict;
use warnings;

=head1 NAME

Wiz::Web::Ext

=head1 VERSION

version 1.0

=cut

our $VERSION = '1.0';

=head1 SYNOPSIS
 

=head1 DESCRIPTION

=cut

use base qw(Wiz::Web::Base);

=head1 EXPORTS

=cut

use Wiz::ConstantExporter [qw(
data_complement4async_tree
data_accessor4async_tree
)];

=head1 CONSTRUCTOR

=head1 METHODS

=head1 FUNCTIONS

=cut

use Data::Dumper;

my @NODE_FIELDS = qw(text cls leaf);

sub data_complement4async_tree {
    my ($data) = @_;
    for my $key (keys %$data) {
        my $node = $data->{$key};
        if (defined $node) {
            defined $node->{text} or $node->{text} = $key;
            $node->{cls} ||= 'file';
            $node->{cls} eq 'file' and $node->{leaf} = 1;
            $node->{children} and data_complement4async_tree($node->{children});
        }
    }
    return $data;
}

sub data_accessor4async_tree {
    my ($data, $path) = @_;

    $path ||= '/';
    if ($path eq '/') { return _create_data4async_tree($data, ''); }
    my @path = split '/', $path;
    return _data_accessor4async_tree($data, \@path, '');
}

sub _data_accessor4async_tree {
    my ($data, $paths, $parent_path) = @_;

    my $target = shift @$paths;
    my $nodes = exists $data->{children} ? $data->{children} : $data->{$target};
    if (defined $nodes) {
        if (@$paths) {
            return _data_accessor4async_tree($nodes, $paths, "$parent_path/$target");
        }
        else {
            return _create_data4async_tree($nodes, "$parent_path/$target");
        }
    }
    return undef;
}

sub _create_data4async_tree {
    my ($nodes, $path) = @_;

    if ($path ne '') {
        defined $nodes->{children} or return;
        $nodes = $nodes->{children};
    }

    my @ret = ();
    for my $key (keys %$nodes) {
        my %m = ();
        for (@NODE_FIELDS) { defined $nodes->{$key}{$_} and $m{$_} = $nodes->{$key}{$_}; }
        $m{id} = "$path/$key";
        push @ret, \%m;
    }

    return @ret ? \@ret : undef;
}

# ----[ private ]-----------------------------------------------------
# ----[ static ]------------------------------------------------------
# ----[ private static ]----------------------------------------------

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

