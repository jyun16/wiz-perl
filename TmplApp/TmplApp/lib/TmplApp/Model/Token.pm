package TmplApp::Model::Token;

use Wiz::Noose;

extends qw(
    Wiz::Web::Framework::Model::Token
);

our @ADDON = qw(member_id);
our @CREATE = (@ADDON, qw(token type data created_time));
our @MODIFY = @CREATE;
our @SEARCH = (@CREATE, qw(id last_modified delete_flag));
our $PRIMARY_KEY = 'id';

=head1 AUTHOR

=head1 COPYRIGHT & LICENSE

=cut

1;

__END__
~
