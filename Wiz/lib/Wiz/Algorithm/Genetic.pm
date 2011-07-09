package Wiz::Algorithm::Genetic;

use strict;

=head1 NAME

Wiz::Algorithm::Genetic

=head1 VERSION

version 1.0

=cut

our $VERSION = '1.0';

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut

use Wiz::Noose;
use Wiz::Util::Array qw(array_shuffle array_random_with_priority);

has 'max_populations' => (is => 'rw', default => 300);
has 'fixed_number_of_generations' => (is => 'rw', default => 1_000);
has 'selection_odds' => (is => 'rw', default => {
    roulette    => 40,
    tournament  => 30,
    ranking     => 20,
    elite       => 9,
    random      => 1,
});
has 'crossover_odds' => (is => 'rw', default => {
    mutation    => 80,
    one_point   => 5,
    two_point   => 80,
    uniform     => 10,
});
has 'ranking_selection_odds' => (is => 'rw', default => {
    1   => 30,
    2   => 20,
    3   => 15,
    4   => 10,
    5   => 5,
    6   => 5,
    7   => 5,
    8   => 5,
    9   => 3,
    10  => 2,
});
has 'number_of_tournament_selection' => (is => 'rw', default => 5);
has 'size_of_individual' => (is => 'rw', default => 5);
has 'data' => (is => 'rw', setter => sub {
    my $self = shift;
    my ($val) = @_;
    $self->{size_of_individual} = @$val;
    return $val;
});
has 'rating' => (is => 'rw');

has 'sub_init' => (is => 'rw', default => sub {
    my $self = shift;
    my @all;
    my @individual = (1 .. $self->{size_of_individual} - 1);
    my %rating = ();
    for (1 .. $self->{max_populations}) {
        my $data = [ array_shuffle(@individual) ];
        $rating{$self->calc_score($data)} = $data;
    }
    $self->{rating} = \%rating;
});

has 'sub_calc_score' => (is => 'rw', default => sub {
    my $self = shift;
    my ($target) = @_;
    my @individual = (0, @$target, 0);
    my $score;
    my $data = $self->{data};
    for (my $i = 0; $i < @individual - 1; $i++) { 
        my ($x, $y) = $individual[$i] < $individual[$i + 1] ?
        ($individual[$i + 1], $individual[$i]) :
        ($individual[$i], $individual[$i + 1]);
        $score += $data->[$x][$y];
    }
    return $score;
});

sub init {
    my $self = shift;
    $self->{sub_init}->($self);
}

sub calc_score {
    my $self = shift;
    $self->{sub_calc_score}->($self, @_);
}

sub calc {
    my $self = shift;
    $self->{rating} or $self->init;
    for (1 .. $self->{fixed_number_of_generations}) {
        my ($father, $mother) = $self->select_parents;
        my $child = $self->crossover($father, $mother);
        if ($self->check_genome($child)) {
            $self->add_polulations($child);
        }
    }
}

sub add_polulations {
    my $self = shift;
    my ($child) = @_;
    my $rating = $self->{rating};
    $rating->{$self->calc_score($child)} = $child;
    my @worst = sort { $b <=> $a } keys %$rating;
    if ($self->{max_populations} < @worst) {
        delete $rating->{shift @worst};
    }
}

sub check_genome {
    my $self = shift;
    my ($target) = @_;
    my %check = map { $_ => 1 } @$target;
    for (1 .. ($self->{size_of_individual} - 1)) {
        $check{$_} or return 0;
    }
    return 1;
}

sub determine_type {
    my $self = shift;
    my ($odds) = @_; 
    my @type = ();
    my @priority = ();
    for (keys %$odds) {
        push @type, $_;
        push @priority, $odds->{$_};
    }
    array_random_with_priority(\@type, \@priority);
}

sub determine_selection_type {
    my $self = shift;
    $self->determine_type($self->{selection_odds});
}

sub select_parents {
    my $self = shift;
    no strict 'refs';
    my $type = $self->determine_selection_type;
    my $m = "select_$type";
    $self->$m(@_);
}

sub select_elite {
    my $self = shift;
    my $father;
    my $rating = $self->{rating};
    for (sort keys %$rating) {
        if (!$father) { $father = $rating->{$_}; }
        else { return ($father, $rating->{$_}); }
    }
}

sub select_ranking {
    my $self = shift;
    my @priority;
    my $rating = $self->{rating};
    for (sort { $a <=> $b } keys %{$self->{ranking_selection_odds}}) {
        push @priority, $self->{ranking_selection_odds}{$_};
    }
    my @keys = sort keys %$rating;
    my @members = @keys[0 .. (scalar @priority)];
    my ($father, $rank) = array_random_with_priority(\@members, \@priority);
    splice @members, $rank, 1;
    splice @priority, $rank, 1;
    my $mother = array_random_with_priority(\@members, \@priority);
    return ($rating->{$father}, $rating->{$mother});
}

sub select_roulette {
    my $self = shift;
    my $sum;
    my $rating = $self->{rating};
    my @members = sort { $a <=> $b } keys %$rating;
    my @priority = reverse @members;
    my ($father, $rank) = array_random_with_priority(\@members, \@priority);
    splice @members, $rank, 1;
    splice @priority, $rank, 1;
    my $mother = array_random_with_priority(\@members, \@priority);
    return ($rating->{$father}, $rating->{$mother});
}

sub select_tournament {
    my $self = shift;
    my %selected;
    my $rating = $self->{rating};
    my @keys = keys %$rating;
    my $num = @keys;
    for (my $i = 0; $i < $self->{number_of_tournament_selection} && $i < $num; $i++) {
        my $n = int rand $num;
        if ($selected{$n}) { $i--; }
        else { $selected{$n} = 1; }
    }
    my @members;
    for (keys %selected) {
        push @members, $keys[$_];
    }
    my $father;
    for (sort @members) {
        if (!$father) { $father = $rating->{$_}; }
        else { return ($father, $rating->{$_}); }
    }
}

sub select_random {
    my $self = shift;
    my $rating = $self->{rating};
    my @keys = keys %$rating;
    my $i = int rand @keys;
    my $j = $i;
    while ($j == $i) { $j = int rand @keys; }
    return ($rating->{$keys[$i]}, $rating->{$keys[$j]});
}

sub determine_crossover_type {
    my $self = shift;
    $self->determine_type($self->{crossover_odds});
}

sub crossover {
    my $self = shift;
    no strict 'refs';
    my $type = $self->determine_crossover_type;
    my $m = "crossover_$type";
    $self->$m(@_);
}

sub crossover_one_point {
    my $self = shift;
    my ($father, $mother) = @_;
    my @father = @$father;
    my @mother = @$mother;
    my $top_padding = 2;
    my $len = @father - $top_padding;
    my $n = $top_padding + (int rand $len);
    @father[$n .. ($len - 1)] = @mother[$n .. ($len - 1)];
    return \@father;
}

sub crossover_two_point {
    my $self = shift;
    my ($father, $mother) = @_;
    my @father = @$father;
    my @mother = @$mother;
    my $len = @father;
    my $n = int rand($len - 1);
    my $o = $n + (int rand ($len - $n - 1) + 1);
    @father[$n .. $o] = @mother[$n .. $o];
    return \@father;
}

sub crossover_uniform {
    my $self = shift;
    my ($father, $mother) = @_;
    my @father = @$father;
    my @mother = @$mother;
    my $i = 0;
    for (@mother) {
        if (int rand 2) {
            $father[$i] = $mother[$i];
        }
        $i++;
    }
    return \@father;
}

sub crossover_mutation {
    my $self = shift;
    my ($father, $mother) = @_;
    my @father = @$father;
    my $len = @father;
    my $n = int rand($len - 1);
    my $o = $n + (int rand ($len - $n - 1) + 1);
    @father[$n, $o] = @father[$o, $n];
    return \@father;
}

sub get_elite {
    my $self = shift;
    my $rating = $self->{rating};
    my @rank = sort { $a <=> $b } keys %$rating;
    return $rating->{shift @rank};
}

=head1 AUTHOR

Junichiro NAKAMURA, C<< <jyun16@gmail.com> >>

=head1 COPYRIGHT & LICENSE

Copyright 2010 The Wiz Project. All rights reserved.

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
