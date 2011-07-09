package TmplApp::Model::Admin;

use Wiz::Noose;
use Wiz::Constant qw(:common);
use Wiz::Web::Framework::Model::Filters qw(SHA512_BASE64);

extends qw(
    Wiz::Web::Framework::Model
);

our @CREATE = qw(userid email password created_time);
our @MODIFY = @CREATE;
our @SEARCH = qw(id userid email);
our $PRIMARY_KEY = 'id';
our %CREATE_FILTERS = (
    password    => SHA512_BASE64,
);

=head1 AUTHOR

=head1 COPYRIGHT & LICENSE

=cut

1;
