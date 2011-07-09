package Wiz::Config;

use strict;
use warnings;

no warnings 'uninitialized';

=head1 NAME

Wiz::Web::Util

=head1 VERSION

version 1.0

=cut

our $VERSION = '1.0';

use Carp;
use URI;
use File::Basename;
use JSON::Syck;
use YAML::Syck;
use XML::Simple;

use Wiz::Util::Array qw(args2array);
use Wiz::Util::Hash qw(override_hash);
use Wiz::Util::File qw(file_read2str);
use Wiz::ConstantExporter [qw(
    load_config_files
)];

# ----[ static ]------------------------------------------------------

sub load_config_files {
    my $files = args2array @_;
    my $ret = {};
    for my $f (@$files) {
        my $filename = basename $f;
        $filename =~ /\.(.*)$/;
        my $ext = $1;
        if ($ext eq 'pdat') { $ret = load_pdat($ret, $f); }
        elsif ($ext =~ /jso?n/) { $ret = load_json($ret, $f); }
        elsif ($ext =~ /ya?ml/) { $ret = load_yaml($ret, $f); }
        elsif ($ext eq 'xml') { $ret = load_xml($ret, $f); }
    }
    return ref $ret eq 'HASH' ? (keys %$ret ? $ret : undef) : ($ret);
}

sub load_pdat {
    my ($ret, $f) = @_;
    my $data = do $f;
    $@ and confess $@;
    if (ref $ret eq 'HASH') { return keys %$ret ? override_hash($ret, $data) : $data; }
    else { return $data; }
}

sub load_json {
    my ($ret, $f) = @_;
    my $data = YAML::Syck::LoadJSON(file_read2str($f));
    if (ref $ret eq 'HASH') { return keys %$ret ? override_hash($ret, $data) : $data; }
    else { return $data; }
}

sub load_yaml {
    my ($ret, $f) = @_;
    my $data = YAML::Syck::LoadFile($f);
    if (ref $ret eq 'HASH') { return keys %$ret ? override_hash($ret, $data) : $data; }
    else { return $data; }
}

sub load_xml {
    my ($ret, $f) = @_;
    my $data = XML::Simple::XMLin($f);
    if (ref $ret eq 'HASH') { return keys %$ret ? override_hash($ret, $data) : $data; }
    else { return $data; }
}

# ----[ private static ]----------------------------------------------

=head1 AUTHOR

Junichiro NAKAMURA, C<< <jyun16@gmail.com> >>

=head1 COPYRIGHT & LICENSE

Copyright 2008,2009 The Wiz Project. All rights reserved.

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

