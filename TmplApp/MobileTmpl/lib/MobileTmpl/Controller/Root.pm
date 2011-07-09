package MobileTmpl::Controller::Root;

use Wiz::Noose;

extends qw(
    Wiz::Web::Framework::Controller
);

sub index {
    my $self = shift;
    my ($c) = @_;
    $c->redirect('/mobile/');
}

1;
