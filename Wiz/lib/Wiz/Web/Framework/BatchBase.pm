package Wiz::Web::Framework::BatchBase;

use strict;

=head1 NAME

Wiz::Web::Framework::BatchBase

=head1 VERSION

version 1.0

=cut

use Wiz::Constant qw(:common);
use Wiz::Util::Hash qw(args2hash);
use Wiz::Util::System qw(check_multiple_execute);
use Wiz::Web::Framework::ContextBase;
use Wiz::Web::Framework::Context;
use Wiz::Message;

our $VERSION = '1.0';

use base qw(Exporter);

our @EXPORT = qw(
    get_context
    get_args
    get_message
    app_name
    lock_dir
    only_single_process
    lock_file_name_with_args
);

our $APP_ROOT;
our $APP_NAME;
our $SCRIPT_NAME;
our $SCRIPT_PATH;
our $WARNING = TRUE;

BEGIN {
    use FindBin;
    my @path = split /\//, $FindBin::Bin;
    my $is_root = 0;
    for (my $i = $#path; $i > 0; $i--) {
        if ($is_root) {
            $APP_NAME = $path[$i];
            $path[$i] =~ /scripts?$|trunk$|branches$|branch$|tags?$|\d+$/ or last;
        }
        else {
            if ($path[$i] eq 'bin') { $is_root = 1; }
            pop @path;
        }
    }
    
    $APP_ROOT = join '/', @path;
    $SCRIPT_NAME = $FindBin::Script;
    $SCRIPT_PATH = $FindBin::Bin;
    push @INC, "$APP_ROOT/lib";
};

sub get_args {
    my ($appended) = @_;
    use Wiz::Args::Simple qw(getopts);
    my $args = getopts(<<"EOS");
e(env):
h(help)
$appended
EOS
    $args->{h} and do { ::usage(); exit 0; };
    $ENV{WIZ_APP_ENV} = $args->{env};
    return $args;
}

sub get_context {
    no strict 'refs';
    my ($opts) = args2hash @_;
    my $cb = new Wiz::Web::Framework::ContextBase(
        app_name    => $APP_NAME,
        app_root    => $APP_ROOT,
        conf        => \%{*{"$APP_NAME\::CONFIG"}},
        %$opts
    );
    bless $cb, 'Wiz::Web::Framework::Context';
}

sub get_message {
    my ($c, $param) = @_;
    new Wiz::Message(
        base_dir   => $c->app_root . '/message',
        %$param,
    );
}

sub lock_dir { "$SCRIPT_PATH/lock"; }

sub lock_file_name_with_args {
    my ($args, $options) = @_;
    my @a;
    for (@$options) { $args->{$_} and push @a, $args->{$_}; }
    my $ret = $SCRIPT_NAME;
    @a and $ret .= '_' . join '_', @a;
    return $ret;
}

sub only_single_process {
    my ($msg, $lock_file) = @_;
    my $lock_dir = lock_dir;
    $lock_file or $lock_file = $SCRIPT_NAME;
    -d $lock_dir or mkdir $lock_dir;
    local $Wiz::Util::System::WARNING = $WARNING;
    unless (check_multiple_execute("$lock_dir/$lock_file")) {
        $msg and print STDERR "$msg\n";
        exit 1;
    }
}

=head1 AUTHOR

Junichiro NAKAMURA, C<< <jyun16@gmail.com> >>

Toshihiro MORIMOTO C<< dealforest.net@gmail.com >>

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


