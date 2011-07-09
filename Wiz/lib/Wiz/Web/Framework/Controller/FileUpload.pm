package Wiz::Web::Framework::Controller::FileUpload;

=head1 NAME

Wiz::Web::Framework::Controller::FileUpload

=head1 SYNOPSIS
 
=head1 VERSION

version 1.0

=cut

our $VERSION = '1.0';

=head1 SYNOPSIS

=cut

use MIME::Type;

use Wiz::Noose;
use Wiz::Util::File qw(dirname mkdir);
use Wiz::Util::String qw(randstr split_prefix);

extends qw(Wiz::Web::Framework::Controller);

no warnings 'uninitialized';

my %mime_image_ext = (
    'image/gif'     => 'gif',
    'image/jpeg'    => 'jpg',
    'image/pjpeg'    => 'jpg',
    'image/png'     => 'png',
);

sub _save_image {
    my $self = shift;
    my ($c, $af, $name, $conf) = @_;
    my $u = $c->req->upload($name) or return;
    if ($u->size > $c->conf->{max_upload_file_size}) {
        $c->applog("error")->error("over max size");
        $af->outer_error($name => $c->validation_message('over_max_size'));
        return;
    }
    my $fn = (join '/', @{split_prefix(randstr($conf->{name_length}), $conf->{dir_depth})}) .
        '.' . $mime_image_ext{$u->type};

    my $fp = $conf->{dir}{tmp} . "/$fn";
    my $abs_fp = $c->path_to($fp);
    -d dirname $abs_fp or mkdir dirname $abs_fp;

    unless ($u->copy_to($abs_fp)) {
        $c->applog("error")->error("can't create category image $abs_fp: $!");
        $af->outer_error($name => $c->error_message('file_upload_failed'));
        return;
    }

    my $tconf = $conf->{thumbnail};
    $self->_save_image_thumbnail($c, $conf, $fn, $abs_fp, $tconf);

    for (2..10) {
        $conf->{"thumbnail$_"} or next;
        $self->_save_image_thumbnail($c, $conf, $fn, $abs_fp, $conf->{"thumbnail$_"});
    }

    my $uri = $conf->{uri}{tmp} . "/$fn";
    my $turi = $conf->{uri}{tmp} . "/$tconf->{dir}/$fn";
    $uri =~ s/^\///; $turi =~ s/^\///;
    $af->param($name => $fn);
    $af->param("${name}_url" => $uri);
    $af->param("${name}_thumb_url" => $turi);

    my $s = $self->_session($c);
    $s->{$name} = $fn;
    $s->{"${name}_url"} = $uri;
    $s->{"${name}_thumb_url"} = $turi;

    my @ret = (
        $s->{$name},
        $s->{"${name}_url"},
        $s->{"${name}_thumb_url"},
    );
    return wantarray ? @ret : \@ret;
}

sub _save_image_thumbnail {
    my $self = shift;
    my ($c, $conf, $fn, $abs_fp, $tconf) = @_;

    my $tfp = $conf->{dir}{tmp} . "/$tconf->{dir}/$fn";
    my $abs_tfp = $c->path_to($tfp);
    -d dirname $abs_tfp or mkdir dirname $abs_tfp;
    `convert -sample $tconf->{width}x$tconf->{height} $abs_fp $abs_tfp`;    
}

sub _commit_image {
    my $self = shift;
    my ($c, $af, $name, $conf) = @_;
    my $s = $self->_session($c);
    my $fn = $s->{${name}};
    $fn eq '' and return;
    my $abs_fp = $c->path_to("$conf->{dir}{tmp}/$fn");
    my $abs_mfp = $c->path_to("$conf->{dir}{main}/$fn");
    if (-f $abs_fp) {
        -d dirname $abs_mfp or mkdir dirname $abs_mfp;
        `cp $abs_fp $abs_mfp`;
        unlink $abs_fp;
    }
    $self->_commit_image_thumbnail($c, $conf, $fn, $abs_fp, $conf->{thumbnail});
    for (2..10) {
        $conf->{"thumbnail$_"} or next;
        $self->_commit_image_thumbnail($c, $conf, $fn, $abs_fp, $conf->{"thumbnail$_"});
    }
}

sub _commit_image_thumbnail {
    my $self = shift;
    my ($c, $conf, $fn, $abs_fp, $tconf) = @_;
    my $abs_tfp = $c->path_to("$conf->{dir}{tmp}/$tconf->{dir}/$fn");
    my $abs_mtfp = $c->path_to("$conf->{dir}{main}/$tconf->{dir}/$fn");
    if (-f $abs_tfp) {
        -d dirname $abs_mtfp or mkdir dirname $abs_mtfp;
        `cp $abs_tfp $abs_mtfp`;
        unlink $abs_tfp;
    }
}

sub _remove_image {
    my $self = shift;
    my ($c, $af, $fn, $conf) = @_;

    my $tconf = $conf->{thumbnail};
    unlink "$conf->{dir}{main}/$fn";
    unlink "$conf->{dir}{main}/$tconf->{dir}/$fn";
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
