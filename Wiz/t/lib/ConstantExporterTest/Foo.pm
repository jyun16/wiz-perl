package ConstantExporterTest::Foo;

use Wiz::ConstantExporter {
    FOO    => 'FOO',    
};

use Wiz::ConstantExporter [qw(foo)];

sub foo {
    return 'FOO';
}

1;
