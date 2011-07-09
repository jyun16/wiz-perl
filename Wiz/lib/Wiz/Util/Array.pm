package Wiz::Util::Array;

use strict;
use warnings;

=head1 NAME

Wiz::Util::Array

=head1 VERSION

version 1.0

=cut

our $VERSION = '1.0';

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut

use POSIX;

use Clone qw(clone);
use Wiz::Constant qw(:common);

=head1 EXPORTS

 array_split
 array_sum
 array_max
 array_min
 array_equals
 array_round_robin
 array_delete
 array_random
 array_random_with_priority
 array_chomp
 array_trim
 array_head_trim
 array_tail_trim
 array_divide
 array_unique
 array_included
 array_shuffle
 array_all_pattern
 args2array

=cut

use Wiz::ConstantExporter [qw(
    array_split
    array_sum
    array_max
    array_min
    array_equals
    array_round_robin
    array_delete
    array_random
    array_random_with_priority
    array_chomp
    array_trim
    array_head_trim
    array_tail_trim
    array_divide
    array_unique
    array_included
    array_shuffle
    array_all_pattern
    args2array
)]; 

=head1 FUNCTIONS

=head2 ($ary1, $ary2) = array_split(@ary or \@ary, $offset)

Splits an array to two arrays by the point of $offset.

=cut

sub array_split {
    my ($ary, $offset) = @_;

    my @ary1 = @$ary[0..($offset - 1)];
    my @ary2 = splice @$ary, $offset;
    return \@ary1, \@ary2;
}

=head2 $sum = array_sum(@ary or \@ary)

Returns the sum of array's all values.

=cut

sub array_sum {
    my $ary = args2array(@_); 
    my $sum = 0;
    for (@$ary) { $sum += $_; }
    return $sum;
}

=head2 $max = array_max(@ary or \@ary)

Returns the max value in the array.

=cut

sub array_max {
    my $ary = args2array(@_); 
    my $max = 0;
    for (@$ary) { $max < $_ and $max = $_; }
    return $max;
}

=head2 $min = array_min(@ary or \@ary)

Returns the min value in the array.

=cut

sub array_min {
    my $ary = args2array(@_); 
    my $min = $ary->[0];
    for (@$ary) { $min > $_ and $min = $_; }
    return $min;
}

=head2 $bool = array_equals($ary1, $ary2)

Compares array.
This method compares an only simple array object(not nesting).

=cut

sub array_equals {
    my ($ary1, $ary2) = @_;
    no warnings qw(uninitialized);
    @$ary1 != @$ary2 and return FALSE;
    my $i = 0;
    for (@$ary1) { $_ ne $ary2->[$i] and return FALSE; ++$i; }
    return TRUE;
}

=head2 $list = array_round_robin(@ary or \@ary)

Returns the round robin array.

=cut

sub array_round_robin {
    my $ary = args2array(@_); 
    my $len = scalar @$ary;
    my $index_len = $len - 1;
    my $pattern = 2 ** $len - 1;

    my @list = ();
    for my $i (0..$pattern) {
        my @data = ();
        for my $j (0..$index_len) {
            if ($i & (1 << $j)) {
                defined $ary->[$j] and push @data, $ary->[$j];
            }
        }
        @data and push @list, \@data;
    }

    return \@list;
}

=head2 @data or \@data = array_delete($ary, $key)

Deletes an array value match the $key.

=cut

sub array_delete {
    my ($ary, $key) = ([], undef);

    if (ref $_[0] eq 'ARRAY') {
        ($ary, $key) = @_;
    }
    else {
        $key = pop @_;
        $ary = [ @_ ];
    }

    my @ret = grep { $key ne $_ } @$ary;
    return wantarray ? @ret : \@ret;
}

=head2 $data = array_random(@ary or \@ary)

Returns random value in the array.

=cut

sub array_random {
    my $ary = args2array(@_); 
    my $n = scalar @$ary;
    srand;
    return $ary->[rand($n)];
}

=head2 $data or [$data, $index] array_random_with_priority($ary, $priority, undef or $priority_sum)

$priority is array reference of a priority(low 0, high 10)

=cut

sub array_random_with_priority {
    my ($ary, $priority, $priority_sum) = @_;

    $priority_sum ||= array_sum($priority);
    my $rand = int(rand($priority_sum)) + 1;
    my ($i, $s) = (0, 0);
    for (@$priority) {
        if ($_ > 0) {
            $s += $_;
            $s >= $rand and last;
        }
        $i++;
    }

    return wantarray ? ($ary->[$i], $i) : $ary->[$i];
}

=head2 $ary = array_chomp(@ary or \@ary)

Chomps the all values in the array.
When an array reference is given, changes itself.

=cut

sub array_chomp {
    my $ary = args2array(@_); 
    for (@$ary) { s/\r?\n$//; }
    return wantarray ? @$ary : $ary;
}

=head2 $ary = array_trim(@ary or \@ary)

Trims the all values in the array.
When an array reference is given, changes itself.

=cut

sub array_trim {
    my $ary = args2array(@_); 
    for (@$ary) { s/^\s*(.*?)\s*$/$1/; }
    return wantarray ? @$ary : $ary;
}

=head2 $ary = array_tail_trim(@ary or \@ary)

Trims tail of each values in the array.
When an array reference is given, changes itself.

=cut

sub array_tail_trim {
    my $ary = args2array(@_); 
    for (@$ary) { s/\s*$//; }
    return wantarray ? @$ary : $ary;
}

=head2 $ary = array_head_trim(@ary or \@ary)

Trims head of each values in the array.
When an array reference is given, changes itself.

=cut

sub array_head_trim {
    my $ary = args2array(@_); 
    for (@$ary) { s/^\s*//; }
    return wantarray ? @$ary : $ary;
}

=head2 $arys = array_divide(\@ary, $num);

Returns devided array per $num.

=cut

sub array_divide {
    my ($array, $n) = @_;

    my @ret = ();
    my ($len, $rest) = (ceil(@$array / $n), @$array % $n);
    for (my $i = 0; $i < @$array; $i += $len) {
        push @ret, [ map {$_} @$array[$i .. ($i + $len - 1)] ];
        --$rest;
        if ($rest == 0) { ++$i; --$len; }
    }
    return \@ret;
}

sub array_unique {
    my $ary = args2array(@_);
    my %tmp;
    my @ret = grep { !$tmp{$_}++; } @$ary;
    wantarray ? @ret : \@ret;
}

=head2 $flag = array_included($target, $check)

=cut

sub array_included {
    my ($target, $check) = @_;

    defined $target or return FALSE;
    defined $check or return FALSE;
    if (ref $check) {
        for my $c (@$check) {
            grep(/$c/, @$target) or return FALSE;
        }
        return TRUE;
    }
    else {
        return grep /$check/, @$target;
    }
}

=head2 $args = args2array(@args or \@args or \%args)

Returns to be changed arguments to array reference .

=cut

sub array_shuffle {
    my ($target) = args2array(@_);
    my $i = @$target;
    while (--$i) {
        my $j = int rand( $i+1 );
        @$target[$i,$j] = @$target[$j,$i];
    }
    return wantarray ? @$target : $target;
}

sub array_all_pattern {
    my $target = args2array @_;
    @$target or return [[]];
    my @ret;
    for (my $i = 0; $i < @$target; $i++) {
        my @tmp = @$target;
        splice @tmp, $i, 1;
        my $tmp = array_all_pattern(\@tmp);
        for my $t (@$tmp) {
            push @ret, [ $target->[$i], @$t ];
        }
    }
    return wantarray ? @ret : \@ret;
}

sub args2array {
    my $ref = ref $_[0];
    if ($ref eq 'ARRAY') { return @_ > 1 ? [ @_ ] : $_[0]; }
    elsif ($ref eq 'HASH') { return @_ > 1 ? [ @_ ] : [ %{$_[0]} ]; } 
    else { return @_ ? [ @_ ] : undef; }
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
