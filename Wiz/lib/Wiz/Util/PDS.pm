package Wiz::Util::PDS;

use strict;

=head1 NAME

Wiz::Util::PDS

=head1 VERSION

version 1.0

=cut

our $VERSION = '1.0';

use base qw(Exporter);

our @EXPORT = qw(
    load_pds
);

use Carp;
use Devel::Symdump;

sub load_pds {
    my ($pkg, $dir) = @_;
    my $data = "package $pkg;\n\n";
    $data .= <<'EOS';
use Clone qw(clone);
use Wiz::Dumper;

sub copy_conf {
    my $map = shift;
    return { map {
        $_ => clone $map->{$_}
    } @_ };
}

EOS
    _load_pds($dir, \$data);
    $data .= "\n1;";
    my %ret;
    {
        no strict;
        no warnings;
        eval $data;
        if ($@) { warn $data; confess $@;  }
        my $p = new Devel::Symdump($pkg);
        my %funcs = map { /::([^:]*)$/; $1 => 1 } $p->functions;
        for (qw(BEGIN CHECK INIT END)) { $funcs{$_} = 1; }
        my %syms = %{$pkg . '::'};
        for (keys %syms) {
            $funcs{$_} and next;
            $ret{$_} = ${"${pkg}::$_"};
        }
    }
    return \%ret;
}

sub _load_pds {
    my ($dir, $r_data) = @_;
    my @files = ();
    opendir my $d, $dir or confess "Can't open directory $dir ($!)";
    for my $p (grep !/^\.\.?/, readdir($d)) {
        if (-d "$dir/$p") {
            _load_pds("$dir/$p", $r_data);
        }
        elsif ($p =~ /\.pds$/) {
            push @files, "$dir/$p";
        }
    }
    closedir $d;
    for (sort @files) {
        open my $f, '<', "$_" or confess "Can't open file $_ ($!)";
        while (my $l = <$f>) { $$r_data .= $l; }
        close $f;
    }
}

# ----[ private static ]----------------------------------------------

=head1 AUTHOR

Junichiro NAKAMURA, C<< <jyun16@gmail.com> >>

=head1 COPYRIGHT & LICENSE

Copyright 2008,2011 The Wiz Project. All rights reserved.

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

