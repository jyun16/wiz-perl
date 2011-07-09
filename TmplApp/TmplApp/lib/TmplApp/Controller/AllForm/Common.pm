package TmplApp::Controller::AllForm::Common;

use Wiz::Noose;
use Wiz::Constant qw(:common);

sub _before_index {
    my $self = shift;
    my ($c, $af, $p, $s) = @_;
   unless ($p->{search_back_result}) {
        $s->{finish_redirect_dest} = $c->req->referer;
    }
}

=head1 AUTHOR

=head1 COPYRIGHT & LICENSE

=cut

1;

__END__
