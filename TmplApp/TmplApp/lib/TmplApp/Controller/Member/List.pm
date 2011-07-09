package TmplApp::Controller::Member::List;

use Wiz::Noose;

extends qw(
    Wiz::Web::Framework::Controller::Auth
    Wiz::Web::Framework::Controller::List
);

our @AUTOFORM = qw(member_list);
our $MODEL = 'Member';
our $SESSION_NAME = __PACKAGE__;
our $AUTHZ_LABEL = 'admin';
our $AUTH_FAIL_REDIRECT = 1;
our $AUTH_FAIL_DEST = '/admin/login';

our %AUTH_TARGET = (
    '&index'   => {
        admin   => 1,
    }
);

sub __before_index {
    my $self = shift;
    my ($c, $af, $p, $s) = @_;
    if ($p->{search_back}) {
        my $stash = $c->stash;
        if ($p->{referer}) { $stash->{referer} = $p->{referer}; }
        else { $stash->{referer} = $c->req->referer; }
    }
}

=head1 AUTHOR

=head1 COPYRIGHT & LICENSE

=cut

1;

__END__

