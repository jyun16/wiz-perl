package Wiz::Validator;

use strict;
use warnings;

no warnings 'uninitialized';

=head1 NAME

Wiz::Validator

=head1 VERSION

version 1.0

=cut

our $VERSION = '1.0';

=head1 SYNOPSIS

 use Wiz::Validator::Constant qw(:error);
 
 my $v = new Wiz::Validator;
 
 # FALSE
 $v->is_number(number_test => '123c');
 
 # { 
 #     number_test => NOT_NUMBER,
 # }
 $v->errors;
 
 # {
 #     number_test => 'is not number',
 # }
 $v->messages;

Validator's methods are same Wiz::Util::Validation.
If you want to use Wiz::Util::Validation::JA's methods, do the following.

 $v->type('ja');
 
 # FALSE
 $v->is_phone_number(phone => '03-x555-5555');
 
 # { 
 #     number_test => NOT_NUMBER,
 #     phone => NOT_PHONE_NUMBER,
 # }
 $v->errors;

If you use original message, do the following.

 my $m = new Wiz::Message(data => {
     en  => {
         validation => {
             not_number => 'Wiz::Message NOT NUMBER',
         },
     },
 });
 
 my $v = new Wiz::Validator(message => $m);
 
 $v->is_number(number => '123c');
 
 # {
 #     number      => 'Wiz::Message NOT NUMBER',
 # }
 $v->messages;

=head1 DESCRIPTION

=cut

use base qw(Class::Accessor::Fast);

use Wiz qw(get_hash_args);
use Wiz::Constant qw(:common);
use Wiz::Validator::Constant qw(:error);
use Wiz::Message;
use Wiz::Util::Hash qw(create_ordered_hash hash_access_by_list);
use Wiz::Util::Array qw(args2array);
use Wiz::Util::Validation;

=head1 ACCESSORS

 message

=cut

__PACKAGE__->mk_accessors(qw(message));

=head1 EXPORTS

 error_no2label

=cut

use Wiz::ConstantExporter [qw(error_no2label)];

my %error_label;

BEGIN {
    no strict 'refs';
    # is & not
    for (qw(
        NULL EMPTY ZERO NUMBER INTEGER NEGATIVE_INTEGER REAL
        ALPHABET ALPHABET_UC ALPHABET_LC ALPHABET_NUMBER ASCII EQUALS
        BIGGER SMALLER EMAIL_ADDRESS URL RFC822_DOT_ATOM_TEXT VALID_LOCAL VALID_DOMAIN
        PHONE_NUMBER ZIP_CODE CREDIT_CARD_NUMBER NAME VALID_DATE INVALID_DATE
        HIRAGANA KATAKANA KANJI FURIGANA
    )) {
        my ($is, $not) = ("IS_$_", "NOT_$_");
        $error_label{$is->()} = lc $is;
        $error_label{$not->()} = lc $not;
    }
    for (qw(OVER_MAX_SELECT SHORT_MIN_SELECT OVER_MAX_LENGTH SHORT_MIN_LENGTH)) {
        $error_label{"$_"->()} = lc $_;
    }
};

my %default_message = (
    en  => {
        validation    => {
            is_null                     => 'value is null',
            is_empty                    => 'value is empty',
            is_zero                     => 'value is zero',
            is_number                   => 'value is number',
            is_integer                  => 'value is integer',
            is_negative_integer         => 'value is negative integer',
            is_real                     => 'value is real number',
            is_alphabet                 => 'value is alphabet',
            is_alphabet_uc              => 'value is alphabet uc',
            is_alphabet_lc              => 'value is alphabet lc',
            is_alphabet_number          => 'value is alphabet number',
            is_ascii                    => 'value is ascii',
            is_equals                   => 'same values',
            is_bigger                   => 'value is bigger',
            is_smaller                  => 'value is smaller',
            is_email_address            => 'value is email address',
            is_url                      => 'value is url',
            is_httpurl                  => 'value is httpurl',
            is_rfc822_dot_atom_text     => 'value is rfc822 dot atom text',
            is_valid_local              => 'value is valid local',
            is_valid_domain             => 'value is valid domain',
            is_credit_card_number       => 'valud is credit card number',
            is_name                     => 'value is name',
            is_valid_date               => 'value is valid date',
            is_invalid_date             => 'valud is invalid date',
            not_null                    => 'value is not null',
            not_empty                   => 'value is not empty',
            not_zero                    => 'value is not zero',
            not_number                  => 'value is not number',
            not_integer                 => 'value is not integer',
            not_negative_integer        => 'value is not negative integer',
            not_real                    => 'value is not real number',
            not_alphabet                => 'value is not alphabet',
            not_alphabet_uc             => 'value is not alphabet uc',
            not_alphabet_lc             => 'value is not alphabet lc',
            not_alphabet_number         => 'value is not alphabet number',
            not_ascii                   => 'value is not ascii',
            not_equals                  => 'is not same values',
            not_bigger                  => 'value is not bigger',
            not_smaller                 => 'value is not smaller',
            not_email_address           => 'value is not email address',
            not_url                     => 'value is not url',
            not_httpurl                 => 'value is not httpurl',
            not_rfc822_dot_atom_text    => 'value is not rfc822 dot atom text',
            not_valid_local             => 'value is not valid local',
            not_valid_domain            => 'value is not valid domain',
            not_phone_number            => 'value is not phone number',
            not_hiragana                => 'value is not hiragana',
            not_katakana                => 'value is not katakana',
            not_kanji                   => 'value is not kanji',
            not_furigana                => 'value is not furigana',
            not_zip_code                => 'value is not zip code',
            not_credit_card_number      => 'valud is not credit card number',
            not_name                    => 'value is not name',
            not_valid_date              => 'value is not valid date',
            not_invalid_date            => 'valud is not invalid date',
            over_max_select             => 'over max select',
            short_min_select            => 'short min select',
            over_max_length             => 'over max length',
            short_min_length            => 'short min length',
        },
    },
);

sub _import_validation {
    no strict 'refs';
    no warnings 'uninitialized';

    my $pkg = (caller)[0];
    my $validation_pkg = "Wiz::Util::Validation";
    $pkg =~ /Validator::(.*)$/;
    defined $1 and $validation_pkg .= "::$1";
    for my $m (keys %{"${validation_pkg}::"}) {
        $m =~ /^(is|not)_(.*)/ or next;
        my $err = $1 eq 'is' ?  ("NOT_" . uc $2)->() : ("IS_" . uc $2)->();
        if ($m =~ /not_empty|not_null/) {
            *{ $pkg . '::' . $m } = sub {
                my $self = shift;
                my ($key, $value) = @_;
                unless ("${validation_pkg}::$m"->($value)) {
                    $self->{errors}{$key} = $err;
                    return FALSE;
                }
                return TRUE;
            }
        }
        else {
            *{ $pkg . '::' . $m } = sub {
                my $self = shift;
                my ($key, $value) = @_;
                $value eq '' and return TRUE;
                unless ("${validation_pkg}::$m"->($value)) {
                    $self->{errors}{$key} = $err;
                    return FALSE;
                }
                return TRUE;
            }
        }
    }
}

BEGIN { _import_validation; };

my %default = (
    type    => 'en',
);

my %langmap = (
    'ja-jp' => 'ja',
);

my %langs = (
    en  => 1,
    ja  => 1,
);

=head1 CONSTRUCTOR

message is Wiz::Message or hash data.

=cut

sub new {
    my $self = shift;
    my $args = get_hash_args(@_);

    defined $args->{message} or
        $args->{message} = new Wiz::Message(
            language => $default{type}, data => \%default_message);

    if ($self eq 'Wiz::Validator') {
        defined $args->{type} or $args->{type} = $default{type};
    }

    exists $langmap{$args->{type}} and $args->{type} = $langmap{$args->{type}};

    my $instance = bless {
        errors          => create_ordered_hash,
        type            => $args->{type},
        message         => $args->{message},
        outer_errors    => create_ordered_hash,
        _message_sub    => ref $args->{message} eq 'Wiz::Message' ?
            sub {
                my $self = shift;
                return $self->{message}->validation(@_);
            } : sub {
                my $self = shift;
                return hash_access_by_list($self->{message}, \@_);
            },
    }, $self;

    $args->{type} and $instance->type($args->{type});

    return $instance;
}

=head1 METHODS

=cut

sub has_error {
    my $self = shift;
    my ($name) = @_;

    if (defined $name) {
        return ($self->error($name) == NO_ERROR) ? FALSE : TRUE;
    }
    else {
        return keys %{$self->{errors}} > 0 || $self->has_outer_error || FALSE;
    }
}
sub has_outer_error { keys %{shift->{outer_errors}} > 0 || FALSE; }

sub remove_error {
    my $self = shift;
    my ($name) = @_;
    delete $self->{errors}{$name};
}

sub error {
    my $self = shift;
    my ($name) = @_;

    my $ret = $self->{errors}{$name};
    if (not defined $ret and $self->has_outer_error) {
        $ret = $self->{outer_errors}{$name};
    }
    return $ret || NO_ERROR
}

sub error_label {
    my $self = shift;
    my ($name) = @_;

    my $ret = $error_label{$self->error($name)};
    if (not defined $ret and $self->has_outer_error) {
        $ret = $self->{outer_errors}{$name};
    }
    return $ret;
}

sub error_message {
    my $self = shift;
    my ($name) = @_;

    my $error_label = $self->error_label($name);
    my $ret = $self->{message}->validation($error_label);
    if (not defined $ret) {
        if ($self->has_outer_error) {
            $ret = $self->{outer_errors}{$name};
        }
        else {
            $ret = $default_message{en}{validation}{$error_label};
        }
    }
    return $ret;
}

sub errors {
    my $self = shift;

    my $ret = { %{$self->{errors}} };
    if ($self->has_outer_error) {
        for (keys %{$self->{outer_errors}}) {
            $ret->{$_} = $self->{outer_errors}{$_};
        }
    }
    return $ret;
}

sub errors_labels {
    my $self = shift;

    my $e = $self->{errors};
    my %ret = map { $_ => $error_label{$e->{$_}} } keys %$e;
    if ($self->has_outer_error) {
        for (keys %{$self->{outer_errors}}) {
            $ret{$_} = $self->{outer_errors}{$_};
        }
    }
    return \%ret;
}

sub errors_messages {
    my $self = shift;

    my $m = $self->{message};
    my $e = $self->errors_labels;
    my %ret = map {
        $_ => ($m->validation($e->{$_}) || $default_message{en}{validation}{$e->{$_}}) } keys %$e;
    if ($self->has_outer_error) {
        for (keys %{$self->{outer_errors}}) {
            $ret{$_} = $self->{outer_errors}{$_};
        }
    }
    return \%ret;
};

sub message {
    my $self = shift;
    my ($name) = @_;
    my $error = $self->error($name);
    defined $error or return '';
    return $error =~ /^\d*$/ ?
        $self->{_message_sub}->($self, $error_label{$error}) :
        $error;
}

sub messages {
    my $self = shift;

    keys %{$self->{errors}} or return undef;
    my $errors = $self->{errors};
    return {
        map {
            $_ => $errors->{$_} =~ /^\d*$/ ? 
                $self->{_message_sub}->($self, $error_label{$errors->{$_}}) :
                $errors->{$_};
        } keys %$errors
    };
}

sub remove_errors {
    my $self = shift;
    my $args = args2array @_;

    for (@$args) {
        delete $self->{errors}{$_};
    }
}

sub clear {
    my $self = shift;

    $self->{errors} = create_ordered_hash;
    $self->{outer_errors} = create_ordered_hash;
}

sub outer_error {
    my $self = shift;
    my ($key, $no) = @_;

    my $msg = $self->{_message_sub}->($self, $error_label{$no});
    defined $msg and $self->{outer_errors}{$key} = $msg;
    $self->{outer_errors}{$key};
}

sub outer_error_message {
    my $self = shift;
    my ($key, $msg) = @_;

    defined $msg and $self->{outer_errors}{$key} = $msg;
    $self->{outer_errors}{$key};
}

sub outer_error_label {
    my $self = shift;
    my ($key, $label) = @_;

    my $msg = $self->{_message_sub}->($self, $label);
    defined $msg and $self->{outer_errors}{$key} = $msg;
    $self->{outer_errors}{$key};
}

*language = \&type;

sub type {
    my $self = shift;
    my ($type) = @_;
    $langs{$type} or $type = $default{type};
    bless $self, 'Wiz::Validator::' . uc $type;
    if (ref $self->{message} eq 'Wiz::Message') {
        $self->{message}->has_language($type) or
            $self->{message}{data}{$type} = $self->{message}{data}{'en'};
        $self->{message}->language($type);
    }
}

#----[ private ]------------------------------------------------------

=head1 FUNCTIONS

=cut

#----[ static ]-------------------------------------------------------
sub error_no2label {
    return $error_label{+shift}
}

#----[ private static ]-----------------------------------------------

=head1 FUNCTIONS

=cut

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
