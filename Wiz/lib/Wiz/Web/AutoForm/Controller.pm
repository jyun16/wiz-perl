package Wiz::Web::AutoForm::Controller;

use strict;
use warnings;

=head1 NAME

Wiz::Web::AutoForm::Controller

=head1 VERSION

version 1.0

=cut

our $VERSION = '1.0';

=head1 SYNOPSIS

SEE L<Wiz::Web::AutoForm::Tutorial>

=cut

use Carp;

use Wiz::Constant qw(:common);
use Wiz::Util::File qw(extended_config_tree);
use Wiz::Util::Hash qw(hash_access_by_list);
use Wiz::Web::AutoForm;
use Wiz::Web::AutoForm::JA;
use Wiz::Message;
use Wiz::Util::PDS;

use base qw(Class::Accessor::Fast);

__PACKAGE__->mk_accessors(qw(conf language));

=head1 CONSTRUCTOR

=cut

my %default = (
    language => 'en',
);

sub new {
    my $self = shift;
    my ($conf_dir, $message, $opts) = @_;
    $opts->{use_pds} ||= {};
    my $instance = bless {
        conf        => $opts->{pds_pkg} ?
            load_autoform_pds($opts->{pds_pkg}, $conf_dir) :
            extended_config_tree($conf_dir, 1), 
        _autoforms  => {},
        _message    => _init_message($message),
        use_pds     => $opts->{pds_pkg} ? TRUE : FALSE,
    }, $self;
    return $instance;
}

sub load_autoform_pds {
    my ($pds_pkg, $conf_dir) = @_;
    opendir my $d, $conf_dir or die "Can't open directory $conf_dir ($!)";
    my %ret;
    for my $f (grep !/^\.\.?/, readdir($d)) {
        $ret{$f} = load_pds("${pds_pkg}::" . ucfirst $f, "$conf_dir/$f");
    }
    closedir $d;
    return \%ret;
}

=head2 autoform($action, $param, $options)

$action: action name
$param: query parameter values

=cut

sub autoform {
    my $self = shift;
    my ($action, $param, $opts) = @_;
    no warnings 'uninitialized';
    my $action_key;
    if ($self->{use_pds}) {
        ref $action and $action = $action->[0];
        $action_key = $action;
    }
    else {
        ref $action or $action = [ $action ];
        $action_key = join '/', @$action;
    }
    my ($language, $message) = ($default{language}, $self->{_message});
    if (defined $opts) {
        defined $opts->{language} and $language = $opts->{language};
        defined $opts->{message} and $message = $opts->{message};
    }
    if (exists $self->{_autoforms}{$language}{$action_key}) {
        my $af = $self->{_autoforms}{$language}{$action_key};
        $af->clear;
        if (ref $param eq 'ARRAY') { $af->list_values($param); }
        else { $af->params($param); }
        return $af;
    }
    else {
        my $conf;
        if (defined $self->{conf}{default} and not defined $self->{conf}{$language}) {
            $language = 'default';
        }
        if ($self->{use_pds}) {
            $conf = $self->{conf}{$language}{$action};
        }
        else {
            $conf = hash_access_by_list($self->{conf}{$language}, $action);
        }
        # TODO Other country
        my $af = new Wiz::Web::AutoForm::JA($action_key, $param, $conf, $language, $message);
        $self->{_autoforms}{$language}{$action_key} = $af;
        return $af;
    }
}

=head1 METHODS

=cut

# ----[ private ]-----------------------------------------------------

=head1 FUNCTIONS

=cut

# ----[ static ]------------------------------------------------------
# ----[ private static ]----------------------------------------------

sub _init_message {
    my $message = shift;
    defined $message or return undef;
    return (ref $message eq 'Wiz::Message') ?
        $message : new Wiz::Message($message);
}

=head1 AUTHOR

Junichiro NAKAMURA, C<< <jyun16@gmail.com> >>

=head1 COPYRIGHT & LICENSE

Copyright 2008 The Wiz Project. All rights reserved.

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
