package Wiz::Message;

use strict;
use warnings;

=head1 NAME

Wiz::Message - handling I18N messages

=head1 VERSION

version 1.0

=cut

our $VERSION = '1.0';

=head1 SYNOPSIS

Create message data with external files(any format is ok, of cource .pdat) like the followings:

anyapp/message/ja/error.pdat:

 {
     error   => {
         service => {
             regist  => {
                 last_name   => {
                     not_null    => '氏名は必須です',
                 },
             },
         },
     },
     system_error    => {
         connection_error        => '接続エラーです',
     },
 }

anyapp/message/en/error.pdat:

 {
     error   => {
         service => {
             regist  => {
                 last_name   => {
                     not_null    =>  'Last name is a necessary condition',
                 },
             ,
         },
     },
     system_error    => {
         connection_error        => 'Connection failed',
     },
 }

Specify the path in constuctor argument.

 my %param = (
     base_dir        => 'anyapp/message',
     file_list_path  => 'filelist.pdat',
     input_encoding  => 'UTF-8', # default input encoding
     output_encoding => 'UTF-8', # default output encoding
     encoding        => { # override default encoding
         input   => { ja  => 'EUC-JP' },
         output  => { ja  => 'EUC-JP' },
     },
     pre_load        => [qw(ja en)],
     locale          => 'ja',
 );
 
 my $message = new Wiz::Message(%param);
 print $message->get('system_error', 'connection_error');

As a result, a message "接続エラーです" will be displayed.
You can write as the follwoing (recommended).

 print $message->system_error('connection_error'); # it is shortcut of the above

Change locale

 $message->language('en');

If you want to put direct message data to Wiz::Message,

 my $m = new Wiz::Message(
     data    => {
         en  => {
             validation    => {
                 hoge    => 'HOGE',
             },
         },
     }
 );

=head1 DESCRIPTION

This can handle I18N messges.
Simple configuration and simple interfaces to get messages.

=cut

use Carp qw(confess);
use Encode;
use Data::Dumper;

use Wiz qw(get_hash_args);
use Wiz::Constant qw(:common);
use Wiz::Config qw(load_config_files);
use Wiz::Util::File qw(file_write filename ls ls_r LS_DIR LS_FILE LS_ABS);
use Wiz::Util::Array qw(args2array);
use Wiz::Util::Hash qw(hash_access_by_list);

use base qw(Class::Accessor::Fast Wiz);

my @public_member = qw(base_dir input_encoding output_encoding encoding 
    language default_language pre_load);

__PACKAGE__->mk_accessors(@public_member);

my %default = (
    input_encoding      => 'ISO-8859-1',
    output_encoding     => 'ISO-8859-1',
    language            => 'default',
    default_language    => 'default',
);

no warnings 'uninitialized';

BEGIN {
    no strict 'refs';
    for my $m (qw(common error system system_error validation)) {
    *{ sprintf '%s::%s', __PACKAGE__, $m } =
        sub {
            my $self = shift;
            my @keys = @_;

            @_ == 1 and not defined $_[0] and return undef;
            @keys or return;

            unshift @keys, $m;
            return $self->get(\@keys);
        }
    }
}

=head1 CONSTRUCTOR

=head2 new(%param or \%param)

The constructor prepares hash-type cache for preserving file path which isn't pre-loaded. 

The cache has keys equivalent to top-level keys of message data, and corresponding values 
which indicates file names.
When accessing to unloaded data, the cache will be used to retrieve file name.

=head3 Arguments

'base_dir' is a base directory from where message files are read. 

'file_list_path' is a file which includes a list of message files, created by create_file_list().

'pre_load' can be used to specify some locales. 
Messages of those locales are to be loaded to memory immediately the instance is created. 

For example, all files in "./message/ja" are loaded into memory when "ja" is specified in pre_load.

To specify pre_loaded files strictly, do like self.

 pre_load('ja/error.dat', 'ja/system_error.dat');

=cut

sub new {
    my $self = shift;
    my $args = get_hash_args(@_);

    if (not defined $args->{data}) {
        defined $args->{base_dir} or confess "please input base_dir.";
        $args->{data} = {};
    }

    my $instance = bless {
        data => $args->{data},  
    }, $self;

    for (@public_member) {
        if (defined $args->{$_}) { $instance->{$_} = $args->{$_}; }
        elsif (exists $default{$_}) { $instance->{$_} = $default{$_}; }
    }

    if ($args->{base_dir}) {
        $instance->_init_file_list($args->{file_list_path});
        $args->{pre_load} and $instance->load($args->{pre_load});
    }

    return $instance;
}

=head1 METHODS

=head2 get(@keys)

Returns message.

 my $regist_service_error = $message->get(qw(error service regist));
 $regist_service_error->{last_name}{not_null};

'get' method returns a hashref when the target isn't a string.
It is useful to reduce the times of dereference, especially when the message hierarchy is too deep.

But, B<to use the following methods instead>, is recommended.

 common
 error
 system
 system_error
 validation

Those methods are also available. We can use them like the followings.

 my $regist_service_error = $message->error(qw(service regist));

=head2 language($language)

To change locale afterward, do like self. The instance changes referring messages to 'en'.

 $message->language('en');

=cut

sub get {
    my $self = shift;
    my $keys = args2array(@_);

    @_ == 1 and not defined $_[0] and return undef;
    @$keys or return;
   
    my $ret = undef;
    my $data = $self->{data}{$self->{language}};

    if (defined $data) {
         $ret = hash_access_by_list($data, $keys);
    }

    defined $ret or $ret = $self->get_by_file_list($keys);

    return $ret;
}

=head2 load(@path)

load message files. If files are already loaded, do nothing.

=cut

sub load {
    my $self = shift;
    my $load = args2array(@_);

    @$load or return;

    for my $language (@$load) {
        $self->{data}{$language} and next;
        $self->_load($language);
    }
}

=head2 reload(@path)

reload message files. Even if files are already loaded, load files.

=cut

sub reload {
    my $self = shift;
    my $load = args2array(@_);

    for my $language (@$load) {
        $self->_load($language);
    }
}

=head2 file_load($language, $path_to_message)

load messae file($path_to_message) as $language.
If the language message is already defined,
new message is added to original message.

=cut

sub file_load {
    my $self = shift;
    my ($language, $path) = @_;

    my $data = $self->_get_file_data($language, $path);

    if (defined $self->{data}{$language}) {
        my $d = $self->{data}{$language};
        for (keys %$data) {
            $d->{$_} = $data->{$_};
        }
    }
    else {
        $self->{data}{$language} = $data;
    }
}

=head2 get_by_file_list(\@keys)

Retruns message like C<get>.
C<get> check instance's cache. but C<get_by_file_list> never check cache.

=cut

sub get_by_file_list {
    my $self = shift;
    my ($keys) = @_;

    my $data = $self->_get_file_data($self->{language},
        $self->{_file_list}{$self->{language}}{$keys->[0]});

    return hash_access_by_list($data, $keys);
}

=head2 create_file_list

Traverses across the 'base_dir' directory and creates the following data. 

 {
     'ja' => {
         'error' => 'error.pdat',
         'system' => 'system.pdat',
     },
     'en' => {
         'error' => 'error.pdat',
         'system' => 'system.pdat',
     },
     ...
 }

=cut

sub create_file_list {
    my $self = shift;

    my %list = ();
    my @languages = map { filename $_ } ls($self->{base_dir}, LS_DIR);
    for my $l (@languages) {
        grep /$l/, @{$self->{pre_load}} and next;
        my $files = ls_r("$self->{base_dir}/$l", LS_FILE | LS_ABS);
        for my $f (@$files) {
            my $data = load_config_files($f);
            for my $k (keys %$data) {
                $list{$l}{$k} = $f;
            }
        }
    }
    return \%list;
}

=head2 create_file_list_file($path)

Output the data to get by create_file_list into file.

=cut

sub create_file_list_file {
    my $self = shift;
    my ($path) = @_;

    local $Data::Dumper::Terse = 1;
    local $Data::Dumper::Indent = 1;

    my $data = Dumper $self->{_file_list};
    file_write($path, $data);
}

=head2 can_use_language(@languages | \@languages)

Returns a locale that the instance has.
If no argument is passed, it returns default language.

=cut

sub can_use_language {
    my $self = shift;
    my $args = args2array(@_);

    for (@$args) {
        exists $self->{data}{$_} and return $_;
        exists $self->{_file_list}{$_} and return $_;
    }

    return $self->{default_language};
}

=head2 has_language(@languages | \@languages)

If instance has given langs, return true.

=cut

sub has_language {
    my $self = shift;
    my $args = args2array(@_);

    for (@$args) {
        exists $self->{data}{$_} and return TRUE;
        exists $self->{_file_list}{$_} and return TRUE;
    }
    return FALSE;
}

# ----[ private ]-----------------------------------------------------
sub _encoding {
    my $self = shift;
    my ($map, $in, $out) = @_;
    
    for (keys %$map) {
        if (ref $map->{$_}) {
            $self->_encoding($map->{$_}, $in, $out);
        }
        else {
            $map->{$_} = encode $out, (decode $in, $map->{$_});
        }
    }
}

sub _get_file_data {
    my $self = shift;
    my ($language, $path) = @_;

    ($path and -f $path) or return;
    my $in_enc = ($self->{encoding}{input}{$language}) || $self->{input_encoding};
    my $out_enc = ($self->{encoding}{output}{$language}) || $self->{output_encoding};
    my $ret = load_config_files($path);
    $self->_encoding($ret, $in_enc, $out_enc);
    return $ret;
}

sub _load {
    my $self = shift;
    my ($language) = @_;
    
    my $path = "$self->{base_dir}/$language";
    -d $path or confess "$self->{base_dir}/$language isn't directory";
    my $files = ls_r($path, LS_FILE | LS_ABS);
    for (@$files) {
        $self->file_load($language, $_);
    }
}

# exclude the path be going to pre_load
sub _init_file_list {
    my $self = shift;
    my ($file_list_path) = @_;

    if ($file_list_path) {
        $self->{_file_list} = load_config_files($file_list_path);
    }
    else {
        $self->{_file_list} = $self->create_file_list;
    }
}

=head1 LANGUAGE STRING

af am ang ar az be bg bn br bs ca cs cy da de el en eo es et eu fa fi fr gl gr gu 
he hi hr hu hy ia id is it ja ka kn ko ku lg li lo lt lv mi mk ml mn mr ms my nb 
ne nl nn no or pa pl pt ro ru rw si sk sl sp sq sr sv ta te th tk tr uk ur uz vi 
wa yi zh zu

=head1 SEE ALSO

L<Catalyst::Plugin::Wiz::Message>

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
