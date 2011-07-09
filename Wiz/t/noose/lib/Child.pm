package Child;

use Wiz::Noose;

has 'child_member' => (is => 'rw');

extends qw(Super);

sub child_method {
    return 'Child method';
}

1;
