package Wiz::Term;

use strict;
use warnings;

=head1 NAME

Wiz::Term

=head1 VERSION

version 1.0

=cut

our $VERSION = '1.0';

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut

use Term::ANSIColor qw(:constants);
use IO::Prompt;

use Wiz::Constant qw(:common);

=head1 EXPORTS

 CLEAR
 RESET
 BOLD
 DARK
 UNDERLINE
 UNDERSCORE
 BLINK
 REVERSE
 CONCEALED
 BLACK
 RED
 GREEN
 YELLOW
 BLUE
 MAGENTA
 CYAN
 WHITE
 ON_BLACK
 ON_RED
 ON_GREEN
 ON_YELLOW
 ON_BLUE
 ON_MAGENTA
 ON_CYAN
 ON_WHITE

 p
 line
 double_line
 p_xo
 p_err

=cut

use Wiz::ConstantExporter 
    \@{${Term::ANSIColor::EXPORT_TAGS{'constants'}}}, 'const';

use Wiz::ConstantExporter [qw(
p
pn
line
double_line
xo
okng
err
confirm
)];

our $WIDTH = 72;
our $CLEAR_COMMAND = '/bin/clear';

#----[ static ]-------------------------------------------------------

=head1 FUNCTIONS

=cut

sub p {
    my ($str, $color) = @_;

    no warnings 'uninitialized';

    if (defined $color and $ENV{WIZ_TERM_COLOR_MODE} ne 0) {
        print BOLD, $color, $str, RESET;
    }
    else { print $str; }
}

sub pn {
    my ($str, $color) = @_;
    p ("$str\n", $color);
}

sub line {
    my ($color) = @_;
    pn '-' x $WIDTH, $color;
}

sub double_line {
    my ($color) = @_;
    pn '=' x $WIDTH, $color;
}

sub xo {
    my ($f) = @_;
    p '['; if ($f) { p 'o', GREEN; } else { p 'x', RED; } p ']';
}

sub okng {
    my ($f) = @_;
    p '['; if ($f) { p 'OK', GREEN; } else { p 'NG', RED; } p ']';
}

sub err {
    my ($msg) = @_;
    p '['; p ' ERROR ', RED; p "] $msg\n";
}

sub confirm {
    my ($msg, $default) = @_;

    defined $default or $default = '';

    if ($default =~ /^y/) { $msg .= ' [Y/n]'; }
    elsif ($default =~ /^n/) { $msg .= ' [y/N]'; }
    else { $msg .= ' [y/n]'; }

    return (lc prompt "$msg: ", -tyno => '', -d => $default) =~ /^y/;
}

#----[ private ]------------------------------------------------------
#----[ private static ]-----------------------------------------------

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
