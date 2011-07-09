package Wiz::Bookmark::RSS0_9;

use Wiz::Noose;
use Wiz::Web::SimpleFeed qw(:feed_type create_feed);

extends 'Wiz::Bookmark::RSS';

sub to_string {
    my $self = shift;
    return create_feed(RSS0_9, {
        title       => $self->title,
        url         => $self->url,
        description => $self->description,
        author      => $self->author,
        children    => $self->data,
    });
}

1;
