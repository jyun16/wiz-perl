package OpenSocialTmpl::Controller::AllForm::List;

use Wiz::Noose;

extends qw(
    Wiz::Web::Framework::Controller::List
);

our @AUTOFORM = qw(all_form list);
our $MODEL = 'AllForm';
our $SESSION_NAME = __PACKAGE__;

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

