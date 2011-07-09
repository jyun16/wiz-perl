package Wiz::Bookmark::Atom;

use Wiz::Noose;
use Wiz::Web::SimpleFeed qw(:feed_type create_feed);
use Wiz::Web::SimpleFeed::Parser;

with 'Wiz::Bookmark::Base';

sub parse {
    my $self = shift;
    my ($data) = @_;
    my $parser = new Wiz::Web::SimpleFeed::Parser;
    my $res = $parser->parse($data);
    for (qw(title url description author)) {
        $res->{$_} ne '' and $self->$_($res->{$_});
    }
    $self->data($res->{children});
    return $res;
}

sub to_string {
    my $self = shift;
    return create_feed(ATOM, {
        title       => $self->title,
        url         => $self->url,
        description => $self->description,
        author      => $self->author,
        children    => $self->data,
    });
}

1;
