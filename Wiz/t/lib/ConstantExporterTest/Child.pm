package ConstantExporterTest::Child;

use base qw(Class::Accessor::Fast ConstantExporterTest::Parent);

use ConstantExporterTest::Parent qw(:all);
#use ConstantExporterTest::Foo qw(:all);

use Wiz::ConstantExporter {
    CHILD   => 'CHILD',    
};

use Wiz::ConstantExporter [qw(child hoge)];

sub child {
    return 'CHILD';
}

sub hoge {
    return 'CHILD HOGE';
}

1;
