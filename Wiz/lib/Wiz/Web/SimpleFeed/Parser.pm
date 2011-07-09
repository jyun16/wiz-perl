package Wiz::Web::SimpleFeed::Parser;

=head1 NAME

Wiz::Web::SimpleFeed::Parser

=head1 VERSION

version 1.0

=cut

use HTML::Parser;
use DateTime::Format::Atom;
use DateTime::Format::RSS;
use LWP::UserAgent;
use Encode qw(encode decode :fallbacks);
use Encode::Guess;

use Wiz::Noose;
use Wiz::Constant qw(:common);
use Wiz::Util::String qw(trim_sp);
use Wiz::DateTime;
use Wiz::Web::SimpleFeed qw(is_feed_mime :feed_type);

our $VERSION = '1.0';

our $FAKE_USER_AGENT = 'Mozilla/5.0';

has parser      => (is  => 'rw');

sub BUILD {
    my $self = shift;
    my $parser = new HTML::Parser(
        process_h   => [ \&process_h, 'self,tag' ],
        start_h => [ \&start_h, 'self,tagname,attr' ],
        end_h   => [ \&end_h, 'self,tagname' ],
        text_h  => [ \&text_h, 'self,dtext,is_cdata' ],
    );
    $parser->utf8_mode(1);

    $parser->xml_mode(TRUE);
    $parser->marked_sections(TRUE);
    $parser->{_d} = {};
    $parser->{_i} = {};
    $parser->{_s} = 'type';
    $parser->{__s} = '';
    $self->parser($parser);
};

sub parse {
    my $self = shift;
    $self->parser->parse(@_);
    return $self->parser->{_d};
}

sub parse_from_feed {
    my $self = shift;
    my ($url, $opts) = @_;
    my $ua = new LWP::UserAgent;
    $ua->agent($FAKE_USER_AGENT);
    for my $method (keys %$opts) {
        $ua->$method($opts->{$method});
    }
    my $res = $ua->get($url);
    if ($res->is_success) {
        $self->parser->parse($res->content);
        return $self->parser->{_d};
    }
    else {
        return {};
    }
}

sub process_h {
    my $self = shift;
    my ($tag) = @_;
    if ($tag =~ /xml version="(.*)" encoding="([^"\s]*).*"/) {
        $self->{_d}{version} = $1;
        $self->{_d}{encoding} = $2;
    }
}

sub _resolve_type {
    my $self = shift;
    my ($el, $attr) = @_;
    my $type;
    if ($el eq 'rdf:RDF') {
        if ($attr->{xmlns} eq 'http://my.netscape.com/rdf/simple/0.9/') { $type = RSS0_9; }
        elsif ($attr->{xmlns} eq 'http://purl.org/rss/1.0/') { $type = RSS1_0; }
    }
    elsif ($el eq 'rss') {
        if ($attr->{version} eq '2.0') { $type = RSS2_0; }
        elsif ($attr->{version} eq '0.91') { $type = RSS0_91; }
    }
    elsif ($el eq 'feed') { $type = ATOM; }
    if ($type) {
        $self->{_d}{type} = $type;
        $self->{_s} = 'meta';
    }
}

sub _resolve_meta {
    my $self = shift;
    my ($el, $attr) = @_;
    my $t = $self->{_d}{type};
    if ($t == ATOM) {
        if ($el eq 'title') { $self->{__s} = 'title'; }
        elsif ($el eq 'link') {
            is_feed_mime($attr->{type}) and 
                $self->{_d}{feed_url} = $attr->{href};
        }
    }
    else {
        if ($el eq 'title') { $self->{__s} = 'title'; }
        elsif ($el eq 'link') { $self->{__s} = 'link'; }
        elsif ($el eq 'description') { $self->{__s} = 'description'; }
    }
}

sub _resolve_item {
    my $self = shift;
    my ($el, $attr) = @_;
    my $t = $self->{_d}{type};
    if ($t == ATOM) {
        if ($el eq 'title') { $self->{__s} = 'title'; }
        elsif ($el eq 'id') { $self->{__s} = 'id'; }
        elsif ($el eq 'link') { $self->{_i}{url} = $attr->{href}; }
        elsif ($el eq 'content') { $self->{__s} = 'content'; }
        elsif ($el eq 'created') { $self->{__s} = 'date'; }
        elsif ($el eq 'published') { $self->{__s} = 'date'; }
        elsif ($el eq 'dc:subject') { $self->{__s} = 'tags'; }
        elsif ($el eq 'category') {
            push @{$self->{_i}{tags}}, $attr->{term};
        }
    }
    else {
        if ($el eq 'title') { $self->{__s} = 'title'; }
        elsif ($el eq 'guid') { $self->{__s} = 'id'; }
        elsif ($el eq 'link') { $self->{__s} = 'link'; }
        elsif ($el eq 'description') { $self->{__s} = 'description'; }
        elsif ($el eq 'content:encoded') { $self->{__s} = 'content'; }
        elsif ($el eq 'dc:date') { $self->{__s} = 'date'; }
        elsif ($el eq 'pubDate') { $self->{__s} = 'date'; }
        elsif ($el eq 'dc:subject') { $self->{__s} = 'tags'; }
    }
}

sub start_h {
    my $self = shift;
    my ($el, $attr) = @_;
    if ($self->{_s} eq 'meta') {
        _resolve_meta($self, $el, $attr);
        if ($el eq 'item' or $el eq 'entry') { $self->{_s} = 'item'; }
    }
    elsif ($self->{_s} eq 'type') {
        _resolve_type($self, $el, $attr);
    }
    elsif ($self->{_s} eq 'item') {
        _resolve_item($self, $el, $attr);
    }
}

sub text_h {
    my $self = shift;
    my ($text, $is_cdata) = @_;
    my $d;
    if ($self->{_s} eq 'item') { $d = $self->{_i}; }
    elsif ($self->{_s} eq 'meta') { $d = $self->{_d}; }
    if ($self->{__s} eq 'title') { $d->{title} = _encode_perlqq($text); }
    elsif ($self->{__s} eq 'description') { $d->{description} = _encode_perlqq($text); }
    elsif ($self->{__s} eq 'content') {
        $d->{content} = trim_sp(_encode_perlqq($text));
    }
    elsif ($self->{__s} eq 'date') {
        my $f;
        if ($self->{_d}{type} eq 'Atom') { $f = new DateTime::Format::Atom; }
        else { $f = new DateTime::Format::RSS; }
        if ($text) {
            my $dt = $f->parse_datetime($text);
            $dt and $d->{date} = $dt->ymd . ' ' . $dt->hms;
        }
    }
    elsif ($self->{__s} eq 'link') { $d->{url} = $text; }
    elsif ($self->{__s} eq 'tags') { push @{$d->{tags}}, $text; }
    elsif ($self->{__s} eq 'link_xml') { $d->{feed_url} = $text; }
    elsif ($self->{__s} eq 'id') { $d->{id} = $text; }
    $self->{__s} = '';
}

sub end_h {
    my $self = shift;
    my ($el) = @_;
    if ($el eq 'item' or $el eq 'entry') {
        push @{$self->{_d}{children}}, $self->{_i};
        $self->{_i} = {};
    }
}

sub _encode_perlqq {
    my ($text) = @_;
#    encode('utf8', $text, Encode::FB_PERLQQ);
    return $text;
}

=head1 AUTHOR

Junichiro NAKAMURA, C<< <jyun16@gmail.com> >>

=head1 COPYRIGHT & LICENSE

Copyright 2008,2009 The Wiz Project. All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice,
this list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright
notice, this list of conditions and the following disclaimer in the
documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE WIZ PROJECT ``AS IS'' AND ANY
EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED.  IN NO EVENT SHALL THE WIZ PROJECT OR CONTRIBUTORS BE
LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER
IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OROTHERWISE)
ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
THE POSSIBILITY OF SUCH DAMAGE.

The views and conclusions contained in the software and documentation are
those of the authors and should not be interpreted as representing official
policies, either expressed or implied, of the Wiz Project.

Additionally, the followings are recommended for the developers
to modify/improve/extend Wiz. Please send modified code/patch to mail list,
wiz-perl@googlegroups.com.
The source you sent will be merged into Wiz package.
We welcome anyone who cooperates with us in developing this software.

We'll invite you to this project's member.

=cut

1;

__END__


