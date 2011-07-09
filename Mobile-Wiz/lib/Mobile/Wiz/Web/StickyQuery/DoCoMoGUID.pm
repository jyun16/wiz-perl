package Mobile::Wiz::Web::StickyQuery::DoCoMoGUID;

use strict;
use warnings;

use base qw(HTML::StickyQuery::DoCoMoGUID);

sub new {
    my($class, %args) = @_; 
    my $self = $class->SUPER::new(%args);
    $self->{sticky}{__base} = $args{base};
    $self;
}

sub sticky {
    my($self, %args) = @_; 
    local *_start = *HTML::StickyQuery::start;
    local *HTML::StickyQuery::start = *start;
    $self->SUPER::sticky(%args);
}

sub start {
    my($self, $tagname, $attr, $attrseq, $orig) = @_;
    if ($self->{__base} && $tagname eq 'a' && $attr->{href} && $attr->{href} =~ /^$self->{__base}/) {
        my $u = new URI($attr->{href});
        my %param = $u->query_form;
        %param = %param ? (%param, %{$self->{param}}) : %{$self->{param}};
        $u->query_form(%param);
        $orig =~ /^(.*href=").*(".*)$/;
        $self->{output} .= ($1. $u->as_string. $2);
        return;
    }
    $tagname ne 'form' and goto &_start;
    $self->SUPER::start($tagname, $attr, $attrseq, $orig);
}

1;

=cut

=head1 AUTHOR

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

=head1 SEE ALSO

L<HTML::StickyQuery>, L<HTML::StickyQuery::DoCoMoGUID>, L<http://www.nttdocomo.co.jp/service/imode/make/content/ip/index.html#imodeid>

=cut
