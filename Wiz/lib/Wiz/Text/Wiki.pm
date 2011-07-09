package Wiz::Text::Wiki;

use File::BOM qw(open_bom);

use Wiz::Noose;
use Wiz::Web::Util::AutoLink qw(auto_link);

has 'data' => (is => 'rw');
has 'mode' => (is => 'rw');
has 'nest_mode' => (is => 'rw');

sub BUILD {
    my $self = shift;
    my ($args) = @_;
    $args->{file} and $self->file($args->{file}); 
    return $self;
}

sub html {
    my $self = shift;
    $self->generate;
    return $self->{html} || '';
}

sub file {
    my $self = shift;
    my ($path) = @_;
    $self->{data} = _read_file_data($path);
}

sub generate {
    my $self = shift;
    my $wiki_data = $self->{data};
    $wiki_data !~ /\n$/ and $wiki_data .= "\n";
    no strict 'refs';
    while ($wiki_data =~ /
        ^(?<hr>-{4})\n|
        ^'(?<bold>.*)'|
        ^(?<h>\*+)(?<h_str>.*)\n|
        ^(?<ul>\.+)\s*(?<li_str>.*)\n|
        ^(?<ol>,+)\s*(?<li_str>.*)\n|
        \[\[(?<url>[^\]]*)\]\]|
        ^DL(?<dl_s>\>\>\>)\n|
        ^CODE-(?<code_s>.*)\>\>\>\n|
        ^(?<pre_s>\>\>\>)\n|
        ^(?<pre_e>\<\<\<)\n|
        ^(?<blockquote_s>}}})\n|
        ^(?<blockquote_e>{{{)\n|
        (?<other>.+)\n|
        (?<br>\n)
    /gmxo) {
        for (qw(hr h url other bold br)) {
            $+{$_} or next;
            my $m = "_generate_$_"; $self->$m();
            $self->_flush_nest_mode;
        }
        for (qw(pre blockquote)) {
            if ($+{"${_}_s"}) { $self->{mode} = $_; }
            elsif ($+{"${_}_e"}) {
                $self->_flush;
            }
        }
        for (qw(ul ol)) {
            $+{$_} or next;
            $self->{nest_mode} ne $_ and $self->_flush;
            $self->{nest_mode} = $_;
            $self->{nested_tmp} ||= [];
            _push_nested_tmp($self->{nested_tmp}, $+{li_str}, (length $+{$_}) - 1);
        }
        if ($+{dl_s}) { $self->{mode} = 'dl'; }
        elsif ($+{code_s}) { $self->{mode} = 'code'; $self->{code_class} = lc $+{code_s}; }
    }
    $self->_flush;
}

sub _push_nested_tmp {
    my ($nested_tmp, $data, $cnt) = @_;
    if ($cnt) {
        my $idx = scalar @$nested_tmp;
        $nested_tmp->[$idx] ||= [];
        _push_nested_tmp($nested_tmp->[$idx], $data, --$cnt);
    }
    else {
        push @{$nested_tmp}, $data;
    }
}

sub _flush {
    my $self = shift;
    $self->_flush_normal_mode;
    $self->_flush_nest_mode;
}

sub _flush_normal_mode {
    my $self = shift;
    $self->{mode} or return;
    my $m = '_generate_' . $self->{mode};
    $self->$m();
    $self->{mode} = undef;
    $self->{tmp} = undef;
}

sub _flush_nest_mode {
    my $self = shift;
    $self->{nest_mode} or return;
    my $mode;
    if ($self->{nest_mode} =~ /ul|ol/) { $mode = 'li'; }
    $mode or return;
    my $m = "_generate_$mode";
    $self->$m($self->{nest_mode}, $self->{nested_tmp});
    $self->{nest_mode} = undef;
    $self->{nested_tmp} = undef;
}

sub _generate_h {
    my $self = shift;
    my $size = length $+{h};
    $self->{html} .= "<h$size>$+{h_str}</h$size>\n";
}

sub _generate_bold {
    my $self = shift;
    my $str = $+{bold};
    $str =~ s/\\'/'/g;
    $self->{html} .= "<b>$str</b>";
}

sub _generate_hr {
    my $self = shift;
    $self->{html} .= "<hr />\n";
}

sub _generate_dl {
    my $self = shift;
    my $tmp = $self->{tmp};
    my $dl = "<dl>\n";
    while ($tmp =~ /
        ^\s+(?<dd>.*)\n|
        ^(?<dt>.*)\n
    /gmxo) {
        if ($+{dt}) { $dl .= "<dt>$+{dt}</dt>\n"; }
        elsif ($+{dd}) { $dl .= "<dd>$+{dd}</dd>\n"; }
    }
    $dl .= "</dl>\n";
    $self->{html} .= $dl;
}

sub _generate_code {
    my $self = shift;
    my $tmp = $self->{tmp};
    $self->{html} .= qq|<textarea name="code" class="$self->{code_class}">\n| . $tmp . "</textarea>\n";
}

sub _generate_pre {
    my $self = shift;
    $self->{html} .= "<pre>\n" . $self->{tmp} . "</pre>\n";
}

sub _generate_blockquote {
    my $self = shift;
    $self->{html} .= "<blockquote>\n" . $self->{tmp} . "</blockquote>\n";
}

sub _generate_li {
    my $self = shift;
    my ($type, $tmp) = @_;
    if (defined $tmp and ref $tmp eq 'ARRAY') {
        $self->{html} .= $type eq 'ul' ? "<$type type='disc'>\n" : "<$type>\n";
        for (@$tmp) {
            if (ref $_ eq 'ARRAY') {
                $self->_generate_li($type, $_);
            }
            else {
                $self->{html} .= "<li>$_</li>\n";
            }
        }
        $self->{html} .= "</$type>\n";
    }
}

sub _generate_url {
    my $self = shift;
    my ($url, $title, $target) = split /\|/, $+{url};
    $title ||= $url;
    $target and $target = qq| target="$target"|;
    $self->{html} .= qq|<a href="$url"$target>$title</a>|;
}

sub _generate_br {
    my $self = shift;
    $self->{html} .= "<br />\n";
}

sub _generate_other {
    my $self = shift;
    if ($self->{mode}) { $self->{tmp} .= "$+{other}\n"; }
    elsif ($self->{nest_mode}) {}
    else {
        my $other = $+{other};
        $other = auto_link($other, { target => '_blank' });
        $other =~ s/<size\s*(\d*)>/<font size="$1">/g;
        $other =~ s/<color\s*(.*?)>/<font color="$1">/g;
        $other =~ s/<\/(size|color)>/<\/font>/g;
        $self->{html} .= "$other\n";
    }
}

sub _read_file_data {
    my ($file) = @_;
    my $ret;
    open_bom my $f, $file;
    while (<$f>) { $ret .= $_; }
    close $f;
    return $ret;
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

