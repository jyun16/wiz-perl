package Wiz::Web::Util;

use strict;

=head1 NAME

Wiz::Web::Util

=head1 VERSION

version 1.0

=cut

use URI;
use URI::Escape;
use LWP::Simple;
use LWP::UserAgent;

use Wiz::Constant qw(:common);
use Wiz::Util::Hash qw(args2hash);
use Wiz::DateTime;

our $VERSION = '1.0';

use Wiz::ConstantExporter [qw(
    html_escape
    html_unescape
    uri_escape
    uri_unescape
    query_param
    append_query_param
    query2hash
    parse_query
    download
    site_last_modified
)];

our $FAKE_USER_AGENT = 'Mozilla/5.0';

=head1 FUNCTIONS

=head2 $escaped_data = html_escape($data or \$data)

HTML escape.

=cut

sub html_escape {
    my $data = shift;
    my $d = ref $data ? $data : \$data;
    if (my $r = ref $d) {
        if ($r eq 'ARRAY') { return [ map html_escape($_), @$d ]; }
        else { defined $$d or return; }
    }
    my %rep = (
        '&' => 'amp',
        '<' => 'lt',
        '>' => 'gt',
        '"' => 'quot',
        "'" => '#39',
    );
    $$d =~ s/([&<>"'])/&$rep{$1};/g;
    return $$d;
}

=head2 $unescaped_data = html_unescape($data or \$data)

HTML unescape.

=cut

sub html_unescape {
    my $data = shift;
    my $d = ref $data ? $data : \$data;
    if (my $r = ref $d) {
        if ($r eq 'ARRAY') { return [ map html_escape($_), @$d ]; }
        else { defined $$d or return; }
    }
    my %rep = (
        amp     => '&',
        lt      => '<',
        gt      => '>',
        quot    => '"',
        '#39'   => "'",
    );
    $$d =~ s/&(amp|lt|gt|quot|#39);/$rep{$1}/g;
    return $$d;
}

{
    no strict 'refs';
    *uri_escape = \&{"URI::Escape::uri_escape"};
    *uri_unescape = \&{"URI::Escape::uri_unescape"};
}

sub query_param {
    my $args = args2hash @_;
    my $uri = new URI;
    $uri->query_form($args);
    return $uri->query;
}

sub append_query_param {
    my $url = shift;
    my $args = args2hash @_;
    my $uri = new URI($url);
    my %qf = $uri->query_form;
    for (keys %$args) { $qf{$_} = $args->{$_}; }
    $uri->query_form(%qf);
    return $uri->as_string;
}

=head2 $hash_ref = query2hash($data)

HTML unescape.

=cut

sub query2hash {
    my %ret = ();
    for (split /&/, shift) {
        my ($k, $v) = split /=/;
        $ret{$k} = $v;
    }
    return \%ret;
}

sub parse_query {
    my ($query) = @_;
    my %ret = ();
    for (split /&/, $query) {
        my ($k, $v) = split /=/;
        $ret{uri_escape($k)} = uri_escape($v);
    }
    return \%ret;
}

sub download {
    my ($uri, $path, $opt) = @_;
    my $content = get $uri;
    my $length = length $content;
    $length or return;
    $opt->{min_size} and $length < $opt->{min_size} and return;
    $opt->{max_size} and $length > $opt->{max_size} and return;
    open my $f, '>', $path;
    print $f $content;
    close $f;
}

sub site_last_modified {
    my ($url) = @_;
    my $ua = new LWP::UserAgent;
    $ua->agent($FAKE_USER_AGENT);
    my $r = $ua->head($url);
    my $lm = $r->header('last-modified');
    if ($lm) {
        my $ret = new Wiz::DateTime;
        $ret->parse('RFC822', $lm);
        return $ret;
    }
    return;
}

=head1 AUTHOR

Junichiro NAKAMURA, C<< <jyun16@gmail.com> >>

=head1 COPYRIGHT & LICENSE

Copyright 2008,2009 The Wiz Project. All rights reserved.

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


