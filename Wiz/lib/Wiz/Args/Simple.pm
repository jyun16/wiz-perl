package Wiz::Args::Simple;

use strict;
use warnings;

no warnings 'uninitialized';

=head1 NAME

Wiz::Args::Simple - parse command options

=head1 VERSION

version 1.0

=cut

our $VERSION = '1.0';

=head1 SYNOPSIS

 use Wiz::Args::Simple qw(getopts);
 
 # Getopt way
 my $args = getopts('u:p:ghv');
 
 # Wiz::Args::Simple way
 my $args = getopts(<<'EOS');
 u(user):
 p(passwd);
 t(targets)@
 h(help)
 v(version)
 -proxy:
 -proxy_user:
 -proxy_pass;
 -hosts@
 -nowarn
 EOS

=head1 DESCRIPTION

The usage looks like Getopt::Std. But Getopt::Std only can set short-option or
it only can specify whether an option takes the value or not.

For example:

 my $args = getopts('u:h');

This code means the command can take the following options.

 cmd -u blah -h

In this command, 'blah' is in $args->{u} and 1 is in $args->{h}.
It is simple, but powerless.

But Wiz::Args::Simple can do more complicate things like as the following:

 my $args = getopts(<<'EOS');
u(user):
p(passwd);
t(targets)@
h(help)
v(version)
-proxy:
-proxy_user:
-proxy_pass;
-hosts@
-nowarn
EOS

=head1 NOTATION

In the following explanation, "W" means one letter.

=head2 W

"W" is the short name of the option. It is as same as Getopt.

For example:

 u

This means '-u' can be used as an option.

 cmd -u

=head2 W(LONG_NAME)

"W" is the short name of the option and "LONG_NAME" is long name of the option.
This means specify short-option and long-option in same time.

For example:

 u(user)

This means '-u' and '--user' can be used as an option.

 cmd -u blah
 cmd --user blah

These are same and set 'blah' to both $args->{u} and $args->{user}.

=head2 W(LONG_NAME): or W(LONG_NAME);

It is as nearly same as the previous except ':' or ';' is added.

":" means this option require a value.
";" has two means. When no value is given to the option, 1 is set.
When a value is given to the option, the value is set.

For example:

 p(passwd);

Command is like the following:

 cmd --passwd blah
 cmd --passwd

The former, 'blah' is set to $args->{passwd} and $args->{p}.
The later, 1 is set to $args->{passwd} and $args->{p}.

=head2 W(LONG_VALUE)@

When "@" is added instead of ';' or ':', it can takes multiple values.

For example:

 t(targets)@

Command is like the following:

 cmd --targets blah1 blah2 blah3

[qw(blah1 blah2 blah3)] is set to $args->{t} and $args->{targets}.

=head2 -LONG_NAME, -LONG_NAME;, -LONG_NAME: or -LONG_NAME@

This allows only long-option like the following.
For example:

 -nowarn

=head2  not specified values ?

When the values which are not specified with getopts,
where are they set?

For example:

 cmd -u user hoge fuga

'-u' can take only one value.
So, in this case, $args is the following:

 $args = {
     'u' => 'user',
     '0' => 'hoge',
     '1' => 'fuga',
     'no_opt_args' => [
         'hoge',
         'fuga'
     ],
     'user' => 'user'
 };
 
In $args->{u} and $args->{user}, "user" is set. It is normal behavior.

But other values('hoge', 'fuga') are set to $args->{#}(# is number) in order,
'hoge' is in $args->{0} and 'fuga' is $args->{1}.
And they are also set to the value of hash key 'no_opt_args'.

It seems a little verbose, but it may make you a little happily.

=head2 2nd and 3rd return value of getopts

getopts returns 3 values if you want.

 my ($args, $slmap, $lsmap) = getopts('u(user):p(passwd);');

The following values are returned as 2nd and 3rd return value:

 $slmap = {
     u  => 'user',
 };
 
 $lsmap    = {
     user    => 'u',
 };

It is a kind of nosy, but, in some case, it will help you.

=head1 EXPORTS

=cut

use base qw(Exporter);

use Wiz::Util::Hash qw(override_hash);

our @EXPORT_SUB = qw(getopts merge_args);
our @EXPORT_CONST = qw();
our @EXPORT_OK = (@EXPORT_SUB, @EXPORT_CONST);

our %EXPORT_TAGS = (
    'sub'       => \@EXPORT_SUB,
    'const'     => \@EXPORT_CONST,
    'all'       => \@EXPORT_OK,
);

=head1 FUNCTIONS

=head2 $args or ($args, $slmap, $lsmap) = getopts($args_pattern)

 u(user):p(passwd):t(targets)@-proxy:abcd
 : option has any argument
 ; option can have any argument
 @ option has list arguments

=cut

sub getopts {
    my $args_pattern = shift;
    my $p = getopts_pattern($args_pattern);
    my %ret = ();
    my $args_cnt = 0;
    my @no_opt_args = ();
    for (my $i = 0; $i < @ARGV; $i++) {
        my ($a, $o, $v) = ($ARGV[$i], undef, undef);
        if ($a =~ /^-/) {
            $a =~ /^([^=]*)=?(.*)/;
            $o = $1; $v = $2;
            exists $p->{$o} or print "no such option -> $o\n" and exit 1;
            $a = $o;
            $o =~ s/^-*//g;
        }
        else {
            $ret{$args_cnt} = $a;
            push @no_opt_args, $a;
            ++$args_cnt;
        }
        if ($p->{$a} eq 's' or $p->{$a} eq 'l') {
            $ret{$o} = 1;
            set_opt_map(\%ret, $p, $o, 1);
        }
        elsif ($p->{$a} eq 'sv' or $p->{$a} eq 'lv') {
            $v eq '' and $v = $ARGV[++$i];
            if ($v eq '') {
                print STDERR "$a option must be given any value.\n";
                exit 1;
            }
            $ret{$o} = $v;
            set_opt_map(\%ret,$p, $o, $v);
        }
        elsif ($p->{$a} eq 'sa' or $p->{$a} eq 'la') {
            if ($ARGV[$i + 1] !~ /^-/) {
                $v eq '' and $v = $ARGV[++$i];
                $ret{$o} = $v;
                set_opt_map(\%ret, $p, $o, $v);
            }
            else {
                $ret{$o} = 1; 
                set_opt_map(\%ret, $p, $o, 1);
            }
        }
        elsif ($p->{$a} eq 'sm' or $p->{$a} eq 'lm') {
            ++$i;
            for (my $j = $i; $j < @ARGV; $j++) {
                if ($ARGV[$j] !~ /^-/) {
                    my $v = $ARGV[$j];
                    push @{$ret{$o}}, $v;
                    set_opt_map(\%ret, $p, $o, $ret{$o});
                    ++$i;
                }
                else {
                    --$i; last;
                }
            }
        }
    }
    @no_opt_args and $ret{no_opt_args} = \@no_opt_args;
    return wantarray ? (\%ret, $p->{'---slmap'}, $p->{'---lsmap'}) : \%ret;
}

# =head2 \%args_pattern = _getopts_pattern($args_pattern)
# 
# $args_pattern = _getopts_pattern('u(user):p(passwd);t(targets)@-proxy:');
# 
# $args_pattern = {
#     -u          => 'sv',
#     --user      => 'lv',
#     -p          => 'sa',
#     --passwd    => 'la',
#     -t          => 'sm',
#     --targets   => 'lm',
#     --proxy     => 'lv',
#     ---lsmap    => {
#         targets     => 't',
#         passwd      => 'p',
#         use         => 'u'
#     },
#     ---slmap    => {
#         p   => 'passwd',
#         u   => 'user',
#         t   => 'targets'
#     },
# };
#  
# s       short option
# sv      option with value
# sa      short option may have any value
# sm      short option have multi value
# l       long option
# lv      long option with value
# la      long option may have any value
# lm      long option have multi value
#  
# =cut

sub getopts_pattern {
    my $args_pattern = shift;
    $args_pattern =~ s/\r?\n//g;
    $args_pattern =~ s/\s//g;
    my %ret = ();
    for my $c ($args_pattern =~ m/(?:-[^-:;@]*[:;@]?)|(?:.\(.*?\)[:;@]?)|(?:.[:;@]?)/g) {
        if ($c =~ /\(/) {
            $c =~ /(.)\((.*?)\)([:;@]?)/;
            if ($3 eq ':') { $ret{-$1} = 'sv'; $ret{'--' . $2} = 'lv'; }
            elsif ($3 eq ';') { $ret{-$1} = 'sa'; $ret{'--' . $2} = 'la'; }
            elsif ($3 eq '@') { $ret{-$1} = 'sm'; $ret{'--' . $2} = 'lm'; }
            else { $ret{-$1} = 's'; $ret{'--' . $2} = 'l'; }
            $ret{'---slmap'}{$1} = $2;
            $ret{'---lsmap'}{$2} = $1;
        }
        else {
            $c =~ /(-?[^-:;@]*)([:;@]?)/;
            my $o = $1;
            my $f = $2;
            if ($c =~ /^-/) {
                if ($f eq ':') { $ret{'-' . $o} = 'lv'; }
                elsif ($f eq ';') { $ret{'-' . $o} = 'la'; }
                elsif ($f eq '@') { $ret{'-' . $o} = 'lm'; }
                else { $ret{'-' . $o} = 'l'; }
            }
            else {
                if ($f eq ':') { $ret{-$o} = 'sv'; }
                elsif ($f eq ';') { $ret{-$o} = 'sa'; }
                elsif ($f eq '@') { $ret{-$o} = 'sm'; }
                else { $ret{-$o} = 's'; }
            }
        }
    }
    return \%ret;
}

sub set_opt_map {
    my ($map, $pattern, $key, $value) = @_;
    for (qw(---slmap ---lsmap)) {
        exists $pattern->{$_}{$key} and 
            $map->{$pattern->{$_}{$key}} = $value;
    }
}

sub merge_args {
    my ($args, $target, $lsmap) = @_;
    for (keys %$target) {
        if ($lsmap->{$_} ne '') {
            $args->{$lsmap->{$_}} = $target->{$_};
            delete $target->{$_};
        }
    }
    return override_hash($args, $target);
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
