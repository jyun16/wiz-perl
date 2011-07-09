package Wiz::Web::Framework::Model::Tag;

=head1 NAME

Wiz::Web::Framework::Model::Tag

=head1 VERSION

version 1.0

=cut

our $VERSION = '1.0';

=head1 SQL

=head2 MySQL

 CREATE TABLE tag (
     id                      INTEGER UNSIGNED    AUTO_INCREMENT PRIMARY KEY,
     name                    VARCHAR(512),
     yomi                    VARCHAR(4096),
     count                   MEDIUMINT UNSIGNED  DEFAULT 0,
     delete_flag             BOOL                DEFAULT 0,
     created_time            DATETIME            NOT NULL,
     last_modified           TIMESTAMP
 ) ENGINE=innodb DEFAULT CHARACTER SET utf8 COLLATE utf8_bin;

=cut

use MeCab;

use Wiz::Noose;
use Wiz::Constant qw(:common);
use Wiz::Util::Array qw(args2array);
use Wiz::ConstantExporter [qw(
    split_tags
)];

extends qw(Wiz::Web::Framework::Model);

sub init_instance {
    my $self = shift;
    $self->{mecab} = new MeCab::Tagger('-Oyomi');
}

sub create_tags {
    my $self = shift;
    my ($tags, $params) = @_;
    $params ||= {};
    $tags = split_tags($tags);
    my @created = ();
    for (@$tags) {
        $self->clear;
        unless ($self->numerate(
            %$params,
            name        => $_,
        )) {
            $self->set(
                %$params,
                name        => $_,
                yomi        => $self->tag_yomi($_),
                count       => 1,
            );
            push @created, $self->create;
        }
    }
    return \@created;
}

sub search_similar_tag {
    my $self = shift;
    my ($tag, $params) = @_;
    $params ||= {};
    my $yomi = $self->tag_yomi($tag);
    if ($self->numerate(
        %$params,
        name        => [ '=', $tag ],
        yomi        => $yomi,
    )) { return []; }
    $self->search(
        %$params,
        name        => [ '!=', $tag ],
        yomi        => $yomi,
    );
}

sub search_similar_tags {
    my $self = shift;
    my ($tags, $params) = @_;
    $tags = split_tags($tags);
    $params ||= {};
    my %ret = ();
    for (@$tags) {
        my $similar = $self->search_similar_tag($_, $params);
        @$similar and $ret{$_} = $similar;
    }
    return %ret ? \%ret : undef;
}

sub tag_yomi {
    my $self = shift;
    my ($str) = @_;
    $str eq '' and return '';
    my $ret = $self->{mecab}->parse($str);
    $ret =~ s/\r?\n$//;
    return lc $ret;
}

sub tags_yomi {
    my $self = shift;
    my ($tags) = @_;
    $tags = split_tags($tags);
    my @ret = ();
    for (@$tags) { push @ret, $self->{mecab}->parse($_); }
    return \@ret;
}

sub append_or_remove_tag_string {
    my $self = shift;
    my ($tags, $tag) = @_;
    $tags = split_tags($tags);
    my @ret = ();
    for (@$tags) { $_ ne $tag and push @ret, $_; }
    if (@$tags == @ret) { push @ret, $tag; }
    return join ' ', @ret;
}

sub remove_tag_string {
    my $self = shift;
    my ($tags, $remove) = @_;
    $tags = split_tags($tags);
    my @ret = ();
    for (@$tags) { $_ ne $remove and push @ret, $_; }
    return join ' ', @ret;
}

sub split_tags {
    my ($tags) = @_;
    ref $tags or $tags = [ split /\s+|　|,/, $tags ];
    return wantarray ? @$tags : $tags;
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
