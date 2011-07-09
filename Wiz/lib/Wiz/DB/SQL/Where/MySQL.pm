package Wiz::DB::SQL::Where::MySQL;

use strict;

=head1 NAME

Wiz::DB::SQL::Where::MySQL

=head1 VERSION

version 1.0

=cut

our $VERSION = '1.0';

=head1 SYNOPSIS

=head2 FOR FULL TEXT INDEX

 my $w = new Wiz::DB::SQL::Where::MySQL;
 
 $w->set(
     -match      => [qw(title body)],
     -against    => 'data;base',
 );
 
 # WHERE MATCH(title,body) AGAINST(?)
 $w->to_string;
 
 # [qw(data;base)]
 $w->values;
 
 # WHERE MATCH(title,body) AGAINST('data\;base')
 $w->to_exstring;
 
 $w->set(
     -match              => [qw(title body)],
     -against_boolean    => 'data;base',
 );
 
 # WHERE MATCH(title,body) AGAINST(? IN BOOLEAN MODE)
 $w->to_string;
 
 # [qw(data;base)]
 $w->values;
 
 # WHERE MATCH(title,body) AGAINST('data\;base' IN BOOLEAN MODE)
 $w->to_exstring;

=head1 DESCRIPTION

=head2 CONSTRUCTOR

=head2 METHOD

=cut

use base 'Wiz::DB::SQL::Where';

use Wiz::Constant qw(:all);
use Wiz::DB::Constant qw(:all);
use Wiz::DB::SQL::Constant qw(:common);

use Wiz::ConstantExporter [qw(against)];

sub new {
    my $self = shift;
    my $instance = $self->SUPER::new(@_);
    $instance->type(DB_TYPE_MYSQL);
    return $instance;
}

sub create_limit {
    my $self = shift;
    if (defined $self->{limit}) {
        $self->{limit} =~ /^\d*$/ or return '';
        if (defined $self->{offset}) {
            $self->{offset} =~ /^\d*$/ or return '';
            return "LIMIT $self->{offset},$self->{limit}";
        }
        else {
            return "LIMIT $self->{limit}";
        }
    }
}

sub against {
    my ($cols, $targets, $word) = @_;
    ref $cols or $cols = [ $cols ];
    ref $targets or $targets = [ $targets ];
    $targets = { map { $_ => 1 } @$targets };
    my @w = ();
    for (my $i = 0; $i < @$cols; $i++) {
        my $c = $cols->[$i];
        $targets->{$c} and push @w, ($i + 1);
    }
    return "*W" . (join ',', @w) . " $word";
}

sub _create_where_core {
    my $self = shift;
    my ($key, $val, $exflag) = @_;
    if (my ($k) = $key =~ /^-(.*)/) {
        if ($k eq 'and' or $k eq 'or') {
            return $self->_create_where_core_and_or($k, $val, $exflag);
        }
        elsif ($k eq 'between') {
            my $r = ref $val;
            if ($r eq 'ARRAY') {
                return $exflag ? "$val->[0] BETWEEN " . $self->_get_sanitized_value($val->[1][0]) . 
                                    " AND " . $self->_get_sanitized_value($val->[1][1]) :
                                 "$val->[0] BETWEEN ? AND ?"; 
            }
            elsif ($r eq 'HASH') {
                for (sort keys %$val) {
                    return $exflag ? "$_ BETWEEN " . $self->_get_sanitized_value($val->{$_}[0]) . 
                                        " AND " .  $self->_get_sanitized_value($val->{$_}[1]) :
                                     "$_ BETWEEN ? AND ?";
                }
            }
        }
        elsif ($k eq 'in') {
            return $self->_create_where_core_in($val, $exflag);
        }
        elsif ($k eq 'not_in') {
            return $self->_create_where_core_in($val, $exflag, TRUE);
        }
        elsif ($k eq 'limit') {
            if (@$val > 1) { $self->{offset} = $val->[0]; $self->{limit} = $val->[1]; }
            elsif (@$val == 1) { $self->{limit} = $val->[0]; }
            return '';
        }
        elsif ($k eq 'order') {
            $self->{order} = $val;
            return '';
        }
        elsif ($k eq 'group') {
            $self->{group} = $val;
            return '';
        }
        elsif ($k eq 'match_against') {
            return $self->_create_where_core_match($val, $exflag, 0);
        }
        elsif ($k eq 'match_against_boolean') {
            return $self->_create_where_core_match($val, $exflag, 1);
        }
    }
}

sub _create_where_core_match {
    my $self = shift;
    my ($val, $exflag, $boolean_mode) = @_;
    my $in_boolean = $boolean_mode ? ' IN BOOLEAN MODE' : '';
    my $against = $val->[$#$val];
    my $match = join ',', @$val[0..$#$val-1];
    return "MATCH($match) " . (
        $exflag ? 'AGAINST(' . $self->_get_sanitized_value($against) . "$in_boolean)" : "AGAINST(?$in_boolean)");
}

sub _create_where_values_other {
    my $self = shift;
    my ($ret, $key, $value) = @_;
    if (my ($k) = $key =~ /^-(.*)/) {
        if ($k =~ /^match/) {
            push @$ret, $value->[$#$value];
        }
    }
}

=head1 SEE ALSO

L<Wiz::DB::SQL::Where>

=head1 AUTHOR

Junichiro NAKAMURA, C<< <jyun16@gmail.com> >>

=head1 COPYRIGHT & LICENSE

Copyright 2008,2009,2010 The Wiz Project. All rights reserved.

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

