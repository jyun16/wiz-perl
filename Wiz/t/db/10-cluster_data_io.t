#!/usr/bin/perl

use strict;
use warnings;

use lib qw(../../lib);

use Data::Dumper;

use Wiz::Test qw(no_plan);
use Wiz::Constant qw(:common);
use Wiz::DB::Constant qw(:all);
use Wiz::DB::DataIO;
use Wiz::DB::Cluster::Controller;

$| = 1;

chtestdir;

my $cache_test = TRUE;

my %mysql_param = (
    type            => DB_TYPE_MYSQL,
    db              => 'test',
    user            => 'root',
    priority_flag   => ENABLE,
    log => {
        stderr  => 1,
        path    => 'logs/cluster_controller.log',
    },
    clusters    => {
        member          => {
            db  => 'cluster_data_test_member',
            cache   => {
                type    => 'Memcached::Fast',
                conf    => {
                    servers => [qw(
                        127.0.0.1:11111
                    )],
                },
            },
        },
        article01       => {
            db  => 'cluster_data_test_article01',
        },
        article02       => {
            db  => 'cluster_data_test_article02',
        },
        article03       => {
            db  => 'cluster_data_test_article03',
        },
    },
    group      => {
       article => [qw(article01 article02 article03)],
    },
    cache   => {
        type    => 'Memcached::Fast',
        conf    => {
            servers => [qw(
                127.0.0.1:11112
            )],
        },
    },
);

sub main {
    my $cc = new Wiz::DB::Cluster::Controller(%mysql_param);

    my $member = new Wiz::DB::DataIO($cc->get_master('member'), 'member');
    $member->cluster_controller($cc);

    $member->set(name => 'HOGE');
    $member->insert;
    my $member_data = $member->get_insert_data;

    my $article = $member->cluster_data_io('article', 'article', { id=> $member_data->{id} });
    $article->set(
        member_id   => $member_data->{id},
        title       => 'HOGE TITLE'
    );
    $article->insert;

    $article->primary_key4cache(qw(member_id));

    warn Dumper $article->retrieve(member_id => $member_data->{id});

    # these transactions are different.
    $article->commit;
    $member->commit;

    return 0;
};

skip_confirm(2) and exit main;
#exit main;

__END__

-- DB cluster_data_test_member
CREATE TABLE member (
    id                      INTEGER UNSIGNED        AUTO_INCREMENT PRIMARY KEY,
    name                    VARCHAR(64),
    cluster_label_article   VARCHAR(255)
) ENGINE=innodb;

-- DB cluster_data_test_article01..03
CREATE TABLE article (
    id                      INTEGER UNSIGNED        AUTO_INCREMENT PRIMARY KEY,
    member_id               INTEGER UNSIGNED
    title                   VARCHAR(64)
) ENGINE=innodb;

