package Mobile::Wiz::Web::Framework;

use Class::Inspector;

use Wiz::ConstantExporter [qw(
    framework_load
    mobile_only
    force_sjis
)];

sub framework_load {
    my $package;
    my $type = '';
    if ($ENV{MOD_PERL}) {
        $package = 'Mobile::Wiz::Web::Framework::Server::Apache2';
    }
    elsif (Class::Inspector->loaded('nginx')) {
        $package = 'Mobile::Wiz::Web::Framework::Server::Nginx';
        $type = 'nginx';
    }
    else {
        $package = 'Mobile::Wiz::Web::Framework::Server::HTTPD';
    } 
    eval "use $package;";
    if ($@) { print STDERR "[ERROR] $@"; }
    else {
        my $symbols = \%{*{"$package\::"}};
        my ($target) = caller;
        for (keys %$symbols) { *{"${target}::$_"} = $symbols->{$_}; } 
    }
}

sub mobile_only {
    *Mobile::Wiz::Web::Framework::Context::is_mobile = sub { 1; };
}

sub force_sjis {
    *Mobile::Wiz::Web::Framework::Context::mobile_encoding = sub { 'sjis'; };
    *Mobile::Wiz::Web::Framework::Context::mobile_charset = sub { 'Shift_JIS'; };
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


