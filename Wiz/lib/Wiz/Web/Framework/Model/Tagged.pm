package Wiz::Web::Framework::Model::Tagged;

=head1 NAME

Wiz::Web::Framework::Model::Tagged

=head1 VERSION

version 1.0

=cut

our $VERSION = '1.0';

=head1 SQL

 CREATE TABLE tag (
     id                      BIGINT UNSIGNED    AUTO_INCREMENT PRIMARY KEY,
     member_id               BIGINT UNSIGNED,
     name                    VARCHAR(512),
     yomi                    VARCHAR(4096),
     count                   MEDIUMINT UNSIGNED  DEFAULT 0,
     delete_flag             BOOL                DEFAULT 0,
     created_time            DATETIME            NOT NULL,
     last_modified           TIMESTAMP
 ) ENGINE=innodb DEFAULT CHARACTER SET utf8 COLLATE utf8_bin;
 ALTER TABLE tag ADD INDEX (member_id);
 ALTER TABLE tag ADD INDEX (member_id, name);
 
 CREATE TABLE scrap_tag (
     id                      BIGINT UNSIGNED    AUTO_INCREMENT PRIMARY KEY,
     member_id               BIGINT UNSIGNED,
     tag_id                  BIGINT UNSIGNED,
     scrap_id                BIGINT UNSIGNED,
     priority                MEDIUMINT UNSIGNED  DEFAULT 0,
     delete_flag             BOOL                DEFAULT 0,
     created_time            DATETIME            NOT NULL,
     last_modified           TIMESTAMP
 ) ENGINE=innodb DEFAULT CHARACTER SET utf8 COLLATE utf8_bin;
 ALTER TABLE scrap_tag ADD FOREIGN KEY (tag_id) REFERENCES tag(id) ON DELETE CASCADE;
 ALTER TABLE scrap_tag ADD FOREIGN KEY (scrap_id) REFERENCES scrap(id) ON DELETE CASCADE;
 ALTER TABLE scrap_tag ADD INDEX (member_id);
 ALTER TABLE scrap_tag ADD INDEX (tag_id);
 
 CREATE TABLE scrap (
     id                      BIGINT UNSIGNED    AUTO_INCREMENT PRIMARY KEY,
     member_id               BIGINT UNSIGNED,
     url                     VARCHAR(1024),
     title                   VARCHAR(1024),
     tags                    VARCHAR(4098),
     rating                  TINYINT UNSIGNED,
     comment                 TEXT,
     disclosure              BOOL                DEFAULT 1,
     secret                  BOOL                DEFAULT 0,
     delete_flag             BOOL                DEFAULT 0,
     created_time            DATETIME            NOT NULL,
     last_modified           TIMESTAMP
 ) ENGINE=innodb DEFAULT CHARACTER SET utf8 COLLATE utf8_bin;
 ALTER TABLE scrap ADD INDEX (member_id);

=head2 MySQL

=cut

use Clone qw(clone);
use Catalyst::Model::Wiz::Tag qw(split_tags);

use Wiz::Noose;
use Wiz::Constant qw(:common);
use Wiz::Util::Hash qw(args2hash);
use Wiz::DB qw(like);

extends qw(Wiz::Web::Framework::Model);

sub numerate_with_tags {
    my $self = shift;
    my ($param) = args2hash @_;
    $param = $self->purify_search_params($param);
    return $self->SUPER::numerate($param);
}

sub getone_with_tags {
    my $self = shift;
    my ($param) = args2hash @_;
    $param = $self->purify_search_params($param);
    my $ret = $self->SUPER::getone($param);
    $ret->{tags} = split_tags($ret->{tags});
    return $ret;
}

sub search_with_tags {
    my $self = shift;
    my ($param) = args2hash @_;
    $param = $self->purify_search_params($param);
    my $list = $self->SUPER::search($param);
    for (@$list) {
        $_->{tags} = split_tags($_->{tags});
    }
    return $list;
}

sub purify_search_params {
    my $self = shift;
    my ($param) = @_;
    $param = clone $param;
    if ($param->{tags}) {
        my $tags = $param->{tags};
        delete $param->{tags};
        $param->{-and} = [];
        for (@$tags) {
            push @{$param->{-and}}, [ 'like', 'tags', like("$_ ") ];
        }
    }
    return $param;
}

sub create_with_tags {
    my $self = shift;
    my ($param) = args2hash @_;
    my $member_id = $param->{member_id};
    my $tags = ref $param->{tags} eq 'ARRAY' ? $param->{tags} : split_tags($param->{tags});
    $param->{tags} = (join ' ', @$tags) . ' ';
    my $ret = $self->SUPER::create($param);
    my $tag = $self->model($self->ourv('TAG_MODEL_NAME'));
    my $related = $self->model($self->ourv('RELATED_MODEL_NAME'));
    my $target = $self->ourv('TAG_TARGET_NAME');
    my $created_tags = $tag->create_tags(
        $param->{tags}, { member_id => $member_id });
    my $priority = 0;
    for (@$tags) {
        my $t = $tag->getone(
            member_id   => $member_id,
            name        => $_,
        );
        $related->set(
            member_id       => $member_id,
            tag_id          => $t->{id},
            "${target}_id"  => $ret->{id},
            priority        => $priority,
        );
        $priority++;
        $related->create;
    }
    my %created_tags = map { $_->{name} => 1 } @$created_tags;
    for (@$tags) {
        $created_tags{$_} and next;
        _modify_tag_count($tag, $param->{member_id}, $_, '+1');
    }
    return $ret;
}

sub modify_with_tags {
    my $self = shift;
    my ($param) = args2hash @_;
    my $member_id = $param->{member_id};
    my $tags = split_tags($param->{tags});
    $param->{tags} = (join ' ', @$tags) . ' ';
    my $ret = $self->SUPER::modify($param);
    $ret or return 0;
    my $tag = $self->model($self->ourv('TAG_MODEL_NAME'));
    my $related = $self->model($self->ourv('RELATED_MODEL_NAME'));
    my $target = $self->ourv('TAG_TARGET_NAME');
    $tag->create_tags($param->{tags}, { member_id => $member_id });
    my $before_tags = $related->search4list(
        "${target}_id"  => $param->{id},
    );
    my %tags = map { $_ => 1 } @$tags;
    my %before_tags = map { $_->{name} => 1 } @$before_tags;
    my @appended;
    my $priority = 0; 
    my %tags_prioriry = map { $_ => $priority++ } @$tags;
    for (@$tags) { $before_tags{$_} or push @appended, $_; }
    for (@appended) {
        my $t = $tag->getone(
            member_id   => $member_id,
            name        => $_,
        );
        if ($t) {
            $related->set(
                member_id       => $member_id,
                tag_id          => $t->{id},
                "${target}_id"  => $param->{id},
                priority        => $tags_prioriry{$_},
            );
            $related->create;
        }
    }
    for (keys %before_tags) {
        my $t = $tag->getone(
            member_id   => $member_id,
            name        => $_,
        );
        if (defined $tags_prioriry{$_}) {
            $related->set(
                priority    => $tags_prioriry{$_},
            );
            $related->update(
                member_id       => $member_id,
                tag_id          => $t->{id},
                "${target}_id"  => $param->{id},
            );
        }
        else {
            $related->force_delete(
                member_id       => $member_id,
                tag_id          => $t->{id},
                "${target}_id"  => $param->{id},
            );
            _modify_tag_count($tag, $member_id, $_, '-1');
        }
    }
    for (@appended) { _modify_tag_count($tag, $member_id, $_, '+1'); }
    return $ret;
}

sub remove {
    my $self = shift;
    my ($param) = args2hash @_;

    my $member_id = $param->{member_id};
    my $tag = $self->model($self->ourv('TAG_MODEL_NAME'));
    my $related = $self->model($self->ourv('RELATED_MODEL_NAME'));
    my $target = $self->ourv('TAG_TARGET_NAME');
    my $before_tags = $related->search4list(
        "${target}_id"  => $param->{id},
    );
    my $ret = $self->SUPER::remove($param);
    $ret or return 0;
    for (@$before_tags) {
        _modify_tag_count($tag, $member_id, $_->{name}, '-1');
    }
    return $ret;
}

sub _modify_tag_count {
    my ($tag, $member_id, $name, $add) = @_;
    $tag->clear;
    $tag->set(
        count   => \"count $add",
    );
    $tag->update(
        member_id   => $member_id,
        name        => $name,
    )
}

=head1 SEE ALSO

=head1 AUTHOR

Junichiro NAKAMURA, C<< <jyun16@gmail.com> >>

=head1 COPYRIGHT & LICENSE

Copyright 2010 The Wiz Project. All rights reserved.

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
