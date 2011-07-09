package Wiz::Web::Feed;

use strict;
use warnings;

no warnings 'uninitialized';

=head1 NAME

Wiz::Web::Feed

=head1 VERSION

version 0.1

=cut

our $VERSION = '0.1';

=head1 SYNOPSIS

 my $wwf  = Wiz::Web::Feed->new('http://example.com/archive?id=123')->parse_feed();
 $wwf->url;          # http://example.com/archive?id=123
 $wwf->feed;         # ref Data::Feed::RSS (or Data::Feed::Atom)
 $wwf->entries;      # [ref Data::Feed::RSS::Entry, ...]


 my $wwf = new Wiz::Web::Feed;
 $entry  = $wwf->match_url('http://example.com/archive?id=123');  #ref Data::Feed::RSS::Entry
 $wwf->truncate_content();           # html body ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~...

=head1 DESCRIPTION

=cut

use base qw(Class::Accessor::Fast);
use Wiz::Constant qw(:common);
use Wiz::Util::String qw(trim_tag_html trim_line_code);

use Feed::Find;
use Data::Feed;
use LWP::Simple qw(head);
use Encode qw(decode);

__PACKAGE__->mk_accessors(qw(url title feed entries entry));

=head1 ACCESSORS
 match_url
 feed_url
=cut

=head1 CONSTRUCTOR

=head2 new($args)

=head2 ARGS

$args: ($url)

=cut

sub new {
    my $class = shift;
    my ($url) = @_;
    $class->SUPER::new({
        url     => $url,
        title   => '',
        entry   => '',
        entries => '',
    });
}

=cut

=head1 METHODS

=head2 feed_urls($args)

Gets HTML link tag for rss's feed.

$args: ($url)

=cut



sub feed_urls {
    my $self = shift;
    my ($url) = @_;
    $url ||= $self->url;

    Feed::Find->find(decode('utf8', $url));
}

=cut

=head2 parse_feed($args)

parse first much the feed.

$args: ($url)

=cut
sub parse_feed {
    my $self = shift;
    my ($url) = @_;

    $url ||= $self->url;
    $url or return DISABLE;
    $self->url or $self->url($url);

    my ($feed_url, $feed, $entry);
    foreach $feed_url ($self->feed_urls($url)) {
        next unless head($feed_url);
        $feed = Data::Feed->parse(URI->new($feed_url));
        $self->feed($feed);
        $self->entries($feed->entries);
        $feed->entries and return SUCCESS;
    }

    FAIL;
}

=cut

=head2 match_url($args)

parse feed and return entry of correspond $args.

$args: ($url)

=cut
sub match_entry {
    my $self = shift;
    my ($url) = @_;

    $url ||= $self->url;
    $url or return DISABLE;
    $self->url or $self->url($url);

    my ($feed_url, $feed, $entry);
    foreach $feed_url ($self->feed_urls($url)) {
        $feed = Data::Feed->parse(URI->new($feed_url));
        $self->feed($feed);
        $self->entries($feed->entries);
        foreach $entry ($feed->entries) {
            if ($url eq $entry->link) {
                $self->entry($entry);
                return $entry;
            }
        }
    }

    FAIL;
}

=cut

=head2 truncate_content($args, $args)

truncate entry's content by the within $num

$args: ($num, $content)

=cut

sub truncate_content {
    my $self = shift;
    my ($num, $content) = @_;
    $num ||= 97;
    ($num <= 0) and return '...';


    $content ||= ($self->entry and $self->entry->content->body);
    $content or return DISABLE;

    $content = Wiz::Util::String::trim_line_code(
                Wiz::Util::String::trim_tag_html($content));
    substr($content, 0, $num). '...';
}

# ----[ private ]-----------------------------------------------------
# ----[ static ]------------------------------------------------------
# ----[ private static ]----------------------------------------------

=head1 AUTHOR

Toshihiro MORIMOTO C<< dealforest.net@gmail.com >>

=head1 COPYRIGHT & LICENSE

Copyright 2008 The Wiz Project. All rights reserved.

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

