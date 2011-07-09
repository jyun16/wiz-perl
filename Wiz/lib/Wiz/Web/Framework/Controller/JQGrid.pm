package Wiz::Web::Framework::Controller::JQGrid;

use strict;
use warnings;

=head1 NAME

Wiz::Web::Framework::Controller::JQGrid

=head1 VERSION

version 1.0

=cut

our $VERSION = '1.0';

=head1 SYNOPSIS

=cut

use JSON::Syck;

use Wiz::Noose;
use Wiz::Constant qw(:common);
use Wiz::DB qw(prelike like suflike like_sub);

extends qw(Wiz::Web::Framework::Controller);

sub edit {
    my $self = shift;
    my ($c) = @_;

    my $p = $c->req->params;
    my $model = $c->model($self->ourv('MODEL'));
    if ($p->{oper} eq 'del') {
        $p->{id} eq '' and return;
        $model->delete(id => $p->{id});
        $model->commit;
    }
    $c->res->content_type("application/json");
    $c->res->body(JSON::Syck::Dump({}));
}

sub list {
    my $self = shift;
    my ($c) = @_;

    my $p = $c->req->params;
    my $model = $c->slave_model($self->ourv('MODEL'));
    my %query = ();
    if ($p->{_search} eq 'true') { $self->_append_query_from_jqgrid(\%query, $p); }
    else { $self->_append_query(\%query, $p, $model); }
    my $records = $model->count(\%query);
    my $total = int($records / $p->{rows});
    $records % $p->{rows} and ++$total;
    my %data = ( 
        page    => $p->{page},
        total   => $total,
        records => $records,
    );
    $query{-limit} = [$p->{rows} * ($p->{page} - 1), $p->{rows}];
    $query{-order} = [ "$p->{sidx} $p->{sord}" ],
    $self->_append_search_params($c, \%query, $model);
    my $rs = $model->select(\%query);
    my @rows = ();
    my @json_fields = $self->ourv('JSON_FIELDS', '@');
    while ($rs->next) {
        my $d = $rs->data;
        my @cell = ();
        for (@json_fields) {
            push @cell, $d->{$_};
        }
        push @rows, {
            id      => $d->{id},
            cell    => \@cell,
        };
    }
    $data{rows} = \@rows;
    $c->res->content_type("application/json");
    $c->res->body(JSON::Syck::Dump(\%data));
}

sub _append_search_params {}

sub _append_query {
    my $self = shift;
    my ($query, $p, $model) = @_;

    my $like_search = { $self->ourv('LIKE_SEARCH', '%') };
    for my $k ($model->ourv('SEARCH', '@')) {
        my $v = $p->{$k};
        defined $v or $v = '';
        $v eq '' and next;
        my @v = split /\s/, $v;
        if (@v > 1) {
            if (defined $like_search->{$k}) {
                my @d = ();
                my $sub = like_sub($like_search->{$k});
                for (@v) {
                    push @d, [ 'like', $k, $sub->($_) ],
                }
                $query->{-or} = \@d;
            }
            else { $query->{-in} = { $k => \@v, }; }
        }
        else {
            if (defined $like_search->{$k}) {
                $query->{$k} = [ 'like', like_sub($like_search->{$k})->($v) ];
            }
            else { $query->{$k} = $v; }
        }
    }
}

sub _append_query_from_jqgrid {
    my $self = shift;
    my ($query, $p) = @_;

    if ($p->{searchOper} eq 'eq') {
        $query->{$p->{searchField}} = $p->{searchString};
    }
    elsif ($p->{searchOper} eq 'ne') {
        $query->{-and} = [
            [ '!=', $p->{searchField}, $p->{searchString} ],
        ];
    }
    elsif ($p->{searchOper} eq 'lt') {
        $query->{-and} = [
            [ '<', $p->{searchField}, $p->{searchString} ],
        ];
    }
    elsif ($p->{searchOper} eq 'le') {
        $query->{-and} = [
            [ '<=', $p->{searchField}, $p->{searchString} ],
        ];
    }
    elsif ($p->{searchOper} eq 'gt') {
        $query->{-and} = [
            [ '>', $p->{searchField}, $p->{searchString} ],
        ];
    }
    elsif ($p->{searchOper} eq 'ge') {
        $query->{-and} = [
            [ '>=', $p->{searchField}, $p->{searchString} ],
        ];
    }
    elsif ($p->{searchOper} eq 'bw') {
        $query->{-and} = [
            [ 'LIKE', $p->{searchField}, prelike $p->{searchString} ],
        ];
    }
    elsif ($p->{searchOper} eq 'ew') {
        $query->{-and} = [
            [ 'LIKE', $p->{searchField}, suflike $p->{searchString} ],
        ];
    }
    elsif ($p->{searchOper} eq 'cn') {
        $query->{-and} = [
            [ 'LIKE', $p->{searchField}, like $p->{searchString} ],
        ];
    }
}

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
