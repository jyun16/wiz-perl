package Wiz::HTTP::Response;

=head1 NAME

Wiz::HTTP::Response

=head1 VERSION

version 1.0

=cut

use CGI::Simple::Cookie;
use HTTP::Headers;

use Wiz::Constant qw(:common);

our $VERSION = '1.0';

use base 'HTTP::Response';

sub init {
    my $self = shift;
    $self->code(200);
    $self->content(undef);
    $self->{_headers} = new HTTP::Headers(
        'Content-Type' => 'text/html'
    );
}

sub complement {
    my $self = shift;
    $self->implement_cookie_headers;
}

sub redirect {
    my $self = shift;
    $self->code(302);
    $self->header('location' => shift);
}

sub cookies {
    my $self = shift;
    $self->{cookies} ||= {};
    return $self->{cookies};
}

sub content_type {
    my $self = shift;
    @_ and $self->header('content-type' => shift);
    return $self->header('content-type');
}

sub filename {
    my $self = shift;
    my ($filename) = @_;
    defined $filename and $self->header('content-disposition' => "attachment; filename=$filename");
    return;
}

sub implement_cookie_headers {
    my $self = shift;
    my $cookies = $self->{cookies};
    for my $name (keys %$cookies) {
        my $cookie = $cookies->{$name};
        my %param = (-name => $name);
        for (qw(value domain path expires secure)) {
            if (defined $cookie->{$_} or defined $cookie->{"-$_"}) {
                $param{"-$_"} = $cookie->{$_};
            }
        }
        $self->headers->push_header('set-cookie' => new CGI::Simple::Cookie(%param));
    }
}

sub body { shift->content(@_); }

sub status {
    my $self = shift;
    $self->code(@_);
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


