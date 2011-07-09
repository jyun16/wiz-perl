package Wiz::ConstantMapExporter;

use strict;

=head1 NAME

Wiz::ConstantMapExporter

=head1 VERSION

version 1.0

=cut

=head1 SYNOPSIS

 Constant Values Package

    package HogeConstant;

    use Wiz::ConstantMapExporter {
        hoge    => {
            HOGE_CONST1 => 1,
            HOGE_CONST2 => 2,
            HOGE_CONST3 => 3,
        },
        fuga    => {
            FUGA_CONST1 => 1,
            FUGA_CONST2 => 2,
            FUGA_CONST3 => 3,
        },
    };

 Package to use constant

    package ConstantTest;

    use Wiz::Dumper;
    use HogeConstant qw(:hoge :fuga);

    sub hoge {
        wd wcm('hoge');
        print HOGE_CONST1 . "\n";
        print HOGE_CONST2 . "\n";
        print HOGE_CONST3 . "\n";
    }

    sub fuga {
        wd wiz_constant_map('fuga');
        print FUGA_CONST1 . "\n";
        print FUGA_CONST2 . "\n";
        print FUGA_CONST3 . "\n";
    }

=cut

sub import {
    shift;
    no strict 'refs';
    my $pkg_ex = (caller)[0];
    ${$pkg_ex::__CONST_MAP__} = $_[0];
    *{$pkg_ex . '::import'} = sub {
        shift;
        my $pkg_im = (caller)[0];
        my $map = ${$pkg_ex::__CONST_MAP__};
        for (@_) {
            if (my @r = $_ =~ /^:(.*)/) {
                my $m = $map->{$r[0]};
                for (keys %$m) {
                    my $v = $m->{$_};
                    *{"${pkg_im}::$_"} = sub { $v; }
                }
            }
        }
        *{"${pkg_im}::wcm"} = *{"${pkg_im}::wiz_constant_map"} = sub {
            my $k = shift;
            defined $k ? $map->{$k} : $map;
        };
    };
}

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
