package Wiz::Mail;

=head1 NAME

Wiz::Mail - Send mail with multi-language

=head1 VERSION

version 1.0

=cut

our $VERSION = '1.0';

=head1 SYNOPSIS

 use Wiz::Mail;
 
 #  set default configurations
 my $smtp = Wiz::Mail->new( 
     smtp => [
         'host1.wiz.net',
         Hello         => 'host1.wiz.net',
         Timeout       => 60,
         Debug         => 1,
     ],
     From    => 'admin@adways.net',
     Subject => 'alert message',
 );
   
It is equivalent to:
 
 my $smtp = Wiz::Mail->new( 'mailconf.yml' );

in mailconf.yml...

 --
 smtp:
     Host: host1.wiz.net
     Hello: host1.wiz.net
     Timeout: 60
     Debug: 1
 From: admin@adways.net
 Subject: alert message

 
 #  set additional configurations
 $smtp->add({
     Content_Type  => 'iso-2022-jp',
     DefaultPath   => '/path/to/template',   #  not yet implemented
     Template      => 'email.tt',
     TmplParams    => \%params,
     TmplOptions   => \%options,             #  not yet implemented
     TmplCode      => 'euc',
 });
    
 $smtp->replace( 'To' => 'test@adways.net' );
    
 #  send mail
 my $result = $smtp->send();
    
email.tt

 Subject: Test Mail
 From: admin@adways.net
    
 user [% user %]
 This is a test message.

%params is

 %params => ( user => 'example1' );
 
Then result message will be like

 user example1
 This is a test message.  


=head1 DESCRIPTION

Wiz::Mail sends a mail with a specified configuration. 
This is a wrapper of MIME::Lite.

You can specify any parameters with new() and methods of MIME::Lite.
For example, you can specify one of header attributes like I<add> or I<replace>. 

Also you can use multibyte characters with some headers.
For example:

 $smtp->add('To', '穂下様<hoge@adways.net>');

Configurations can be specified either by hashref or by YAML file.


=head2 Available Keys

=head3 Sending method

Specify one of sendmail, smtp, smtp_simple and sub.
    
 sendmail => '/usr/bin/sendmail'
 
 smtp => [
     host,
     HELLO   => hello,
     Timeout => timeout,
 ]
    
Other fields in params of smtp are also available. See new() in Net::SMTP.


=head3 Keys corresponding to message headers   

 Approved      Encrypted     Received      Sender
 Bcc           From          References    Subject
 Cc            Keywords      Reply_To      To
 Comments      Message_ID    Resent_*      X_*
 Content_*     MIME-version 1.0 Return_Path
 Date                        Organization

if key name contains -(hyphens), replace them with _(underscores).


=head3 Keys used in this module    

=over 4

=item Template

Template file name.

=item HTemplate

Template with header.

=item TemplateData

Template string data

=item TmplParams

Hashref which is used when replacing TT parameters in Template, HTemplate and TemplateData.

=item TmplOptions (not implemented yet)

Hashref which will be passed to Template Toolkit.

=item TmplCode

Letter encoding used in template.

=item TmplParamCode

Letter encoding used in TmplParams.   

=item InCode

charcode of the script itself

=item OutCode

Output code. Usually you need not specify it.

=back

=head2 How to use template

Configuration can be specified not only by hash, but also by writing directly in template.

When you want to write parameters in template file, specifies IncludeConf as TRUE, and write params like this.
 param_name1: value1
 param_name2: value2
 (empty line between configs and message body)
 This is a message body.
    
Emply line is needed between params and message body.

email.tt
 1  Subject: Test Mail for [% user %]
 2  From: admin@adways.net
 3  
 4  user [% user %]
 5  This is a test message.
 6

With this template, Subject and From are recognized as configs.
Line 4-6 is recognized as message body.

When IncludeConf is FALSE, message body is started from the first line. 

=head2 others

Since this is a subclass of MIME::Lite, you can use any methods in MIME::Lite.
For example, you can attach files to mail, using I<attach> method.
See also MIME::Lite.

=cut

use Carp;
use YAML;
use Template;
use Encode qw(from_to);
use Encode::Guess;

use Wiz qw(get_hash_args);
   
use base 'MIME::Lite';

no warnings 'uninitialized';

=head1 EXPORTS

=cut

our @EXPORT_SUB = qw();
our @EXPORT_CONST = qw();
our @EXPORT_OK = (@EXPORT_SUB, @EXPORT_CONST);

our %EXPORT_TAGS = (
    'sub'       => \@EXPORT_SUB,
    'const'     => \@EXPORT_CONST,
    'all'       => \@EXPORT_OK,
);

=head1 METHODS

=head2 $obj = new( %params )

Create a new object.

=head2 $obj = new( $file )

Create a new object.

Params can also be passed with using YAML or pdat file.
When using YAML, the filename must end with '.yml'.

=cut

sub new {
    my $invocant = shift;
    my $class = ref $invocant || $invocant;
    my $self = $class->SUPER::new();

    my $conf = get_hash_args(@_);
    $self->_complement_config($conf);

    $self->build(%$conf);
    
    return $self;   
}

=head2 $result = send()

Sends a message.

=cut

sub send {
    my $self = shift;

    my $conf = get_hash_args(@_);

    $self->_complement_config($conf);
    for my $key (keys %$conf) { $self->add($key => $conf->{$key}); }

    $self->SUPER::data($self->_make_message_body);
    my @backup_header = $self->_convert_header_to_mime();
    my $result = $self->SUPER::send(@{$self->{method}});
    $self->{Header} = \@backup_header;

    return $result;
}

sub _convert_header_to_mime {
    my $self = shift;
    my @header_backup = @{ $self->{Header} };
    my @temp_header = ();
    for my $header_ra (@{ $self->{Header} }) {
        my ($attr, $value) = @$header_ra;
        $value = $self->_decode($value, $self->{InCode});

        my $mh = 'MIME-Header';
        lc $self->{OutCode} eq 'iso-2022-jp' and $mh .= '-ISO_2022_JP';

        $value = $self->_decode($value, $self->{OutCode}, $mh);
        push @temp_header, [ $attr, $value ];
    }
    
    $self->{Header} = \@temp_header; 

    return @header_backup;
}

sub set_tmpl_param {
    my ($self, $key, $value) = @_;
    my $dec = $self->{TmplParamCode} || $self->{InCode};
    $self->{TmplParams}->{$key} = $self->_decode($value, $dec);
}

sub data {
    my ($self, $data) = @_;
    $self->{TemplateData} = $data;       
}

sub _make_message_body {
    my ($self) = @_;

    my $template    = $self->{TemplateData};
    my $tmpl_params = $self->{TmplParams};
    my $tmpl_config = $self->{TmplConfig};
    my $tmpl_options = $self->{TmplOptions};
    my $data;

    my $tt = Template->new($tmpl_config || {});

    $tt->process(\$template, $tmpl_params || {}, \$data, $tmpl_options || {})
       or Carp::croak $tt->error;

    return $self->_decode($data, $conf->{InCode});
}

sub _complement_config {
    my ($self, $conf) = @_;

    $conf->{InCode} and $self->{InCode} = $conf->{InCode};
    $conf->{TmplCode} and $self->{TmplCode} = $conf->{TmplCode};

    if ($self->{OutCode} eq '' or $conf->{OutCode} ne '') {
        $self->{OutCode} = $conf->{OutCode} || 'ISO-2022-JP';
    }

    for my $key (qw/ HTemplateFile TemplateFile TemplateData TmplParams TmplConfig TmplOptions /) {
        if ($conf->{$key}) {
            $self->$key($conf->{$key});
        }
    }

    for my $key (qw/ sendmail smtp smtp_simple sub /) {
        if (my $method = $conf->{$key}) {
            unshift @{$method}, $key;
            $self->{method} = $method;
        }   
    }

    $conf->{Type} ||= 'text/plain; charset=' . $self->{OutCode};
    $conf->{Encoding} ||= '7bit';

    return $conf;
}

sub _read_encfile {
    my ($self, $filename) = @_;
    my $enc = $self->{TmplCode};

    open my $FH, "<:encoding($enc)", $filename
        or confess "Can't open file $filename: $!";
    local $/;
    my $read = <$FH>;
    close $FH;

    return $read;      
}

sub HTemplateFile {
    my ($self, $filename) = @_;

    my $read = $self->_read_encfile($filename);

    my ($head, $body) = split /\n\n/, $read, 2;
    $head .= "\n";

    my $param_ref = Load($head);
    for my $key (keys %$param_ref) {
        $self->{$key} = $param_ref->{$key};
    }

    $self->{TemplateData} = $body;
}

sub TemplateFile {
    my ($self, $filename) = @_;
    my $read = $self->_read_encfile($filename);
    $self->{TemplateData} = $read;
}

sub TemplateData {
    my ($self, $data) = @_;
    my $dec = $self->{TmplCode} || $self->{InCode};
    $self->{TemplateData} = $self->_decode($data, $dec);
}

sub TmplParams {
    my ($self, $param_ref) = @_;
    my $dec = $self->{TmplParamCode} || $self->{InCode};

    for my $key (keys %$param_ref) {
        $param_ref->{$key} = $self->_decode($param_ref->{$key}, $dec);  
    }

    $self->{TmplParams} = $param_ref;
}

sub _decode {
    my ($self, $data, $in_enc, $out_enc) = @_;

    if ($in_enc eq '') {
        $in_enc = guess_encoding($data)->name;
        $in_enc eq 'utf8' and $in_enc = 'utf-8';
    }

    $out_enc ||= $self->{OutCode};

    if (lc $in_enc ne lc $out_enc) {
        my $ret = $data;
        from_to($ret, $in_enc, $out_enc);
        return $ret;
    }

    return $data;
}

sub _encode_header {
    my ($self, $str) = @_;

    my $type = 'MIME-Header';
    if (uc $self->{OutCode} eq 'ISO-2022-JP') {
        $type .= '-ISO_2022_JP';
    }

    return Encode::encode($type, $str);
}

=head1 SEE ALSO

 MIME::Lite
 Net::SMTP

=head1 AUTHOR

Egawa Takashi, C<< <egawa.takashi@adways.net> >>

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

1; # End of Wiz::Mail

__END__


  
