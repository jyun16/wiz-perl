package Super;

use Wiz::Noose;

has 'member' => (is => 'rw', default => 'MEMBER_DEFAULT');
has 'required_member' => (is => 'rw', required => 1);

sub super_method {
    return 'Super method';
}

1;
