package ConstantExporterTest::Bar;

use Wiz::ConstantExporter {
    BAR => 'BAR!',
};

use Wiz::ConstantExporter [qw(bar)];

sub bar {
    return 'BARRRRRRRRRR!!!!!!';
}

1;
