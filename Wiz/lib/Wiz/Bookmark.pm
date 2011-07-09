package Wiz::Bookmark;

use Carp;

use Clone qw(clone);

use Wiz::Noose;

with 'Wiz::Bookmark::Base';

use Wiz::Constant qw(:common);
use Wiz::Bookmark::Netscape;
use Wiz::Bookmark::OPML;
use Wiz::Bookmark::Atom;
use Wiz::Bookmark::RSS2_0;
use Wiz::Bookmark::RSS1_0;
use Wiz::Bookmark::RSS0_91;
use Wiz::Bookmark::RSS0_9;

use Wiz::ConstantExporter {
    BOOKMARK_TYPE_UNKNOWN   => 0,
    BOOKMARK_TYPE_NETSCAPE  => 1,
    BOOKMARK_TYPE_OPML      => 2,
    BOOKMARK_TYPE_RSS0_9    => 101,
    BOOKMARK_TYPE_RSS0_91   => 102,
    BOOKMARK_TYPE_RSS1_0    => 110,
    BOOKMARK_TYPE_RSS2_0    => 120,
    BOOKMARK_TYPE_ATOM      => 200,
}, 'bookmark_type';

use Wiz::ConstantExporter [qw(epoch2date dig_bookmark_type convert2tags_data convert_tags_data2normal_data bookmark_label2type)];

our %BOOKMARK_CLASS = (
    BOOKMARK_TYPE_NETSCAPE()    => 'Wiz::Bookmark::Netscape',
    BOOKMARK_TYPE_OPML()        => 'Wiz::Bookmark::OPML',
    BOOKMARK_TYPE_ATOM()        => 'Wiz::Bookmark::Atom',
    BOOKMARK_TYPE_RSS0_9()      => 'Wiz::Bookmark::RSS0_9',
    BOOKMARK_TYPE_RSS0_91()     => 'Wiz::Bookmark::RSS0_91',
    BOOKMARK_TYPE_RSS1_0()      => 'Wiz::Bookmark::RSS1_0',
    BOOKMARK_TYPE_RSS2_0()      => 'Wiz::Bookmark::RSS2_0',
);

our %LABEL2TYPE = (
    'netscape'  => BOOKMARK_TYPE_NETSCAPE,
    'atom'      => BOOKMARK_TYPE_ATOM,
    'rss0_9'    => BOOKMARK_TYPE_RSS0_9,
    'rss0_91'   => BOOKMARK_TYPE_RSS0_91,
    'rss1_0'    => BOOKMARK_TYPE_RSS1_0,
    'rss2_0'    => BOOKMARK_TYPE_RSS2_0,
    'opml'      => BOOKMARK_TYPE_OPML,
);

sub BUILD {
    my $self = shift;
    my ($args) = @_;
    if ($args->{type} ne '') {
        $self->type($args->{type});
    }
}

sub type {
    my $self = shift;
    my ($type) = @_;
    if ($type ne '') {
        $type !~ /^\d*$/ and $type = bookmark_label2type($type); 
        $self->{type} = $type;
        bless $self, $BOOKMARK_CLASS{$type};
    }
    return $self->{type};
}

sub parse {
    my $self = shift;
    my ($data) = @_;
    my $type = dig_bookmark_type($data);
    $self->type($type);
    $self->parse($data);
}

sub to_string {
    my $self = shift;
    my ($type) = @_;
    $type ||= $self->type;
    $self->to_string;
}

sub epoch2date {
    my ($epoch) = @_;
    if (length $epoch > 10) { $epoch = substr $epoch, 0, -6; }
    my $date = new Wiz::DateTime;
    $date->set_epoch($epoch);
    return $date->to_string;
}

sub dig_bookmark_type {
    my ($data) = @_;
    $data = substr $data, 0, 300;
    $data =~ s/\r?\n//g;

    if ($data =~ /^\Q<!DOCTYPE NETSCAPE-Bookmark-file-1>\E/) { BOOKMARK_TYPE_NETSCAPE; }
    elsif ($data =~ /^\Q<?xml version="1.0" encoding="utf-8"?>\E\s*\Q<feed\E/i) { BOOKMARK_TYPE_ATOM; }
    elsif ($data =~ /^\Q<?xml version="1.0" encoding="utf-8"?>\E\s*\Q<opml\E/i) { BOOKMARK_TYPE_OPML; }
    elsif (my @r = $data =~ m#<rss\s+.*version="(.*?)"#) {
        if ($r[0] eq '0.91') {
            return BOOKMARK_TYPE_RSS0_91;
        }
        elsif ($r[0] eq '2.0') {
            return BOOKMARK_TYPE_RSS2_0;
        }
    }
    elsif ($data =~ /^\Q<?xml version="1.0" encoding="utf-8"?>\E\s*\Q<rdf:RDF\E/i) {
        if ($data =~ m#\Qxmlns="http://my.netscape.com/rdf/simple/0.9/"\E#i) {
            return BOOKMARK_TYPE_RSS0_9;
        }
        elsif ($data =~ m#\Qxmlns="http://purl.org/rss/1.0/"\E#i) {
            return BOOKMARK_TYPE_RSS1_0;
        }
    }
    elsif ($data =~ /^\Q<rss version="0.91"\E/i) {
        return BOOKMARK_TYPE_RSS0_91;
    }
    else { BOOKMARK_TYPE_UNKNOWN; }
}

sub convert2tags_data {
    my ($data) = @_;
    $data = clone $data;
    my @ret = ();
    _convert2tags_data(\@ret, $data);
    return \@ret;
}

sub _convert2tags_data {
    my ($ret, $data, $tags) = @_;
    for (@$data) {
        my $tag;
        my $children = $_->{children};
        delete $_->{children};
        unless ($_->{url} eq '' and $_->{feed_url} eq '') {
            $tags ne '' and $_->{tags} = $tags;
            push @$ret, $_;
        }
        else {
            if ($_->{text} ne '') { $tag = $_->{text}; }
            elsif ($_->{title} ne '') { $tag = $_->{title}; }
        }
        _convert2tags_data($ret, $children, $tags ne '' ? "$tags,$tag" : $tag );
    }
}

sub create_convert_tags_data2normal_data_tree {
    my ($hash, $list, $value) = @_;
    my $d = shift @$list;
    if (defined $d) {
        if (defined $value and @$list < 1) {
            push @{$hash->{$d}{_data}}, $value;
            return $value;
        }
        else {
            return create_convert_tags_data2normal_data_tree($hash->{$d}, $list, $value);
        }
    }
    else {
        return $hash;
    }
}

sub convert_tags_data2normal_data {
    my ($data) = @_;
    $data = clone $data;
    my %tree = ();
    my @ret = ();
    for my $d (@$data) {
        my $tags = ref $d->{tags} ? $d->{tags} : [ split /,/, $d->{tags} ];
        delete $d->{tags};
        unless (@$tags) { push @ret, $d; }
        create_convert_tags_data2normal_data_tree(\%tree, $tags, $d);
    }
    _convert_tags_data2normal_data(\@ret, \%tree);
    return \@ret;
}

sub _convert_tags_data2normal_data {
    my ($ret, $tree) = @_;
    for my $tag (keys %$tree) {
        my @children = ();
        if ($tree->{$tag}{_data}) {
            push @children, @{$tree->{$tag}{_data}};
            delete $tree->{$tag}{_data};
        }
        _convert_tags_data2normal_data(\@children, $tree->{$tag});
        push @$ret, {
            text        => $tag,
            children    => \@children,
        };
    }
}

sub bookmark_label2type {
    return $LABEL2TYPE{shift()};
}

1;
