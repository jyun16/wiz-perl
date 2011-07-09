package Wiz::Web::Framework::Controller::Download::CSV;

=head1 NAME

Wiz::Web::Framework::Controller::Download::CSV

=head1 VERSION

version 1.0

=cut

our $VERSION = '1.0';

=head1 SYNOPSIS

=cut

use Encode;
use Text::CSV_XS;

use Wiz::Noose;

extends qw(Wiz::Web::Framework::Controller);

sub _download {
    my $self = shift;
    my ($c, $data, $fields, $fields_labels) = @_;

    my $stash = $c->stash;
    $stash->{fields_labels} and $fields_labels = $stash->{fields_labels};

    my $csv_line_separator = $self->ourv('CSV_LINE_SEPARATOR') || "\n";
    my $csv_use_multi_byte = $self->ourv('CSV_USE_MULTI_BYTE') || 0;
    my $csv_enc_f = $self->ourv('CSV_ENCODE_FROM') || 'utf8';
    my $csv_enc_t = $self->ourv('CSV_ENCODE_TO') || 'utf8';
    my $csv = Text::CSV_XS->new($csv_use_multi_byte ? {binary => 1} : {});
    my $csv_data;
    my $enc_f = find_encoding($csv_enc_f);
    my $enc_t = find_encoding($csv_enc_t);
    $csv->combine(@$fields_labels);
    $csv_data .= $enc_t->encode($enc_f->decode($csv->string)) . $csv_line_separator;
    for (@$data) {
        $csv->combine(_hash2array($_, $fields));
        $csv_data .= $enc_t->encode($enc_f->decode($csv->string)) . $csv_line_separator;
    }
    my $filename = $stash->{filename} || sprintf('download_%s.csv', time);
    $c->res->header('Content-Type', 'text/csv');
    $c->res->header('Content-Disposition' => "attachment; filename=$filename");
    $c->res->body($csv_data);
    $c->req->action(undef);
}

sub download {
    my $self = shift;
    my ($c) = @_;
    no strict 'refs';
    my $m = $c->slave_model($self->ourv('MODEL'));
    my $csv_data_method = $self->ourv('CSV_DATA_METHOD') || 'csv_data';
    my $param = $self->_create_search_param($c, $m);
    $self->_append_search_param($c, $param, $m);
    my $data = $m->$csv_data_method($param);
    $self->_before_download($c, $data);
    $self->_download($c, $data, [@{ref($m) . "::CSV_DATA_FIELDS"}], [@{ref($m) . "::CSV_DATA_FIELDS_LABELS"}]);
    $self->_after_download($c, $data);
}

sub _before_download {}
sub _after_download {}
sub _append_search_param {}

sub _create_search_param {
    my $self = shift;
    my ($c, $m) = @_;

    my %param = ();
    if ($self->ourv('CSV_ORDER', '@')) {
        $param{-order} = [ $self->ourv('CSV_ORDER', '@') ];
    }
    my $like_search = { $self->ourv('CSV_LIKE_SEARCH', '%') };
    for my $k ($m->ourv('CSV_SEARCH', '@')) {
        my $p = $c->req->param($k);
        defined $p or $p = '';
        $p eq '' and next;
        my @p = split /\s/, $p;
        if (@p > 1) {
            if (defined $like_search->{$k}) {
                my @d = ();
                my $sub = like_sub($like_search->{$k});
                for (@p) {
                    push @d, [ 'like', $k, $sub->($_) ],
                }
                $param{-or} = \@d;
            }
            else { $param{-in} = { $k => \@p, }; }
        }
        else {
            if (defined $like_search->{$k}) {
                $param{$k} = [ 'like', like_sub($like_search->{$k})->($p) ];
            }
            else { $param{$k} = $p; }
        }
    }
    return \%param;
}

sub _hash2array {
    my ($data, $fields) = @_;
    if (ref $data eq 'HASH') {
        my @ret = ();
        for (@$fields) {
            push @ret, $data->{$_};
        }
        return @ret;
    }
    return @$data;
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
