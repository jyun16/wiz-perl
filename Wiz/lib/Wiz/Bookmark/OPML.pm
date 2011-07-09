package Wiz::Bookmark::OPML;

use XML::Simple;

use Wiz::Noose;
use Wiz::Util::Hash qw(create_ordered_hash);

with 'Wiz::Bookmark::Base';

has 'version' => (is => 'rw', default => '1.0');

sub parse {
    my $self = shift;
    my ($opml) = @_;
    my $data = XMLin($opml, ForceArray => ['outline']);
    $self->title($data->{head}{title});
    $self->version($data->{version});
    $self->data($self->_parse($data->{body}{outline}));
}

sub _parse {
    my $self = shift;
    my ($outline) = @_;
    my @ret = ();
    for (@$outline) {
        my %r = ();
        _set_parsed_data(\%r, $_);
        if ($_->{outline}) { $r{children}    = $self->_parse($_->{outline}); }
        push @ret, \%r;
    }
    return \@ret;
}

sub _set_parsed_data {
    my ($r, $data) = @_;
    if ($data->{title} ne '') { $r->{title} = $data->{title}; }
    elsif ($data->{text} ne '') {$r->{text} = $data->{text}; }
    $data->{htmlUrl} and $r->{url} = $data->{htmlUrl};
    $data->{xmlUrl} and $r->{feed_url} = $data->{xmlUrl};
}

sub complement_children {
    my $self = shift;
    my @ret = ();
    $self->_complement_children(\@ret, $self->{data});
    return \@ret;
}

sub _complement_children {
    my $self = shift;
    my ($ret, $children) = @_;
    for (@$children) {
        my %child = ();
        $_->{title} ne '' and $child{title} = $_->{title};
        $_->{text} ne '' and $child{text} = $_->{text};
        $_->{url} and $child{htmlUrl} = $_->{url};
        $_->{feed_url} and $child{xmlUrl} = $_->{feed_url};
        $child{text} ||= $child{title};
        if ($_->{children}) {
            my @r = ();
            $self->_complement_children(\@r, $_->{children});
            $child{outline} = \@r;
        }
        else {
            $child{type} = 'rss';
        }
        push @$ret, \%child;
    }
}

sub to_string {
    my $self = shift;
    my $opml = create_ordered_hash;
    $opml->{version} = "1.0",
    $opml->{head} = {
        title   => [ $self->title ],
    };
    my $children = $self->complement_children;
    $opml->{body} = {
        outline => $children
    };
    return XMLout(
        { opml => $opml },
        XMLDecl     => '<?xml version="1.0" encoding="UTF-8"?>',
        RootName    => undef,
        NoSort      => 1,
    );
}

1;
