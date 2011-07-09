package Wiz::Web::Framework::Controller::SimpleMail;

=head1 NAME

Wiz::Web::Framework::Controller::SimpleMail

=head1 VERSION

version 1.0

=cut

our $VERSION = '1.0';

=head1 SYNOPSIS

=cut

use Template;
use Devel::Symdump;

use Wiz::Noose;
use Wiz::SimpleMail;
use Wiz::Web::Filter qw(:all);

extends qw(Wiz::Web::Framework::Controller);

no strict 'refs';

my %filters = ();
my @filters = Devel::Symdump->functions('Wiz::Web::Filter');

for (Devel::Symdump->functions('Wiz::Web::Filter')) {
    my @p = split /::/;
    my $f = pop @p;
    my $fn = $f;
    if ($f eq 'auto_link') { $fn = 'autolink'; }
    $filters{$fn} = [ sub {
        shift;
        my @args = @_;
        if ($f eq 'datetime') {
            @args = { format => $args[0] };
        }
        return sub {
            "$f"->(shift, @args);
        }
    }, 1 ];
}

sub _send_mail {
    my $self = shift;
    my ($c, $param, $template) = @_;

    my $mail_conf = $self->ourv('MAIL_CONF') || 'mail';
    my %conf = %{$c->app_conf($mail_conf)};
    my $tt = new Template(
        INCLUDE_PATH => [
            $c->path_to('tmpl'),
        ],
        COMPILE_DIR         => $c->path_to('tmpl/.cache'),
        COMPILE_EXT         => '.ttc',
        RECURSION           => 1,
        TRIM                => 1,
        ABSOLUTE            => 1,
        PRE_PROCESS         => $c->path_to('tmpl/include/macro.tt'),
        FILTERS             => \%filters,
    );
    my $tt_data = '';
    my $path = $c->app_root. "/tmpl/default/". $template;
    $tt->process("$path", $param, \$tt_data) or die $tt->error;
    my ($header, $body) = split /\n\n/, $tt_data, 2;
    my %header = ();
    for (split /\n/, $header) {
        $_ =~ /(.*):\s*(.*)/;
        $header{$1} = $2;
    }
    my $m = new Wiz::SimpleMail(%conf);
    my $from = $param->{from} || $header{From} || $conf{from};
    my $to = $param->{to} || $param->{email};
    $m->send(
        from        => $from,
        to          => $to,
        data        => $tt_data,
        header      => \%header,
    );
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
