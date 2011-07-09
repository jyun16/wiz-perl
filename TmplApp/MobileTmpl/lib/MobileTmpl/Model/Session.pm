package MobileTmpl::Model::Session;

use Wiz::Noose;

extends qw(
    Wiz::Web::Framework::Model
);

our @CREATE = qw(
id
session_data
expires
);
our @MODIFY = @CREATE;
our $PRIMARY_KEY = 'id';
our $MODIFY_KEY = $PRIMARY_KEY;

=head1 AUTHOR

=head1 COPYRIGHT & LICENSE

=cut

1;
