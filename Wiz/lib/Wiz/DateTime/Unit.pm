package Wiz::DateTime::Unit;

use strict;
use warnings;
use Scalar::Util ();

=head1 NAME

Wiz::DateTime::Unit - unit for calcuration of Wiz::DateTime

=head1 VERSION

version 1.0

=cut

our $VERSION = '1.0';

=head1 SYNOPSIS

=head1 DESCRIPTION

If you use this module, the following constants are automatically exported.

 YEAR
 MONTH
 WEEKDAY
 DAY
 HOUR
 MINUTE
 SECOND

In the above, YEAR, MONTH and WEEKDAY is a bit special. The rest is simply second.
YEAR, MONTH and WEEKDAY are Wiz::DateTime::Unit object.
If you use them for the operation of Wiz::DateTime, it may be good.

 $dt = Wiz::DateTime->new('2008/01/31');
 $dt += MONTH; # $dt is 2008/02/29
 $dt += YEAR;  # $dt is 2009/02/28

{end_of_month => limit} option is added

=head1 METHODS

=head2 $bool = is_unit

 YEAR->is_unit;
 MONTH->is_unit;
 WEEKDAY->is_unit;

It returns the object is Wiz::DateTime::Unit or not.

=head1 SEE ALSO

L<Wiz::DateTime>
L<Wiz::DateTime::Delta>

=head1 AUTHOR

Kato Atsushi, C<< <kato@adways.net> >>

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

use Carp ();
use Readonly;
use overload '""'   => sub { shift },
             'eq'   => sub { shift },
             '*'    => \&_multiply  ,
             '+'    => \&_add       ,
             '-'    => \&_minus     ,
             'bool' => sub {
                 my $self = shift;
                 Scalar::Util::reftype $self eq 'ARRAY' ? @{$self} : ${$self}
               };

use base qw/Exporter/;

our @EXPORT_SUB = qw();
our @EXPORT_CONST = qw(YEAR MONTH WEEKDAY DAY HOUR MINUTE SECOND);
our @EXPORT_OK = (@EXPORT_SUB, @EXPORT_CONST);

our %EXPORT_TAGS = (
    'sub'       => \@EXPORT_SUB,
    'const'     => \@EXPORT_CONST,
    'all'       => \@EXPORT_OK,
);

# new is used to create constant value. so $unit shouldn't be modified.
sub _new {
    my $class = shift;
    Readonly my $unit => 1;
    return bless \$unit, $class;
}

sub _multiply {
    my $class = ref(my $self = shift);
    my $unit  = $$self * shift;
    return bless \$unit, $class;
}

sub _add {
    my $class = ref(my $self = shift);
    my $other = shift;
    my $to_minus = shift;
    my @other;
    my $reftype = Scalar::Util::reftype $other || '';

    if($reftype eq 'SCALAR'){
        $other *= -1 if $to_minus;
        @other = $other;
    } elsif ($reftype eq 'ARRAY') {
        @other = @$other;
    } else {
        @other = $other;
    }

    if(Scalar::Util::reftype $self eq 'ARRAY'){
        push @$self, @other;
        return $self;
    } else {
        return bless [$self, @other], __PACKAGE__;
    }
}

sub _minus {
    my $self = shift;
    return $self->_add(@_, 1);
}

sub is_unit {
    1;
}

BEGIN {
    push @Wiz::DateTime::Unit::Year::ISA, 'Wiz::DateTime::Unit';
    push @Wiz::DateTime::Unit::Month::ISA, 'Wiz::DateTime::Unit';
    push @Wiz::DateTime::Unit::Weekday::ISA, 'Wiz::DateTime::Unit';
}

use constant {
    YEAR    => Wiz::DateTime::Unit::Year->_new,
    MONTH   => Wiz::DateTime::Unit::Month->_new,
    WEEKDAY => Wiz::DateTime::Unit::Weekday->_new,
    DAY     => 86_400,
    HOUR    =>  3_600,
    MINUTE  =>     60,
    SECOND  =>      1,
};

1;
