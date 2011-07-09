package ConstantExporterTest::Parent;

use Wiz::ConstantExporter {
    PARENT  => 'PARENT!!',
};

use Wiz::ConstantExporter [qw(parent hoge)];

sub parent {
    return 'PARENT';
}

sub hoge {
    return 'PARENT HOGE';
}

1;
