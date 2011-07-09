package Wiz;

use strict;
use warnings;

=head1 NAME

Wiz - provides functions commonly used for creating modules

=head1 VERSION

version 1.0

=cut

our $VERSION = '1.0';

=head1 DESCRIPTION

This module provides functions commonly used for creating Wiz::* modules.

=head1 EXPORTS

All functions/method can be exported.

=cut

use Carp;
use base qw(Exporter);

use Wiz::Config qw(load_config_files);

our @EXPORT_SUB = qw(
get_hash_args
get_log_from_conf
ourv
import_parent_symbols
);
our @EXPORT_CONST = qw();
our @EXPORT_OK = (@EXPORT_SUB, @EXPORT_CONST);

our %EXPORT_TAGS = (
    'sub'       => \@EXPORT_SUB,
    'const'     => \@EXPORT_CONST,
    'all'       => \@EXPORT_OK,
);

=head1 FUNCTIONS

=head2 \%args = get_hash_args(@_)

If you specified in Hoge.pm.

 use Wiz qw(get_hash_args);
 
 sub hoge {
     my $self = shift;
     my $args = get_hash_args(@_);
 }

You can call the constructor of Hoge at the following.

 my $obj = new Hoge;
 $obj->hoge(hoge => 'HOGE', fuga => 'FUGA');

or

 my $obj = new Hoge;
 $obj->hoge({ hoge => 'HOGE', fuga => 'FUGA' });

When you write the following data into conf.pdat.

 {
     foo => 'FOO',
     bar => 'BAR',
 },

Then you can call it at the following.

 my $obj = new Hoge;
 $obj->hoge(hoge => 'HOGE', fuga => 'FUGA', _conf => 'conf.pdat');

=cut

sub get_hash_args {
    no warnings qw(all);

    my $conf = ref $_[0] eq 'HASH' ? $_[0] : 
         ref $_[0] eq 'ARRAY' ? { @{$_[0]} } : { @_ };
    my $conf_file = $conf->{_conf};
    if (defined $conf_file) {
        -f $conf_file or confess "can't open file > $conf_file ($!)";
        my $conf_obj = load_config_files($conf_file);
        for (keys %$conf_obj) {
            $conf->{$_} = $conf_obj->{$_};
        }
        delete $conf->{_conf};
    }

    return $conf;
}

=head2 $log = get_log_from_conf($conf)

Returns a instance of Wiz::Log from the data to get by get_hash_args.

If $conf has key 'log' and it is hash ref or array ref,
it is regraded as log configuration and make $conf->{log} Wiz::Log instance.
If the key is already Wiz::Log, returns it.
If $conf doesn't have key 'log', it returns undef.

=cut

sub get_log_from_conf {
    my $conf = shift;

    defined $conf->{log} or return;

    my $r = ref $conf->{log};
    if ($r eq 'HASH') {
        if (defined $conf->{base_dir}) {
            $conf->{log}{base_dir} = $conf->{base_dir};
        }
        return new Wiz::Log($conf->{log});
    }
    elsif ($r eq 'ARRAY') {
        return new Wiz::Log($conf->{log});
    }
    elsif ($r eq 'Wiz::Log') {
        return $conf->{log};
    }
}

=head1 METHODS

=head2 $ourvalue = ourv($varname, $symbol)

Returns the value defined by C<our>.

$varname is variable name. $symbol is '$', '@' or '%'.
If $symbol is omitted, $symbol is regarded as '$'.

 package Hoge;
 
 our %OUR_VALUE = (a => 1, b => 2);
 
 package main;

 my $hoge = Hoge->new;
 my %our_value = $hoge->ourv('OUR_VALUE', '%');

=cut

sub ourv {
    my $self = shift;
    my ($target, $type) = @_;

    no strict 'refs';
    my $name = ref $self || $self;

    defined $type or $type = '$';
    if ($type eq '@') { return @{"${name}::$target"}; }
    elsif ($type eq '%') { return %{"${name}::$target"}; }
    elsif ($type eq '$') { return ${"${name}::$target"}; }
}

=head2

 package Parent;
 
 our $PARENT_VALUE = 10_000_000;
 
 sub parent_method {
     warn 'PARENT';
 }
 
 sub common {
     warn 'PARENT COMMON';
 }
 
 1;
 
 ----
 
 package Child;
 
 use Parent;
 
 use Wiz qw(import_parent_symbols);
 
 sub BEGIN {
     import_parent_symbols('Parent');
 }
 
 sub child_method {
     warn 'CHILD';
 }
 
 sub common {
     warn 'CHILD COMMON';
 }
 
 1;
 
 ----
 
 #!/usr/bin/perl
 
 use Child;
 
 # 10_000_000
 warn $Child::PARENT_VALUE;
 # PARENT
 Child::parent_method;
 # CHILD COMMON
 Child::common;

=cut

sub import_parent_symbols {
    my ($parent) = @_;
    my ($child) = caller;
    no strict 'refs';
    my %parent_symbols = %{*{"$parent\::"}};
    my %self_symbols = %{*{"$child\::"}};
    for (keys %parent_symbols) {
        $self_symbols{$_} and next;
        *{"${child}::$_"} = $parent_symbols{$_};
    }
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
