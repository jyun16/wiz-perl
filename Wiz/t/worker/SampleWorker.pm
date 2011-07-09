package SampleWorker;

use Any::Moose;

with 'Wiz::Worker';

use Data::Dumper;

sub job {
    my $self = shift;
    my ($args, $data) = @_;
    warn 'ARGS: ' . Dumper $args;
    if ($args->{fuga}) {
        die 'ABOOOOOOON!!!!!!';
    }
    return 'HOGEHOGEEEEEEEEEE';
}

sub succeed {
    my $self = shift;
    my ($args, $data) = @_;
    warn 'SUCCEED: ' . Dumper $args;
}

sub fail {
    my $self = shift;
    my ($args, $data) = @_;
    warn 'FAIL: ' . Dumper $args;
}

1;
