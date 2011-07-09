#!/usr/bin/perl

use strict;
use warnings;

use Wiz::Test qw(no_plan);

use lib qw(../lib);

use Data::Dumper;

use Wiz::Bookmark qw(:all);

is 1, 1;

chtestdir;

my $conf = {
    title   => q|hoge's rss feed list|,
    group1  => {
        title   => "GROUP1",
        children => [
            {
                title   => "HOGE",
                url     => "http://www.hogehoge.hoge/",
                feed_url    => "http://www.hogehoge.hoge/xml",
            },
            {
                title   => "FUGA",
                url     => "http://fugafuga.fuga/",
                feed_url    => "http://fugafuga.fuga/xml",
            },
        ],
    },
    group2  => {
        title   => "GROUP2",
        children => [
            {
                title   => "FOO",
                url     => "http://www.foofoo.foo/",
                feed_url    => "http://www.foofoo.foo/xml",
            },
            {
                title   => "BAR",
                url     => "http://www.barbar.bar/",
                feed_url    => "http://www.barbar.bar/xml",
            },
        ],
    },
};

sub main {
#    dig_bookmark_type_test();
#    any();
#    opml();
#    netscape();
    return 0;
}

sub dig_bookmark_type_test {
    is dig_bookmark_type(file_read2str('web/feed_sample/rss0_9')), 101;
    is dig_bookmark_type(file_read2str('web/feed_sample/rss0_91')), 102;
    is dig_bookmark_type(file_read2str('web/feed_sample/rss1_0')), 110;
    is dig_bookmark_type(file_read2str('web/feed_sample/rss2_0')), 120;
    is dig_bookmark_type(file_read2str('web/feed_sample/atom')), 200;
}

sub any {
#    my $data = file_read2str('bookmark_sample/netscape.htm');
#    my $data = file_read2str('bookmark_sample/export.xml');
#    my $data = file_read2str('bookmark_sample/atom.xml');
#    my $data = file_read2str('bookmark_sample/rss.xml');
#    my $data = file_read2str('bookmark_sample/opml.opml');

    my $data = file_read2str('/var/work/perl/catalyst/wizapp/SppBM/_tmp/imported_files/Kp5fwWzgK5');
    my $bookmark = new Wiz::Bookmark;
    $bookmark->parse($data);
#    warn 'title: ' . $bookmark->title;
#    warn 'version: ' . $bookmark->version;
#    warn 'author: ' . $bookmark->author;
    warn 'data: ' . Dumper $bookmark->data;
#    warn 'data: ' . Dumper convert2tags_data($bookmark->data);
#    warn $bookmark->to_string;
}

sub opml {
    my $bm = new Wiz::Bookmark::OPML(title => $conf->{title});
    $bm->add($conf->{group1});
    $bm->add($conf->{group2});
    my $data = $bm->to_string;
    is $data, <<"EOS", "create OPML";
<?xml version="1.0" encoding="UTF-8"?>
  <opml version="1.0">
    <head>
      <title>hoge's rss feed list</title>
    </head>
    <body>
      <outline text="GROUP1" title="GROUP1">
        <outline xmlUrl="http://www.hogehoge.hoge/xml" htmlUrl="http://www.hogehoge.hoge/" text="HOGE" type="rss" title="HOGE" />
        <outline xmlUrl="http://fugafuga.fuga/xml" htmlUrl="http://fugafuga.fuga/" text="FUGA" type="rss" title="FUGA" />
      </outline>
      <outline text="GROUP2" title="GROUP2">
        <outline xmlUrl="http://www.foofoo.foo/xml" htmlUrl="http://www.foofoo.foo/" text="FOO" type="rss" title="FOO" />
        <outline xmlUrl="http://www.barbar.bar/xml" htmlUrl="http://www.barbar.bar/" text="BAR" type="rss" title="BAR" />
      </outline>
    </body>
  </opml>
EOS
    $bm->parse($data);
    is $bm->title, q|hoge's rss feed list|, "parse OPML - title";
    is_deeply $bm->data, [
          {
            'title' => 'GROUP1',
            'children' => [
                            {
                              'title' => 'HOGE',
                              'url' => 'http://www.hogehoge.hoge/',
                              'feed_url' => 'http://www.hogehoge.hoge/xml',
                            },
                            {
                              'title' => 'FUGA',
                              'url' => 'http://fugafuga.fuga/',
                              'feed_url' => 'http://fugafuga.fuga/xml',
                            }
                          ],
          },
          {
            'title' => 'GROUP2',
            'children' => [
                            {
                              'title' => 'FOO',
                              'url' => 'http://www.foofoo.foo/',
                              'feed_url' => 'http://www.foofoo.foo/xml',
                            },
                            {
                              'title' => 'BAR',
                              'url' => 'http://www.barbar.bar/',
                              'feed_url' => 'http://www.barbar.bar/xml',
                            }
                          ],
          }
    ], "parse OPML - data";
}

sub netscape {
    my $bm = new Wiz::Bookmark::Netscape(title => $conf->{title});
    $bm->add($conf->{group1});
    $bm->add($conf->{group2});
    my $data = $bm->to_string;
    is $data, <<"EOS", "create Netscape Bookmark";
<!DOCTYPE NETSCAPE-Bookmark-file-1>
<META HTTP-EQUIV="Content-Type" CONTENT="text/html; charset=UTF-8">
<TITLE>hoge's rss feed list</TITLE>
<H1>hoge's rss feed list</H1>
<DL><p>
    <DT><H3>GROUP1</H3>
    <DL><p>
        <DT><A HREF="http://www.hogehoge.hoge/">HOGE</A>
        <DT><A HREF="http://fugafuga.fuga/">FUGA</A>
    </DL><p>
    <DT><H3>GROUP2</H3>
    <DL><p>
        <DT><A HREF="http://www.foofoo.foo/">FOO</A>
        <DT><A HREF="http://www.barbar.bar/">BAR</A>
    </DL><p>
</DL></p>
EOS
    $bm->parse($data);
    is $bm->title, q|hoge's rss feed list|, "parse Netscape Bookmark - title";
    is_deeply $bm->data, [
          {
            'title' => 'GROUP1',
            'children' => [
                            {
                              'url' => 'http://www.hogehoge.hoge/',
                              'title' => 'HOGE',
                            },
                            {
                              'url' => 'http://fugafuga.fuga/',
                              'title' => 'FUGA',
                            }
                          ],
            'title' => 'GROUP1'
          },
          {
            'title' => 'GROUP2',
            'children' => [
                            {
                              'url' => 'http://www.foofoo.foo/',
                              'title' => 'FOO',
                            },
                            {
                              'url' => 'http://www.barbar.bar/',
                              'title' => 'BAR',
                            }
                          ],
            'title' => 'GROUP2'
          }
    ], "parse Netscape Bookmark - data";
}

use Wiz::Util::File qw(file_read2str);

exit main();
