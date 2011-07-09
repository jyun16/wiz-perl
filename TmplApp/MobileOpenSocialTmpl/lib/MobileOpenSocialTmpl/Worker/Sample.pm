package MobileOpenSocialTmpl::Worker::Sample;

use Wiz::Noose;

with 'Wiz::Worker';

use Data::Dumper;

our $TABLE = 'sample_job';

sub job {
    my $self = shift;
    my ($args, $data) = @_;
    warn 'ARGS: ' . Dumper $args;
    if ($args->{fuga}) {
        die 'DIE';
    }
    return 'RETURN VALUE';
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
