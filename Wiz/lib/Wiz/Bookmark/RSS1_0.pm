package Wiz::Bookmark::RSS1_0;

use Wiz::Noose;
use Wiz::Web::SimpleFeed qw(:feed_type create_feed);

extends 'Wiz::Bookmark::RSS';

sub to_string {
    my $self = shift;
    return create_feed(RSS1_0, {
        title       => $self->title,
        children    => $self->data,
    });
}

1;
