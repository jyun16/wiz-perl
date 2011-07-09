package Wiz::Bookmark::RSS2_0;

use Wiz::Noose;
use Wiz::Web::SimpleFeed qw(:feed_type create_feed);

extends 'Wiz::Bookmark::RSS';

sub to_string {
    my $self = shift;
    return create_feed(RSS2_0, {
        title       => $self->title,
        url         => $self->url,
        description => $self->description,
        author      => $self->author,
        children    => $self->data,
    });
}

1;
