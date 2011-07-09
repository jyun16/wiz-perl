#!/usr/bin/perl

use lib qw(../../lib);

use Data::Dumper;

use Wiz::Test qw(no_plan);
use Wiz::Constant qw(:common);
use Wiz::Web::SimpleFeed qw(:feed_type create_feed);
use Wiz::Web::SimpleFeed::Parser;
use Wiz::Util::File qw(file_read2str);

chtestdir;

sub main {
#    create();
    parse();
    return 0;
}

sub parse {
    my $parser = new Wiz::Web::SimpleFeed::Parser;
#    warn Dumper $parser->parse(file_read2str('feed_sample/rss0_9'));
#    warn Dumper $parser->parse(file_read2str('feed_sample/rss0_91'));
#    warn Dumper $parser->parse(file_read2str('feed_sample/rss1_0'));
    warn Dumper $parser->parse(file_read2str('feed_sample/rss2_0'));
#    warn Dumper $parser->parse(file_read2str('feed_sample/atom'));
}

sub create {
    my $feed = {
        title   => 'RSSタイトル',
        url    => 'http://www.google.com',
        description => 'デスクリプション',
        author  => 'JN',
    };
    my $children = [
        {
            title   => 'タイトル111',
            url    => 'http://hoge.com/rss1',
            description => 'コンテンツ111',
            date    => '2009-10-11 22:33:44',
        },
        {
            title   => 'タイトル222',
            url    => 'http://hoge.com/rss2',
            description => 'コンテンツ222',
        },
    ];
    warn 'RSS 0.9 ' . '-' x 30;
    warn create_feed(RSS0_9, {
        %$feed,
        children   => $children,
    });
    warn 'RSS 0.91 ' . '-' x 30;
    warn create_feed(RSS0_91, {
        %$feed,
        children   => $children,
    });
    warn 'RSS 1.0' . '-' x 30;
    warn create_feed(RSS1_0, {
        %$feed,
        children   => $children,
    });
    warn 'RSS 2.0 ' . '-' x 30;
    warn create_feed(RSS2_0, {
        %$feed,
        children   => $children,
    });
    warn 'Atom ' . '-' x 30;
    warn create_feed(ATOM, {
        %$feed,
        children   => $children,
    });
}

exit main;
