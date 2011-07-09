package Interface;

use Wiz::Noose;

has 'member' => (is => 'rw');
has 'required_member' => (is => 'rw', required => 1);

requires 'needed_method';

1;
