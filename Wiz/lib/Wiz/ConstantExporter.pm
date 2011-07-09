package Wiz::ConstantExporter;

use strict;
use warnings;

no warnings 'redefine';

=head1 NAME

Wiz::ConstantExporter - use constant values easily 

=head1 VERSION

version 1.0

=cut

our $VERSION = '1.0';

=head1 SYNOPSIS

 package MyPackage;
 use Wiz::ConstantExporter {
    APPLE    => 'red',
    BANANA   => 'yellow',
    MELON    => 'green',
 }, 'fruit';
 
 use Wiz::ConstantExporter [qw( run walk jump stop )], 'action';

in another script...

 use MyPackage qw(:fruit :action);
 
 $apple_color = APPLE;  #  'red'
 jump();                #  MyPackage::jump()


=head1 DESCRIPTION

Utility which supports exporting many constants/functions at a time.


=head2 Exporting many constants

When exporting constants, specify a hashref in which constants are defined, and an export name.

 use Wiz::ConstantExporter {
    APPLE    => 'red',
    BANANA   => 'yellow',
    MELON    => 'green',
 }, 'fruit';

When export name is omitted, it will be defined as 'const'.

=head2 Exporting many functions 

When exporting functions, specify an arrayref in which function names are defined, and an export name.

 use Wiz::ConstantExporter [qw( run walk jump stop )], 'action';

When export name is omitted, it will be defined as 'sub'.


=head2 Importing constants/functions

Constants and functions exported in a manner of previous section, can be imported by specifying export name like this.

 #  import APPLE, BANANA and MELON
 use MyPackage qw(:fruit);
 $banana_color = BANANA;
    
 #  import run, walk, jump and stop
 use MyPackage qw(:action);
 walk();

Indivisual constant/function can be also imported like this.
    
 #  import MELON only
 use MyPackage qw(MELON);
    
All constants and functions can be imported by specifying 'all' for an export name.
    
 #  import all
 use MyPackage qw(:all);    


=head2 Grouping multiple export names into a single name

We can define a single export name which groups multiple export names.

 #  export both fruit and action with one Export name 'common'
 use Wiz::ConstantExporter 'common' => [ qw(fruit action) ];
    
Now we can import all constants/functions in 'fruit' and 'action' like this.

 use MyPackage qw(:common);

=cut

sub import {
    my $self = shift;
    
    #  $export - has different meanings according to its type.  
    #               hashref  - (const)map which contains exported key-value pairs
    #               arrayref - (sub)a list of exported functions.
    #               scalar   - (alias)alias name to group several names 
    #  $name   - has different meanings according to $export
    #               hashref, arrayref - Export name
    #               scalar   - a list of grouped names
    my ($export, $name) = @_;

    no strict 'refs';

    my @caller_ex = caller;
    my $pkg_ex = $caller_ex[0];
    my $ref = ref $export;

    if ($ref eq 'HASH' ) { $name ||= 'const'; }
    elsif ($ref eq 'ARRAY') { $name ||= 'sub';   }

    my $all_export_map = ${"${pkg_ex}::__all_export_map__"};
    my $import_override = 0;
    if (not defined $all_export_map) {
        $all_export_map = {};
        *{"${pkg_ex}::__all_export_map__"} = \$all_export_map;
        $import_override = 1;
    }
    if ($ref eq 'HASH') {
        if (defined $all_export_map->{const}{$name}) {
            for (keys %$export) { $all_export_map->{const}{$name}{$_} = $export->{$_}; }
        }
        else { $all_export_map->{const}{$name} = $export; }
        for my $k (keys %$export) {
            *{"${pkg_ex}::${k}"} = sub () { my $val = $export->{$k}; return $val; }
        }
    }
    elsif ($ref eq 'ARRAY') { 
        $all_export_map->{sub}{$name} ||= {};
        my $target = $all_export_map->{sub}{$name};
        for (@$export) { $target->{$_} = \&{"${pkg_ex}::$_"}; }
    }
    else { push @{$all_export_map->{alias}{$export}}, @$name; }
    $import_override or return;
    *{ $pkg_ex . '::import' } = sub {
        my $self = shift;
        my @tmp_args = @_;

        my @caller_im = caller(0);
        my $pkg_im = $caller_im[0];
        my $all_export_map = ${"${pkg_ex}::__all_export_map__"};
        my $all_const_map = $all_export_map->{const};
        my $all_sub_map = $all_export_map->{sub};
        my @args = ();
        my $alias = $all_export_map->{alias};
        for my $arg (@tmp_args) {
            my $arg_no_precolon = substr($arg, 1);
            if (exists $alias->{$arg_no_precolon}) {
                for (@{$alias->{$arg_no_precolon}}) { push @args, ':' . $_; }
            }
            else { push @args, $arg; }
        }
        for my $arg (@args) {
            if ($arg eq ':all') {
                for my $k1 (keys %$all_const_map) {
                    my $map = $all_const_map->{$k1};
                    for my $k2 (keys %$map) {
                        *{"${pkg_im}::${k2}"} = 
                            sub () { my $val = $map->{$k2}; return $val; };
                    }
                }
                for my $k1 (keys %$all_sub_map) {
                    my $subs = $all_sub_map->{$k1};
                    for (keys %$subs) { *{"${pkg_im}::$_"} = $subs->{$_}; }
                }
            }
            elsif ($arg =~ /^:(.*)/) {
                if (exists $all_const_map->{$1}) {
                    my $map = $all_const_map->{$1};
                    for my $k (keys %$map) {
                        *{"${pkg_im}::${k}"} = 
                            sub () { my $val = $map->{$k}; return $val; };
                    }
                }
                elsif (exists $all_sub_map->{$1}) {
                    my $subs = $all_sub_map->{$1};
                    for (keys %$subs) { *{"${pkg_im}::$_"} = $subs->{$_}; }
                }
            }
            else {
                for my $k (keys %$all_const_map) {
                    my $map = $all_const_map->{$k};
                    if (exists $map->{$arg}) {
                        *{"${pkg_im}::${arg}"} = 
                            sub () { my $val = $map->{$arg}; return $val; };
                    }
                }
                for my $k (keys %$all_sub_map) {
                    my $subs = $all_sub_map->{$k};
                    for (keys %$subs) {
                        $_ ne $arg and next;
                        *{"${pkg_im}::$_"} = $subs->{$_};
                    }
                }
            }
        }
    };
}

=head1 AUTHOR

Egawa Takashi, C<< <egawa.takashi@adways.net> >>

[Base idea & Base code] Junichiro NAKAMURA, C<< <jyun16@gmail.com> >>

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

1; # End of Wiz::ConstantExporter

__END__
