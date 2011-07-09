package TestPackage;

use strict;
use warnings;

use lib '../../lib';

my $const;

BEGIN {
    $const = {
        FROM_HASH_1 => 'from_hash_1',
        FROM_HASH_2 => 'from_hash_2',
    };
};

use Wiz::ConstantExporter $const, 'from_hash';

#  Export Constant with a name 'key1'
use Wiz::ConstantExporter {
    KEY1_1  => 1,
    KEY1_2  => 'value1',
}, 'const1';

#  Export Constant with no name(expecting to be assigned default name 'const')
use Wiz::ConstantExporter {
    KEY2_1  => 2,
    KEY2_2  => 'value2',
};

#  Export Subroutine with a name 'sub1'
use Wiz::ConstantExporter [ qw(func1 func2) ], 'sub1';

#  Export Subroutine with no name(expecting to be assigned default name 'sub')
use Wiz::ConstantExporter [ qw(func3 func4) ];

#  Export Alias with a name 'alias1'
use Wiz::ConstantExporter 'alias1' => [ qw(const1 sub1) ];

sub func1 { "Function no.1" };
sub func2 { "Function no.2" };
sub func3 { "Function no.3" };
sub func4 { "Function no.4" };

1;
