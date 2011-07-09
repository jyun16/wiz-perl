#!/usr/bin/perl

use strict;
use warnings;

#use Wiz::Test qw(no_plan);

use lib qw(../lib);

use Wiz::Net::Service::Twitter::API;
use Wiz::Net::Service::Twitter::API::ResultSet;

#chtestdir;

use Wiz::Dumper;

sub main {
    my $t = new Wiz::Net::Service::Twitter::API(
        screen_name         => '',
        password            => '',
        consumer_key        => '',
        consumer_secret     => '',
#        use_oauth           => 1,
#        access_token        => {
#            secret  => '',
#            token   => ''
#        },
    );
#    wd $t->broute_get_access_token;

#    search($t);
    timeline($t);
#    statuses($t);
#    user($t);
#    list($t);
#    list_subscribers($t);
#    direct_messages($t);
#    friendships($t);
#    social_graph($t);
#    account($t);
#    favorites($t);
#    blocks($t);
    return 0;
}

sub search {
    my ($t) = @_;

#    my $rs = $t->search(q => 'Perl', rpp => 10, lang => 'ja');
#    $rs->next;
#    wd $rs->data;
#    $rs->next;
#    wd $rs->data;

#    wd $t->trends;
#    wd $t->trends_current;
#    wd $t->trends_daily;
#    wd $t->trends_weekly;

#    $rs->has_error and die $rs->error;
    $t->has_error and die $t->error;
}

sub timeline {
    my ($t) = @_;

#    wd $t->statuses_public_timeline;

#    my $rs = $t->statuses_user_timeline(
#        screen_name => '', 
#    );
#    $rs->next;
#    wd $rs->data;

#    my $rs = $t->statuses_home_timeline;
#    $rs->next;
#    wd $rs->data;
#    $rs->next;
#    wd $rs->data;

#    my $rs = $t->statuses_retweeted_to_me;
#    $rs->next;
#    wd $rs->data;
#    $rs->next;
#    wd $rs->data;

#    $rs->has_error and die $rs->error;
    $t->has_error and die $t->error;
}

sub statuses {
    my ($t) = @_;
#    wd $t->statuses_show(id => 18514009314);
#    $rs->has_error and die $rs->error;
    $t->has_error and die $t->error;
}

sub user {
    my ($t) = @_;

    # voidx3: 98620382
    wd $t->users_show(id => 'ktat') || die $t->error;

#    warn hate_utf8_dumper $t->users_show(id => 119440846);
#    wd $t->users_lookup(user_id => [qw(119440846 142757453)]);
#    wd $t->users_search(q => 'dizllar');
#    wd $t->users_suggestions;
#    wd $t->users_suggestions_category(slug => 'books');

#    my $rs = $t->statuses_friends(id => 'dizllar');
#    while ($rs->next) {
#        for (@{$rs->data}) {
#            warn $_->{screen_name};
#        }
#    }

#    $rs->has_error and die $rs->error;
    $t->has_error and die $t->error;
}

sub list {
    my ($t) = @_;
#    $t->post_lists(name => 'haihai', mode => 'public', description => 'DESCRIPTION TEXT');

#    wd $t->post_lists_id(id => '16927816', name => 'bainbain', mode => 'public', description => 'DESCRIPTION TEXT');

#    wd $t->get_list_id(id => '16862685');
#    wd $t->delete_list_id(id => '16862685');

    my $rs = $t->get_lists;
    while ($rs->next) {
        wd $rs->data;
        warn '-----';
    }

#    while ($rs->next) {
#        for (@{$rs->data}) {
#            wd $_;
#        }
#    }

#    my $rs = $t->get_list_statuses(id => 16862568, per_page => 2);
#    while ($rs->next) {
#        for (@{$rs->data}) {
#            wd $_;
#        }
#    }

#    my $rs = $t->get_list_memberships;
#    $rs->next;
#    wd $rs->data;

#    $rs->has_error and die $rs->error;
    $t->has_error and die $t->error;
}

sub list_members {
    my ($t) = @_;

#    my $rs = $t->get_list_members(list_id => 16862568);
#    $rs->next;
#    wd $rs->data;

    wd $t->get_list_members_id(list_id => 16862568, id => 'voidx');

#    $rs->has_error and die $rs->error;
    $t->has_error and die $t->error;
}

sub list_subscribers {
    my ($t) = @_;

    my $rs = $t->get_list_subscribers(list_id => 16862568);
    $rs->next;
    wd $rs->data;

#    $rs->has_error and die $rs->error;
    $t->has_error and die $t->error;
}

sub direct_messages {
    my ($t) = @_;

#    my $rs = $t->direct_messages;
#    while ($rs->next) {
#        for (@{$rs->data}) {
#            wd $_->{id};
#        }
#    }

#    for (qw(897697384 895520782 895520657 895206638)) {
#        $t->direct_messages_destroy(id => $_);
#    }

#    $t->direct_messages_new(user => 'dizllar', text => 'hey');

#    $rs->has_error and die $rs->error;
    $t->has_error and die $t->error;
}

sub friendships {
    my ($t) = @_;

#    wd $t->friendships_create(id => 'voidx3');
#    $t->friendships_destroy(screen_name => 'voidx3');

#    wd $t->friendships_exists(user_a => 'ddizllar', user_b => 'voidx3');
#    my $r =  $t->friendships_show(source_screen_name => 'dizllar', target_screen_name => 'voidx3');

    my $rs = $t->friendships_outgoing;
    while ($rs->next) {
        for (@{$rs->data}) {
             my $user = $t->users_show(id => $_);
             $t->friendships_destroy(id => $_);
             warn $user->{screen_name};
        }
    }

#    $rs->has_error and die $rs->error;
    $t->has_error and die $t->error;
}

sub social_graph {
    my ($t) = @_;

    my $rs = $t->followers_ids;
    $rs->next;
    wd $rs->data;

#    $rs->has_error and die $rs->error;
    $t->has_error and die $t->error;
}

sub account {
    my ($t) = @_;

#    wd $t->account_verify_credentials;
#    wd $t->account_rate_limit_status;
#    wd $t->account_end_session;
#    wd $t->account_update_profile_colors(profile_background_color => 'c1dfed');

    wd $t->account_update_profile_image(
        image   => [ '75.jpg', 'image', 'Content-Type' => 'image/jpeg' ],
    );

#    $rs->has_error and die $rs->error;
    $t->has_error and die $t->error;
}

sub favorites {
    my ($t) = @_;

    my $rs = $t->favorites;
    $rs->next;
    wd $rs->data;

#    $rs->has_error and die $rs->error;
    $t->has_error and die $t->error;
}

sub blocks {
    my ($t) = @_;

#    my $rs = $t->blocks_blocking;
#    $rs->next;
#    wd $rs->data;

    wd $t->blocks_blocking_ids;

#    $rs->has_error and die $rs->error;
    $t->has_error and die $t->error;
}

exit main;
