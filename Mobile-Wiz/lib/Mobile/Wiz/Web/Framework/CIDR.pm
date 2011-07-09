package Mobile::Wiz::Web::Framework::CIDR;

use Any::Moose;

use Net::CIDR::MobileJP;
use WWW::MobileCarrierJP 0.19;
use WWW::MobileCarrierJP::DoCoMo::CIDR;
use WWW::MobileCarrierJP::EZWeb::CIDR;
use WWW::MobileCarrierJP::AirHPhone::CIDR;
use WWW::MobileCarrierJP::ThirdForce::CIDR;

use Wiz::Constant qw(:common);
use Wiz::Util::Array qw(array_equals);

our $MOBILE_NAME_LONG2SHORT = {
    DoCoMo     => 'I',
    EZWeb      => 'E',
    AirHPhone  => 'H',
    ThirdForce => 'V',
};

our $MOBILE_NAME_SHORT2LONG = {
    I   => 'DoCoMo',
    E   => 'EZWeb',
    H   => 'AirH',
    V   => 'SoftBank',
};

has 'memcached' => (is => 'rw');
has 'cache_key' => (is => 'rw');
has 'cache' => (is => 'rw');
has 'exclusive_dest' => (is => 'rw');

sub BUILD {
    my $self = shift; 
    my ($args) = @_;
    $self->{cache} = new Cache::Memcached::Fast($self->{memcached});
    if (my $dest = $self->exclusive_dest) {
        ref $self->exclusive_dest or $dest = [$self->exclusive_dest];
        $self->exclusive_dest([
            map { my ($i, $m) = split '/'; { ip => $i, subnetmask => '/'. ($m || 32) } } @{$self->exclusive_dest}
        ]);
    }
}

sub get {
    my $self = shift;
    my $result;
    for my $carrier (qw/DoCoMo EZWeb AirHPhone ThirdForce/) {
        my $class = "WWW::MobileCarrierJP::${carrier}::CIDR";
        my $dat = $class->scrape;
        $self->exclusive_dest and push @$dat, @{$self->exclusive_dest};
        $result->{$MOBILE_NAME_LONG2SHORT->{$carrier}} = [map { "$_->{ip}$_->{subnetmask}" } @$dat];
    }
    return $result;
}

sub update_memcached {
    my $self = shift;
    my $new_cidr = $self->get;
    my $memd = $self->{cache};
    my $cidr = $memd->get($self->{cache_key});
    if ($cidr) {
        for (qw(E V I H)) {
            unless(array_equals($cidr->{$_}, $new_cidr->{$_})) {
                $memd->set($self->{cache_key}, $new_cidr);
                last;
            }
        }
    }
    else {
        $memd->set($self->{cache_key}, $new_cidr);
    }
}

sub is_mobile {
    shift->carrier(@_) eq 'N' ? FALSE : TRUE;
}

sub is_non_mobile {
    shift->carrier(@_) eq 'N' ? TRUE : FALSE;
}

sub carrier {
    my $self = shift;
    my ($ip) = @_;
    my $memd = $self->{cache};
    my $cidr = new Net::CIDR::MobileJP($memd->get($self->{cache_key}));
    $cidr->get_carrier($ip);
}

sub carrier_longname {
    my $self = shift;
    $MOBILE_NAME_SHORT2LONG->{$self->carrier(@_)};
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


