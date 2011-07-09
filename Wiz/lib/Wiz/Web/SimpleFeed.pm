package Wiz::Web::SimpleFeed;

use strict;
use warnings;

=head1 NAME

Wiz::Web::SimpleFeed

=head1 VERSION

version 1.0

=cut

use LWP::UserAgent;
use HTTP::Request;
use HTML::Parser;
use XML::Feed;
use XML::Feed::Entry;

use Wiz::Constant qw(:common);
use Wiz::DateTime;

no warnings 'uninitialized';

our $VERSION = '1.0';

=head1 EXPORTS

 feed_type => {
     RSS0_9  => 1,
     RSS0_91 => 2,
     RSS1_0  => 10,
     RSS2_0  => 20,
     ATOM    => 100,
 }

=cut

use Wiz::ConstantExporter {
    RSS0_9  => 1,
    RSS0_91 => 2,
    RSS1_0  => 10,
    RSS2_0  => 20,
    ATOM    => 100,
}, 'feed_type';

use Wiz::ConstantExporter [qw(
    find_feeds
    is_feed_mime
    feed_exists
    create_feed
)];

our $FEED_EXT = qr/\.(?:rss|xml|rdf)$/;
our %FEED_MIME = (
    'text/xml'                  => 1,
    'application/xml'           => 1,
    'application/rss+xml'       => 1,
    'application/rdf+xml'       => 1,
    'application/atom+xml'      => 1,
    'application/x.atom+xml'    => 1,
);

our $FAKE_USER_AGENT = 'Mozilla/5.0';

sub feed_exists {
    my @feed = XML::Feed->find_feeds(shift);
    return @feed ? TRUE : FALSE;
}

sub is_feed_mime {
    return $FEED_MIME{-shift} ? TRUE : FALSE;
}

sub create_feed {
    my ($type, $data) = @_;
    my $type_name = 'RSS';
    my %type_option; 
    if ($type == RSS0_9) { $type_option{version} = '0.9'; }
    elsif ($type == RSS0_91) { $type_option{version} = '0.91'; }
    elsif ($type == RSS1_0) { $type_option{version} = '1.0'; }
    elsif ($type == RSS2_0) { $type_option{version} = '2.0'; }
    elsif ($type == ATOM) { $type_name = 'Atom'; }
    my $rss = new XML::Feed($type_name, %type_option);
    my $utf8_decode_flag = FALSE;
    for (qw(url title link author description)) { utf8::is_utf8($data->{$_}) or utf8::decode($data->{$_}); }
    for (qw(title description link author)) { $data->{$_} ne '' and $rss->$_($data->{$_}); }
    $data->{url} ne '' and $rss->link($data->{ulr});
    my $children = $data->{children};
    if (@$children and !utf8::is_utf8($children->[0]{title})) {
        $utf8_decode_flag = TRUE;
    }
    for (@$children) {
        defined $_->{title} or $_->{title} = '';
        defined $_->{description} or $_->{description} = '';
        my $children = new XML::Feed::Entry($type_name);
        if ($utf8_decode_flag) {
            utf8::decode($_->{title});
            utf8::decode($_->{description});
        }
        $children->title($_->{title});
        $children->id($_->{url});
        $children->link($_->{url});
        $children->summary($_->{description});
        my @tags;
        if (ref $_->{tags} eq 'ARRAY') { @tags = @{$_->{tags}}; }
        else { @tags = split /,/, $_->{tags}; }
        for my $tag (@tags) { $children->tags($tag); }
        $children->content($_->{description});
        my $date = $_->{date} ? new Wiz::DateTime($_->{date}) : new Wiz::DateTime;
        $children->issued($date->_dt);
        $children->modified($date->_dt);
        $rss->add_entry($children);
    }
    return $rss->as_xml;
}

# Appended timeout and error handling to Feed::Find::find.
sub find_feeds {
    my ($url, $opt) = @_;
    my $ua = LWP::UserAgent->new;
    $ua->agent($FAKE_USER_AGENT);
    $ua->parse_head(0);
    $opt->{timeout} and $ua->timeout($opt->{timeout});
    my $req = HTTP::Request->new(GET => $url);
    my $p = HTML::Parser->new(api_version => 3,
        start_h => [ \&_find_links, 'self,tagname,attr' ]);
    $p->{base_url} = $url;
    $p->{feeds} = [];
    my $res = $ua->request($req, sub {
        my($chunk, $res, $proto) = @_;
        if ($FEED_MIME{$res->content_type}) {
            push @{ $p->{feeds} }, $url;
        }
        $p->parse($chunk);
    });
    unless ($res->is_success) {
        return {
            code    => $res->code,
            message => $res->message,
        };
    }
    return $p->{feeds};
}

sub _find_links {
    my ($p, $tag, $attr) = @_;
    my $base_url = $p->{base_url};
    if ($tag eq 'link') {
        return unless $attr->{rel};
        my %rel = map { $_ => 1 } split /\s+/, lc($attr->{rel});
        (my $type = lc $attr->{type}) =~ s/^\s*//;
        $type =~ s/\s*$//;
        push @{ $p->{feeds} }, URI->new_abs($attr->{href}, $base_url)->as_string
                if $FEED_MIME{$type} &&
                   ($rel{alternate} || $rel{'service.feed'});
    }
    elsif ($tag eq 'base') {
        $p->{base_url} = $attr->{href} if $attr->{href};
    }
    elsif ($tag =~ /^(?:meta|isindex|title|script|style|head|html)$/) {
    }
    elsif ($tag eq 'a') {
        my $href = $attr->{href} or return;
        my $url = URI->new($href);
        push @{ $p->{feeds} }, URI->new_abs($href, $base_url)->as_string
            if $url->path =~ /$FEED_EXT/io;
    }
    else {
        $p->eof if @{ $p->{feeds} };
    }
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


