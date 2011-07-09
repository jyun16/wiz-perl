package TmplApp::Controller::AllForm::List;

use Wiz::Noose;
use Wiz::Constant qw(:common);
use Wiz::DB::SQL::Constant qw(:like);

extends qw(
    Wiz::Web::Framework::Controller::List
);

our @AUTOFORM = qw(all_form_list);
our $MODEL = 'AllForm';
our $SESSION_NAME = __PACKAGE__;
our %LIKE_SEARCH = (
    textarea        => LIKE,
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

sub _append_search_param {
    my $self = shift;
    my ($c, $param, $m, $af) = @_;
    my $p = $c->req->params;
    for (qw(created_time)) {
        $af->value($_) ne '' and
            push @{$param->{-and}}, [ '>=', $_, $af->value($_) ];
        $af->value("${_}_end") ne "" and
            push @{$param->{-and}}, [ '<=', $_, $af->value("${_}_end") ];
    }
}

=head1 AUTHOR

=head1 COPYRIGHT & LICENSE

=cut

1;

__END__

