package Wiz::Bookmark::Base;

use Wiz::Noose;

has 'title'         => (is => 'rw');
has 'url'           => (is => 'rw');
has 'description'   => (is => 'rw');
has 'author'        => (is => 'rw');
has 'data'          => (is => 'rw', default => sub { [] });
#has 'type'          => (is => 'rw');
has 'version'       => (is => 'rw', default => '1.0');

requires 'parse';
requires 'to_string';

sub add {
    my $self = shift;
    my ($data) = @_;
    push @{$self->{data}}, $data;
}

1;
