package Wiz::Text::Estraier::DB;

=head1 NAME

Wiz::Test::Estraier::DB

=head1 VERSION

version 1.0

=cut

our $VERSION = '1.0';

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut

=head1 EXPORTS

=cut

use DBI;
use Estraier;
use Carp;

use Wiz::Noose;
use Wiz::Config qw(load_config_files);
use Wiz::DB::Connection;
use Wiz::DB::DataIO;
use Wiz::Util::Hash qw(override_hash);
use Wiz::Text::Estraier qw(:db_condition);

extends 'Wiz::Text::Estraier';

has 'db' => (is => 'rw', setter => sub {
    my $self = shift;
    my ($conn) = @_;
    $self->{db} = new Wiz::DB::DataIO($conn, $self->{table});
});
has 'select_query4search' => (is => 'rw');
has 'count_query4register' => (is => 'rw');
has 'select_query4register' => (is => 'rw');
has 'progress' => (is => 'rw');
has 'table' => (is => 'rw');
has 'primary_key' => (is => 'rw', default => 'id');
has 'searched_text' => (is => 'rw');
has 'attribute' => (is => 'rw', default => []);
has 'register_all_limit_per_once' => (is => 'rw', default => 100_000);

sub BUILD {
    my $self = shift;
    my ($args) = @_;
    my $conf = {};
    if ($args->{conf}) { $conf = load_config_files($args->{conf}); }
    override_hash($conf, $args);
    if ($conf->{db}) {
        my $conn = new Wiz::DB::Connection($conf->{db});
        $self->{table} ||= $conf->{db}{table};
        $self->{db} = new Wiz::DB::DataIO($conn, $self->{table});
    }
    $self->{e} = new Database;
    $args->{db_condition} ||= DB_WRITER | DB_CREATE;
    $self->{e}->open($conf->{index},
        Database::DBNOLCK | Database::DBLCKNB | $args->{db_condition}
    ) or confess $self->error(q|can't create the Estraier Object|);
}

sub count_all {
    my $self = shift;
    $self->{e}->doc_num;
}

sub count {
    my $self = shift;
    my ($keyword, $opt) = @_;
    my $cond = new Condition;
    if ($opt->{attribute}) {
        if (ref $opt->{attribute}) { for (@{$opt->{attribute}}) { $cond->add_attr($_); } }
        else { $cond->add_attr($_); }
    }
    $cond->set_phrase($keyword);
    my $res = $self->{e}->search($cond);
    return $res->doc_num;
}

sub search {
    my $self = shift;
    my @ret = ();
    my @ids = $self->search_ids(@_);
    @ids or return;
    my @ret;
    my $db = $self->{db};
    my $query = $self->select_query4search;
    for (@ids) {
        if ($query) { push @ret, $db->dbc->retrieve($query, [$_]); }
        else { push @ret, $db->retrieve(id => $_); }
    }
    return wantarray ? @ret : \@ret;
}

sub search_ids {
    my $self = shift;
    my ($keyword, $opt) = @_;
    my $cond = new Condition;
    defined $opt->{limit} and $cond->set_max($opt->{limit});
    defined $opt->{offset} and $cond->set_skip($opt->{offset});
    $cond->set_phrase($keyword);
    if ($opt->{order}) {
        if (ref $opt->{order}) { for (@{$opt->{order}}) { $cond->set_order($_); } }
        else { $cond->set_order($_); }
    }
    if ($opt->{attribute}) {
        if (ref $opt->{attribute}) { for (@{$opt->{attribute}}) { $cond->add_attr($_); } }
        else { $cond->add_attr($_); }
    }
    my $e = $self->{e};
    my $res = $e->search($cond);
    my $n = $res->doc_num - 1;
    my @ret = ();
    for my $i (0..$n) {
        my $doc = $e->get_doc($res->get_doc_id($i), 0);
        push @ret, $doc->attr('@uri');
    }
    return wantarray ? @ret : \@ret;
}

sub register_all_with_db {
    my $self = shift;
    my $db = $self->{db};
    my $count_query = $self->count_query4register;
    my $select_query = $self->select_query4register;
    my $primary_key = $self->primary_key;
    my $searched_text = $self->searched_text;
    my @attribute = @{$self->attribute};
    my $count = 0;
    if ($count_query) {
        my $rs = $db->execute($count_query);
        $rs->next;
        $count = $rs->data->{count};
    }
    else { $count = $db->count; }
    my $limit = $self->{register_all_limit_per_once};
    my $loop = int($count / $limit);
    my $i = 0;
    for (0 .. $loop) {
        $self->progress and print "$i\n";
        my $rs;
        if ($select_query) {
            $rs = $db->execute($select_query . " LIMIT $i, $limit");
        }
        else {
            $rs = $db->select(-limit => [ $i, $limit ]);
        }
        while ($rs->next) {
            my $d = $rs->data;
            my %attr = map { $_ => $d->{$_} } @attribute;
            $self->register($d->{$primary_key}, $d->{$searched_text}, \%attr);
        }
        $i += $limit;
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
