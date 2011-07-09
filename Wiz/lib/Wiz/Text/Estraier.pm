package Wiz::Text::Estraier;

=head1 NAME

Wiz::Test::Estraier

=head1 VERSION

version 1.0

=cut

our $VERSION = '1.0';

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut

=head1 EXPORTS

=cut

use Estraier;
use Carp;

use Wiz::Noose;
use Wiz::Config qw(load_config_files);
use Wiz::Util::Hash qw(override_hash);

use Wiz::ConstantExporter {
    DB_WRITER                   => Database::DBWRITER,
    DB_READER                   => Database::DBREADER,
    DB_CREATE                   => Database::DBCREAT,
    DB_NGRAM_ALL                => Database::DBPERFNG,
    DB_LESS_THAN_50K_RECORD     => Database::DBSMALL,
    DB_MORE_THAN_300K_RECORD    => Database::DBLARGE,
    DB_MORE_THAN_1M_RECORD      => Database::DBHUGE,
    DB_MORE_THAN_5M_RECORD      => Database::DBHUGE2,
    DB_MORE_THAN_10M_RECORD     => Database::DBHUGE3,
    DB_SCORE_VOID               => Database::DBSCVOID,
    DB_SCORE_INT                => Database::DBSCINT,
    DB_SCORE_ADJUST             => Database::DBSCASIS,
}, 'db_condition';

has 'e' => (is => 'rw');
has 'db_condition' => (is => 'rw');
has 'conf' => (is => 'rw');
has 'max' => (is => 'rw');
has 'index' => (is => 'rw', default => 'index');

sub BUILD {
    my $self = shift;
    my ($args) = @_;
    my $conf = {};
    if ($args->{conf}) { $conf = load_config_files($args->{conf}); }
    override_hash($conf, $args);
    $self->{e} = new Database;
    $args->{db_condition} ||= DB_WRITER | DB_CREATE;
    $self->{e}->open($conf->{index}, $args->{db_condition}) or
        confess $self->error(q|can't create the Estraier Object|);
}

sub search {
    my $self = shift;
    my ($keyword, $opt) = @_;
    my $cond = new Condition;
    defined $opt->{limit} and $cond->set_max($opt->{limit});
    defined $opt->{offset} and $cond->set_skip($opt->{offset});
    $cond->set_phrase($keyword);
    my $e = $self->{e};
    my $res = $e->search($cond);
    my $n = $res->doc_num - 1;
    my @ret = ();
    for my $i (0..$n) {
        push @ret, $e->get_doc($res->get_doc_id($i), 0);
    }
    return wantarray ? @ret : \@ret;
}

sub register {
    my $self = shift;
    my ($uri, $text, $attr) = @_;
    my $doc = new Document;
    $doc->add_attr('@uri', $uri);
    $doc->add_text($text);
    for (keys %$attr) {
        $doc->add_attr($_, $attr->{$_});
    }
    $self->{e}->put_doc($doc, Database::PDCLEAN) or
        die $self->error(q|can't put the doc into the document|);
    return $doc->id;
}

sub add_attr_index {
    my $self = shift;
    $self->{e}->add_attr_index(@_);
}

sub error {
    my $self = shift;
    my ($msg) = @_;
    return $msg . sprintf('(%s)', $self->{e}->err_msg($self->{e}->error));
}

sub close {
    my $self = shift;
    $self->{e}->close or die $self->error(q|can't close the database|);
}

sub DESTROY {
    my $self = shift;
    $self->close;
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
