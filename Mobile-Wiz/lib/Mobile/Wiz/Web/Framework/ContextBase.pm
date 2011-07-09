package Mobile::Wiz::Web::Framework::ContextBase;

use Encode qw(from_to);

use Wiz::Noose;
use Wiz::DateTime;
use Wiz::DateTime::Formatter qw(HTTP);

use Mobile::Wiz::Web::Framework::Session::Controller;

extends qw(
    Wiz::Web::Framework::ContextBase
);

sub _init_c {
    my $self = shift;
    my ($c) = @_;
    if ($c->req->method eq 'POST' && $c->is_mobile) {
        if ($c->is_docomo || $c->is_ezweb) {
            my $p = $c->req->params;
            for (keys %$p) {
                $p->{$_} =~ /^[[:ascii:]]*$/ and next;
                from_to($p->{$_}, $c->mobile_encoding, 'utf-8');
            }
        }
    }
    my $now = new Wiz::DateTime;
    $c->res->header('Cache-Control' => 'no-cache');
    $c->res->header(Pragma => 'no-cache');
    $c->res->header(Expires => $now->to_string(HTTP));
}

sub _modify_template_path_on_stash {
    my $self = shift;
    my ($c) = @_;
    my $stash = $c->stash;
    if ($c->is_mobile) {
        $stash->{template_sub_dir} = "mobile/$stash->{template_sub_dir}";
        $stash->{template_base} = $self->app_root . "/tmpl/$stash->{template_sub_dir}/"
    }
    if ($stash->{template} && $stash->{template} !~ /^\//) { 
        $stash->{template} = "/$stash->{template}";
    }
}

sub _tt_pre_process {
    my $self = shift;
    return [
        $self->app_root . '/tmpl/include/macro.tt',
        $self->app_root . "/tmpl/mobile/include/macro.tt",
    ];
}

sub _output_filter {
    my $self = shift;
    my ($c, $output) = @_;
    my $conf = $self->app_conf('mobile');
    $c->convert_emoji($output);
    $conf->{auto_append_guid_on} and $c->is_docomo and $c->append_guid_on($output);
    my $mime = $conf->{content_type_only_html} ? 'text/html' : 'application/xhtml+xml';
    if ($c->is_docomo) {
            $c->res->content_type("$mime;charset=". $c->mobile_charset);
    }
    elsif ($c->is_ezweb) {
        $c->res->content_type("$mime;charset=Shift_JIS");
    }
}

sub init_session_controller {
    my $self = shift;
    $self->{session_controller} =
        new Mobile::Wiz::Web::Framework::Session::Controller(conf => $self->app_conf->{session});
}

=head1 AUTHOR

Junichiro NAKAMURA, C<< <jyun16@gmail.com> >>

[Modify] Toshihiro MORIMOTO C<< dealforest.net@gmail.com >>

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


