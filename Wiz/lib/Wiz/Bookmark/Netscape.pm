package Wiz::Bookmark::Netscape;

use HTML::TreeBuilder;

use Wiz::Noose;
use Wiz::DateTime;
use Wiz::Bookmark;

with 'Wiz::Bookmark::Base';

sub parse {
    my $self = shift;
    my ($data) = @_;
    my $tree = HTML::TreeBuilder->new_from_content($data);
    $self->title($tree->look_down(_tag => "title")->as_text);
    my @elements = $tree->look_down(sub { $_[0]->tag =~ /^(h3|a)$/ && $_[0]->depth == 4 });
    my @children = ();
    for (@elements) { $self->_parse(\@children, $_); }
    $self->data(\@children);
}

sub _parse {
    my $self = shift;
    my ($ret, $element) = @_;
    my %r = ();
    $r{title} = $element->as_text;
    if ($element->attr("href")) { $r{url} = $element->attr("href"); }
    for (qw(add_date last_modified last_visit)) { $element->attr($_) and $r{$_} = Wiz::Bookmark::epoch2date($element->attr($_)); }
    for (qw(private tags)) { defined $element->attr($_) and $r{$_} = $element->attr($_); }
    if ($element->right) {
        my @elements =
            map { $_->tag eq 'dt' ? ($_->content_list)[0] : () } $element->right->content_list;
        my @children = ();
        for (@elements) { $self->_parse(\@children, $_); }
        $r{children} = \@children;
    }
    push @$ret, \%r;
}

sub to_string {
    my $self = shift;
    my $title = $self->title;
    my $ret = <<EOS;
<!DOCTYPE NETSCAPE-Bookmark-file-1>
<META HTTP-EQUIV="Content-Type" CONTENT="text/html; charset=UTF-8">
<TITLE>$title</TITLE>
<H1>$title</H1>
<DL><p>
EOS
    $self->_to_string(\$ret, $self->{data}, "");
    $ret .= "</DL></p>\n";
    return $ret;
}

sub _to_string {
    my $self = shift;
    my ($ret, $children, $tab) = @_;
    $tab .= ' ' x 4;
    for (@$children) {
        if ($_->{children}) {
            $$ret .= "$tab<DT><H3";
            $$ret .= _add_date('add_date', $_);
            $$ret .= _add_date('last_modified', $_);
            $$ret .= ">$_->{title}</H3>\n";
            $$ret .= "$tab<DL><p>\n";
            $self->_to_string($ret, $_->{children}, $tab);
            $$ret .= "$tab</DL><p>\n";
        }
        else {
            $$ret .= qq|$tab<DT><A HREF="$_->{url}"|;
            $$ret .= _add_date('add_date', $_);
            $$ret .= _add_date('last_modified', $_);
            if ($_->{tags}) {
                $$ret .= sprintf ' TAGS="%s"', ref $_->{tags} ? join(',', @{$_->{tags}}): $_->{tags};
            }
            $$ret .= qq|>$_->{title}</A>\n|;
        }
    }
}

sub _add_date {
    my ($target, $data) = @_;
    $data->{$target} or return '';
    my $date = new Wiz::DateTime($data->{$target});
    return sprintf ' %s="%s"', uc $target,  $date->epoch;
}

1;
