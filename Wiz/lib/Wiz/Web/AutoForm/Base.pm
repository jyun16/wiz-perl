package Wiz::Web::AutoForm::Base;

use strict;
use warnings;

=head1 NAME

Wiz::Web::AutoForm::Base

=head1 VERSION

version 1.0

=cut

our $VERSION = '1.0';

=head1 SYNOPSIS

SEE L<Wiz::Web::AutoForm::Tutorial>

=cut

use Carp;

use Wiz::Constant qw(:common);

=head1 EXPORTS

=cut

use base qw(Exporter Class::Accessor::Fast);

our @EXPORT_SUB = qw();
our @EXPORT_CONST = qw();
our @EXPORT_OK = (@EXPORT_SUB, @EXPORT_CONST);

our %EXPORT_TAGS = (
    'sub'       => \@EXPORT_SUB,
    'const'     => \@EXPORT_CONST,
    'all'       => \@EXPORT_OK,
);

=head1 CONSTRUCTOR

=cut

sub new {
    my $self = shift;
}

=head1 METHODS

=cut

sub clear {
    my $self = shift;
}

# ----[ private ]-----------------------------------------------------

=head1 FUNCTIONS

=cut

# ----[ static ]------------------------------------------------------
# ----[ private static ]----------------------------------------------
sub _tag_append_attribute {
    my ($attr, $escape) = @_;

    defined $attr or return '';
    defined $escape or $escape = HTML_ESCAPE;
    %$attr or return '';
    my $tag = '';
    for (keys %$attr) {
        if ($_ ne 'value') {
            defined $attr->{$_} or next;
            my $a = ($escape == NON_ESCAPE) ? $attr->{$_} : html_escape($attr->{$_});
            $tag .= qq| $_="$a"|;
        }
    }
    return $tag;
}

sub _tag_append_attributes {
    my ($attrs, $i, $escape) = @_;

    defined $attrs or return '';
    defined $escape or $escape = HTML_ESCAPE;
    ref $attrs eq 'HASH' and return _tag_append_attribute($attrs, $escape);
    return _tag_append_attribute($attrs->[$i], $escape);
}

sub _tag_value {
    my ($value, $conf, $escape) = @_;

    defined $escape or $escape = HTML_ESCAPE;
    defined $value or $value = ($conf->{default} || '');
    return ($escape == NON_ESCAPE) ? $value : html_escape($value);
}

sub __tag_values {
    my ($values, $conf, $escape) = @_;

    defined $escape or $escape = HTML_ESCAPE;
    if (not defined $values or @$values == 0) {
        $values = defined $conf->{default} ?
            (ref $conf->{default} ? $conf->{default} : [ $conf->{default} ]) : [];
    }
    for (@$values) { $_ = ($escape == NON_ESCAPE) ? $_ : html_escape($_); }
    return $values;
}

sub _tag_values {
    return __tag_values(@_);
}

sub _tag_values2hash {
    my ($values, $conf, $escape) = @_;

    defined $escape or $escape = HTML_ESCAPE;
    $values = __tag_values($values, $conf, $escape); 
    if ($escape == NON_ESCAPE) { return { map { $_ => 1 } @$values }; }
    else { return { map { html_escape($_) => 1 } @$values }; }
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

