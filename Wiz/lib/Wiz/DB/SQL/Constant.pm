package Wiz::DB::SQL::Constant;

use strict;
use warnings;

=head1 NAME

Wiz::DB::SQL::Constant

=head1 VERSION

version 1.0

=cut

our $VERSION = '1.0';

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut

=head1 EXPORT

 sql_query   => {
     SQL_QUERY_WHERE         => 0,
     SQL_QUERY_WHERE_NONE    => 1,
 }
 
 join        => {
     CROSS_JOIN              => 1,
     INNER_JOIN              => 2,
     LEFT_JOIN               => 3,
     RIGHT_JOIN              => 4,
     DIRECT_JOIN             => 5,
 }

 like    => {
     LIKE        => 1,
     PRE_LIKE    => 2,    
     SUF_LIKE    => 3,    
 }

 null        => {
     IS_NULL                 => sub { 1 },
     IS_NOT_NULL             => sub { 2 },
 }

 'common' => [qw(sql_query join null)]

=cut

use Wiz::ConstantExporter {
    SQL_QUERY_WHERE         => 0,
    SQL_QUERY_WHERE_NONE    => 1,
}, 'sql_query';

use Wiz::ConstantExporter {
    CROSS_JOIN              => 1,
    INNER_JOIN              => 2,
    LEFT_JOIN               => 3,
    RIGHT_JOIN              => 4,
    DIRECT_JOIN             => 5,
}, 'join';

use Wiz::ConstantExporter {
    LIKE        => 1,
    PRE_LIKE    => 2,    
    SUF_LIKE    => 3,    
}, 'like';

use Wiz::ConstantExporter {
    IS_NULL                 => sub { 1 },
    IS_NOT_NULL             => sub { 2 },
}, 'null';

use Wiz::ConstantExporter 'common' => [qw(sql_query join null)];

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

